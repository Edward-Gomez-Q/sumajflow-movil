// lib/presentation/getx/tracking_controller.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/core/config/tracking_config.dart';
import 'package:sumajflow_movil/core/exceptions/network_exception.dart';
import 'package:sumajflow_movil/core/services/location_service.dart';
import 'package:sumajflow_movil/core/services/offline_storage_service.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/data/repositories/tracking_repository.dart';
import 'package:flutter/rendering.dart';

/// Controller dedicado EXCLUSIVAMENTE al tracking GPS
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
  final lastUpdateTime = Rxn<DateTime>();
  final hasGpsIssue = false.obs;
  final wasOfflineLastUpdate = false.obs;

  // Timers
  Timer? _locationUpdateTimer;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Control de errores GPS
  int _consecutiveGpsErrors = 0;
  static const int _maxConsecutiveErrors = 3;

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
      lastUpdateTime.value = DateTime.now();
      _consecutiveGpsErrors = 0;
      hasGpsIssue.value = false;

      // Iniciar stream de ubicación en tiempo real
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5, // Actualizar cada 5 metros
              // ❌ NO usar timeLimit - causa TimeoutException
            ),
          ).listen(
            _onLocationUpdate,
            onError: _onLocationError,
            cancelOnError: false, // Continuar escuchando después de errores
          );

      // Timer de respaldo para asegurar actualizaciones periódicas
      _locationUpdateTimer = Timer.periodic(
        Duration(seconds: TrackingConfig.locationUpdateInterval),
        (_) => _actualizarUbicacionManual(),
      );

      // Iniciar sincronización periódica
      _iniciarSincronizacionPeriodica();

      isActive.value = true;
      isPaused.value = false;

      debugPrint(
        '✅ Tracking GPS iniciado - Intervalo: ${TrackingConfig.locationUpdateInterval}s',
      );
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

    _positionStreamSubscription?.pause();
    _locationUpdateTimer?.cancel();
    _syncTimer?.cancel();

    // Sincronizar antes de pausar
    _sincronizarDatosOffline();
  }

  Future<void> reanudarTracking() async {
    if (!isPaused.value) return;

    debugPrint('▶️ Reanudando tracking GPS');
    isPaused.value = false;

    _positionStreamSubscription?.resume();

    // Reiniciar timers
    _locationUpdateTimer = Timer.periodic(
      Duration(seconds: TrackingConfig.locationUpdateInterval),
      (_) => _actualizarUbicacionManual(),
    );

    _iniciarSincronizacionPeriodica();

    // Obtener ubicación actual
    await _actualizarUbicacionManual();
  }

  void detenerTracking() {
    debugPrint('⏹️ Deteniendo tracking GPS');

    isActive.value = false;
    isPaused.value = false;

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationUpdateTimer?.cancel();
    _syncTimer?.cancel();

    // Sincronizar datos pendientes
    if (isOnline.value) {
      _sincronizarDatosOffline();
    }

    _consecutiveGpsErrors = 0;
    hasGpsIssue.value = false;
  }

  // ============================================================
  // TRACKING INTERNO
  // ============================================================

  void _onLocationUpdate(Position position) {
    if (!isActive.value || isPaused.value) {
      return;
    }

    // Reset contador de errores en actualización exitosa
    _consecutiveGpsErrors = 0;
    hasGpsIssue.value = false;

    final now = DateTime.now();
    final lastUpdate = lastUpdateTime.value;

    // Verificar si es una actualización significativa
    if (lastUpdate != null) {
      final timeSinceLastUpdate = now.difference(lastUpdate);
      if (timeSinceLastUpdate.inSeconds <
          TrackingConfig.locationUpdateInterval) {
        // Si es muy pronto, solo actualizar posición local sin enviar al backend
        currentPosition.value = position;
        return;
      }
    }

    currentPosition.value = position;
    lastUpdateTime.value = now;

    debugPrint(
      '📍 Nueva ubicación: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} | '
      'Velocidad: ${(position.speed * 3.6).toStringAsFixed(1)} km/h | '
      'Precisión: ${position.accuracy.toStringAsFixed(1)}m',
    );

    _enviarUbicacionAlBackend(position);
  }

  void _onLocationError(dynamic error) {
    if (!isActive.value || isPaused.value) return;

    _consecutiveGpsErrors++;

    // Identificar el tipo de error
    if (error is TimeoutException) {
      debugPrint(
        '⏱️ Timeout GPS (${_consecutiveGpsErrors}/$_maxConsecutiveErrors) - '
        'Señal débil o en interior',
      );
    } else {
      debugPrint(
        '❌ Error de ubicación: $error (${_consecutiveGpsErrors}/$_maxConsecutiveErrors)',
      );
    }

    // Marcar problema GPS si hay muchos errores consecutivos
    if (_consecutiveGpsErrors >= _maxConsecutiveErrors) {
      if (!hasGpsIssue.value) {
        debugPrint('⚠️ Problemas persistentes con GPS detectados');
        hasGpsIssue.value = true;
      }
    }

    // Guardar última ubicación conocida offline
    if (currentPosition.value != null) {
      _guardarUbicacionOffline();
    }

    // Intentar obtener ubicación manualmente como fallback
    _actualizarUbicacionManual();
  }

  Future<void> _enviarUbicacionAlBackend(Position position) async {
    if (!isActive.value || isPaused.value) return;

    final capturoOffline = !isOnline.value;

    if (capturoOffline) {
      debugPrint('📴 Enviando ubicación capturada mientras estaba offline');
    }

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
        esOffline: capturoOffline,
      );

      if (response.success) {
        if (!isOnline.value) {
          debugPrint('🟢 Reconectado al backend');
        }
        isOnline.value = true;
        wasOfflineLastUpdate.value = false;
      }
    } on NetworkException catch (e) {
      // Error de red esperado - no loguear si ya estamos offline
      if (isOnline.value) {
        debugPrint('🔴 Desconectado del backend: ${e.type}');
      }
      isOnline.value = false;
      wasOfflineLastUpdate.value = true;
      await _guardarUbicacionOffline(position);
    } catch (e) {
      // Otros errores
      if (isOnline.value) {
        debugPrint('⚠️ Error inesperado al enviar ubicación: $e');
      }
      isOnline.value = false;
      wasOfflineLastUpdate.value = true;
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
    final pendientes = _offlineStorage.totalPendingLocations;
    debugPrint(
      '💾 Ubicación guardada offline\n'
      '   📍 Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}\n'
      '   ⏰ ${DateTime.now().toString()}\n'
      '   📦 Total pendientes: $pendientes',
    );
  }

  Future<void> _actualizarUbicacionManual() async {
    if (!isActive.value || isPaused.value) return;

    try {
      final position = await _locationService.getCurrentPosition().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Timeout silencioso - usar última posición
          return null;
        },
      );

      if (position != null) {
        _onLocationUpdate(position);
      } else if (currentPosition.value != null) {
        // Si no hay nueva posición pero tenemos una anterior, guardarla offline
        await _guardarUbicacionOffline();
      }
    } catch (e) {
      // Error silencioso - no detener el tracking
      if (currentPosition.value != null) {
        await _guardarUbicacionOffline();
      }
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

      if (hasConnection && wasOffline) {
        debugPrint('🔄 Conexión restaurada, sincronizando...');
        _sincronizarDatosOffline();
      } else if (!hasConnection && !wasOffline) {
        debugPrint('📡 Conexión perdida, modo offline activado');
      }

      isOnline.value = hasConnection;
    });
  }

  void _iniciarSincronizacionPeriodica() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: TrackingConfig.syncInterval),
      (_) => _sincronizarDatosOffline(),
    );
    debugPrint(
      '🔄 Sincronización periódica iniciada cada ${TrackingConfig.syncInterval}s',
    );
  }

  Future<void> _sincronizarDatosOffline() async {
    if (!isOnline.value) return;

    try {
      final ubicacionesPendientes = await _offlineStorage.getPendingLocations(
        asignacionId,
      );

      if (ubicacionesPendientes.isEmpty) {
        return;
      }

      debugPrint(
        '🔄 Iniciando sincronización offline\n'
        '   📦 Ubicaciones pendientes: ${ubicacionesPendientes.length}\n'
        '   🕐 Rango: ${ubicacionesPendientes.first.timestamp} a ${ubicacionesPendientes.last.timestamp}',
      );

      final response = await _trackingRepository.sincronizarUbicaciones(
        asignacionCamionId: asignacionId,
        ubicaciones: ubicacionesPendientes,
      );

      if (response.success && response.ubicacionesSincronizadas > 0) {
        await _offlineStorage.markLocationsSynced(
          asignacionId,
          response.ubicacionesSincronizadas,
        );
        debugPrint(
          '✅ Sincronización completada\n'
          '   ✔️ Exitosas: ${response.ubicacionesSincronizadas}\n'
          '   ❌ Fallidas: ${response.ubicacionesFallidas}\n'
          '   📦 Pendientes restantes: ${_offlineStorage.totalPendingLocations}',
        );
      }
    } on NetworkException catch (e) {
      debugPrint('📴 Error de red en sincronización: ${e.type}');
      isOnline.value = false;
    } catch (e) {
      debugPrint('⚠️ Error al sincronizar: $e');
    }
  }

  @override
  void onClose() {
    detenerTracking();
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}
