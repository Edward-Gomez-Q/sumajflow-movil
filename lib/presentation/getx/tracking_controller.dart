// lib/presentation/getx/tracking_controller.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/core/services/location_service.dart';
import 'package:sumajflow_movil/core/services/offline_storage_service.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/data/repositories/tracking_repository.dart';
import 'package:flutter/rendering.dart';

/// Controller dedicado EXCLUSIVAMENTE al tracking GPS
/// No maneja UI ni eventos de negocio
class TrackingController extends GetxController {
  final int asignacionId;

  // Servicios
  final LocationService _locationService = LocationService.to;
  final OfflineStorageService _offlineStorage = OfflineStorageService.to;
  final TrackingRepository _trackingRepository = TrackingRepository();

  // Estado
  final currentPosition = Rxn<Position>();
  final isOnline = true.obs;
  final isActive = false.obs;
  final isPaused = false.obs;

  // Timers
  Timer? _locationUpdateTimer;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Config
  static const int _locationUpdateIntervalSeconds = 30;
  static const int _syncIntervalSeconds = 60;

  TrackingController({required this.asignacionId});

  @override
  void onInit() {
    super.onInit();
    _monitorearConectividad();
  }

  // ============================================================
  // API PÚBLICA
  // ============================================================

  Future<void> iniciarTracking() async {
    if (isActive.value) {
      debugPrint('⚠️ Tracking ya está activo');
      return;
    }

    try {
      debugPrint('📡 Iniciando tracking GPS - AsignacionId: $asignacionId');

      // Verificar permisos
      final hasPermission = await _locationService.checkPermissions();
      if (!hasPermission) {
        throw Exception('Permisos de ubicación requeridos');
      }

      // Verificar GPS
      final gpsEnabled = await _locationService.checkGpsStatus();
      if (!gpsEnabled) {
        throw Exception('GPS deshabilitado');
      }

      // Obtener ubicación inicial
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        throw Exception('No se pudo obtener ubicación inicial');
      }
      currentPosition.value = position;

      // Iniciar tracking continuo
      final success = await _locationService.startTracking(
        onUpdate: _onLocationUpdate,
        onErrorCallback: _onLocationError,
        intervalSeconds: _locationUpdateIntervalSeconds,
      );

      if (!success) {
        throw Exception('No se pudo iniciar el tracking');
      }

      // Timer de respaldo
      _locationUpdateTimer = Timer.periodic(
        Duration(seconds: _locationUpdateIntervalSeconds),
        (_) => _actualizarUbicacionManual(),
      );

      // Iniciar sincronización
      _iniciarSincronizacionPeriodica();

      isActive.value = true;
      isPaused.value = false;

      debugPrint('✅ Tracking GPS iniciado correctamente');
    } catch (e) {
      debugPrint('❌ Error al iniciar tracking: $e');
      isActive.value = false;
      rethrow;
    }
  }

  void pausarTracking() {
    if (!isActive.value) return;

    debugPrint('⏸️ Pausando tracking GPS');
    isPaused.value = true;

    _locationUpdateTimer?.cancel();
    _syncTimer?.cancel();
    _locationService.stopTracking();

    // Sincronizar antes de pausar
    _sincronizarDatosOffline();
  }

  Future<void> reanudarTracking() async {
    if (!isPaused.value) return;

    debugPrint('▶️ Reanudando tracking GPS');
    isPaused.value = false;

    await iniciarTracking();
  }

  void detenerTracking() {
    debugPrint('⏹️ Deteniendo tracking GPS');

    isActive.value = false;
    isPaused.value = false;

    _locationUpdateTimer?.cancel();
    _syncTimer?.cancel();
    _locationService.stopTracking();

    // Sincronizar datos pendientes
    if (isOnline.value) {
      _sincronizarDatosOffline();
    }
  }

  // ============================================================
  // TRACKING INTERNO
  // ============================================================

  void _onLocationUpdate(Position position) {
    if (!isActive.value || isPaused.value) {
      debugPrint('⏸️ Tracking pausado/inactivo, ignorando actualización');
      return;
    }

    currentPosition.value = position;
    debugPrint(
      '📍 Nueva ubicación: ${position.latitude}, ${position.longitude}',
    );

    _enviarUbicacionAlBackend(position);
  }

  void _onLocationError(String error) {
    debugPrint('❌ Error de ubicación: $error');
    _guardarUbicacionOffline();
  }

  Future<void> _enviarUbicacionAlBackend(Position position) async {
    if (!isActive.value) return;

    try {
      final response = await _trackingRepository.actualizarUbicacion(
        asignacionCamionId: asignacionId,
        lat: position.latitude,
        lng: position.longitude,
        precision: position.accuracy,
        velocidad: position.speed * 3.6,
        rumbo: position.heading,
        altitud: position.altitude,
        timestampCaptura: DateTime.now(),
      );

      if (response.success) {
        isOnline.value = true;
        // El ViajeController escuchará cambios de estado desde el backend
      }
    } catch (e) {
      debugPrint('❌ Error al enviar ubicación: $e');
      isOnline.value = false;
      await _guardarUbicacionOffline(position);
    }
  }

  Future<void> _guardarUbicacionOffline([Position? position]) async {
    final pos = position ?? currentPosition.value;
    if (pos == null) return;

    final ubicacionOffline = UbicacionOfflineModel(
      lat: pos.latitude,
      lng: pos.longitude,
      timestamp: DateTime.now(),
      precision: pos.accuracy,
      velocidad: pos.speed * 3.6,
      rumbo: pos.heading,
      altitud: pos.altitude,
    );

    await _offlineStorage.saveLocationOffline(asignacionId, ubicacionOffline);
    debugPrint('💾 Ubicación guardada offline');
  }

  Future<void> _actualizarUbicacionManual() async {
    if (!isActive.value || isPaused.value) return;

    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      _onLocationUpdate(position);
    }
  }

  // ============================================================
  // CONECTIVIDAD Y SYNC
  // ============================================================

  void _monitorearConectividad() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      final wasOffline = !isOnline.value;
      isOnline.value = hasConnection;

      if (hasConnection && wasOffline) {
        debugPrint('🔄 Reconectado, sincronizando...');
        _sincronizarDatosOffline();
      }
    });
  }

  void _iniciarSincronizacionPeriodica() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: _syncIntervalSeconds),
      (_) => _sincronizarDatosOffline(),
    );
  }

  Future<void> _sincronizarDatosOffline() async {
    try {
      final ubicacionesPendientes = await _offlineStorage.getPendingLocations(
        asignacionId,
      );

      if (ubicacionesPendientes.isEmpty) {
        return;
      }

      debugPrint(
        '🔄 Sincronizando ${ubicacionesPendientes.length} ubicaciones...',
      );

      await _trackingRepository.sincronizarUbicaciones(
        asignacionCamionId: asignacionId,
        ubicaciones: ubicacionesPendientes,
      );

      await _offlineStorage.markLocationsSynced(
        asignacionId,
        ubicacionesPendientes.length,
      );

      isOnline.value = true;
      debugPrint('✅ Sincronización completada');
    } catch (e) {
      debugPrint('❌ Error al sincronizar: $e');
      isOnline.value = false;
    }
  }

  @override
  void onClose() {
    detenerTracking();
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
