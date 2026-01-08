// lib/presentation/getx/tracking_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/core/services/location_service.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/core/services/offline_storage_service.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/data/repositories/tracking_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TrackingController extends GetxController {
  final TrackingRepository _repository = TrackingRepository();
  final LocationService _locationService = LocationService.to;
  final OfflineStorageService _offlineStorage = OfflineStorageService.to;
  final NotificationService _notification = NotificationService.to;

  // ID de la asignación actual
  int? asignacionCamionId;

  // Estados principales
  final RxBool isLoading = false.obs;
  final RxBool isViajeActivo = false.obs;
  final RxBool isOnline = true.obs;
  final RxString errorMessage = ''.obs;

  // Datos del viaje
  final Rx<LoteDetalleViajeModel?> loteDetalle = Rx<LoteDetalleViajeModel?>(
    null,
  );
  final Rx<TrackingModel?> tracking = Rx<TrackingModel?>(null);
  final Rx<UbicacionModel?> ubicacionActual = Rx<UbicacionModel?>(null);
  final Rx<GeofencingStatusModel?> geofencingStatus =
      Rx<GeofencingStatusModel?>(null);

  // Modo simulación
  final RxBool modoSimulacion = false.obs;

  // Timers y streams
  Timer? _updateTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Intervalo de actualización en segundos
  static const int _updateInterval = 30;

  @override
  void onInit() {
    super.onInit();
    _setupConnectivityListener();
  }

  @override
  void onClose() {
    _updateTimer?.cancel();
    _connectivitySubscription?.cancel();
    _locationService.stopTracking();
    super.onClose();
  }

  /// Configura el listener de conectividad
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      isOnline.value = hasConnection;

      if (hasConnection && _offlineStorage.hasPendingData.value) {
        _sincronizarDatosPendientes();
      }
    });
  }

  // ==================== INICIAR VIAJE ====================

  /// Carga el detalle del lote antes de iniciar
  Future<void> cargarDetalleLote(int asignacionId) async {
    isLoading.value = true;
    errorMessage.value = '';
    asignacionCamionId = asignacionId;

    try {
      final detalle = await _repository.getDetalleLote(asignacionId);
      loteDetalle.value = detalle;
      debugPrint('✅ Detalle del lote cargado: ${detalle.codigoLote}');
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _notification.showError('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Inicia el viaje y el tracking GPS
  Future<bool> iniciarViaje() async {
    if (asignacionCamionId == null) {
      _notification.showError('Error', 'No hay asignación seleccionada');
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Obtener ubicación inicial
      Position? posicionInicial;
      if (!modoSimulacion.value) {
        posicionInicial = await _locationService.getCurrentPosition();
      }

      // Iniciar tracking en el backend
      final trackingData = await _repository.iniciarTracking(
        asignacionCamionId: asignacionCamionId!,
        latInicial: posicionInicial?.latitude,
        lngInicial: posicionInicial?.longitude,
      );

      tracking.value = trackingData;
      isViajeActivo.value = true;

      // Iniciar tracking de GPS
      await _iniciarTrackingGps();

      _notification.showSuccess(
        '¡Viaje iniciado!',
        'El tracking GPS está activo',
      );
      debugPrint('✅ Viaje iniciado - Tracking ID: ${trackingData.id}');

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _notification.showError('Error al iniciar viaje', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Inicia el tracking de GPS
  Future<void> _iniciarTrackingGps() async {
    if (modoSimulacion.value) {
      debugPrint('🎮 Tracking en modo simulación');
      _locationService.enableSimulationMode();
      return;
    }

    await _locationService.startTracking(
      onUpdate: _onUbicacionActualizada,
      onErrorCallback: (error) {
        debugPrint('❌ Error GPS: $error');
      },
    );

    // Timer para enviar actualizaciones periódicas
    _updateTimer = Timer.periodic(
      const Duration(seconds: _updateInterval),
      (_) => _enviarActualizacionUbicacion(),
    );
  }

  /// Callback cuando se actualiza la ubicación
  void _onUbicacionActualizada(Position position) {
    ubicacionActual.value = UbicacionModel(
      lat: position.latitude,
      lng: position.longitude,
      timestamp: DateTime.now(),
      precision: position.accuracy,
      velocidad: position.speed * 3.6, // m/s a km/h
      rumbo: position.heading,
      altitud: position.altitude,
    );

    // Verificar geofencing localmente
    _verificarGeofencingLocal();
  }

  /// Envía la ubicación actual al servidor
  Future<void> _enviarActualizacionUbicacion() async {
    if (ubicacionActual.value == null || asignacionCamionId == null) return;

    final ubicacion = ubicacionActual.value!;

    if (!isOnline.value) {
      // Guardar offline
      await _offlineStorage.saveLocationOffline(
        asignacionCamionId!,
        UbicacionOfflineModel(
          lat: ubicacion.lat,
          lng: ubicacion.lng,
          timestamp: DateTime.now(),
          precision: ubicacion.precision,
          velocidad: ubicacion.velocidad,
          rumbo: ubicacion.rumbo,
          altitud: ubicacion.altitud,
        ),
      );
      debugPrint('💾 Ubicación guardada offline');
      return;
    }

    try {
      final response = await _repository.actualizarUbicacion(
        asignacionCamionId: asignacionCamionId!,
        lat: ubicacion.lat,
        lng: ubicacion.lng,
        precision: ubicacion.precision,
        velocidad: ubicacion.velocidad,
        rumbo: ubicacion.rumbo,
        altitud: ubicacion.altitud,
      );

      geofencingStatus.value = response.geofencingStatus;

      // Verificar si requiere acción
      if (response.requiereAccion) {
        _mostrarAccionRequerida(response.accionRequerida);
      }

      debugPrint('📤 Ubicación enviada al servidor');
    } catch (e) {
      // Si falla, guardar offline
      await _offlineStorage.saveLocationOffline(
        asignacionCamionId!,
        UbicacionOfflineModel(
          lat: ubicacion.lat,
          lng: ubicacion.lng,
          timestamp: DateTime.now(),
          precision: ubicacion.precision,
          velocidad: ubicacion.velocidad,
          rumbo: ubicacion.rumbo,
          altitud: ubicacion.altitud,
        ),
      );
      debugPrint('⚠️ Error al enviar ubicación, guardada offline: $e');
    }
  }

  // ==================== PUNTOS DE CONTROL ====================

  /// Registra llegada a un punto de control
  Future<bool> registrarLlegada(String tipoPunto) async {
    if (asignacionCamionId == null) return false;

    isLoading.value = true;

    try {
      final ubicacion = ubicacionActual.value;

      final trackingActualizado = await _repository.registrarLlegada(
        asignacionCamionId: asignacionCamionId!,
        tipoPunto: tipoPunto,
        lat: ubicacion?.lat,
        lng: ubicacion?.lng,
      );

      tracking.value = trackingActualizado;
      geofencingStatus.value = trackingActualizado.geofencingStatus;

      _notification.showSuccess(
        'Llegada registrada',
        'Has llegado al punto de control',
      );
      return true;
    } catch (e) {
      _notification.showError(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Registra salida de un punto de control
  Future<bool> registrarSalida(String tipoPunto) async {
    if (asignacionCamionId == null) return false;

    isLoading.value = true;

    try {
      final trackingActualizado = await _repository.registrarSalida(
        asignacionCamionId: asignacionCamionId!,
        tipoPunto: tipoPunto,
      );

      tracking.value = trackingActualizado;
      geofencingStatus.value = trackingActualizado.geofencingStatus;

      _notification.showSuccess(
        'Salida registrada',
        'Continúa hacia el siguiente punto',
      );
      return true;
    } catch (e) {
      _notification.showError(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== SIMULACIÓN ====================

  /// Activa/desactiva el modo simulación
  void toggleModoSimulacion() {
    modoSimulacion.value = !modoSimulacion.value;

    if (modoSimulacion.value) {
      _locationService.enableSimulationMode();
      _notification.showInfo(
        'Modo simulación',
        'Activado - usa el botón para mover tu ubicación',
      );
    } else {
      _locationService.disableSimulationMode();
      _notification.showInfo(
        'Modo simulación',
        'Desactivado - usando GPS real',
      );
    }
  }

  /// Simula una ubicación específica
  Future<void> simularUbicacion(double lat, double lng) async {
    if (!modoSimulacion.value) {
      modoSimulacion.value = true;
      _locationService.enableSimulationMode();
    }

    // Actualizar localmente
    _locationService.setSimulatedPosition(lat, lng, speed: 30);

    ubicacionActual.value = UbicacionModel(
      lat: lat,
      lng: lng,
      timestamp: DateTime.now(),
      precision: 5,
      velocidad: 30,
    );

    // Enviar al servidor
    if (asignacionCamionId != null && isOnline.value) {
      try {
        final response = await _repository.simularUbicacion(
          asignacionCamionId: asignacionCamionId!,
          lat: lat,
          lng: lng,
          velocidad: 30,
        );

        geofencingStatus.value = response.geofencingStatus;

        if (response.requiereAccion) {
          _mostrarAccionRequerida(response.accionRequerida);
        }
      } catch (e) {
        debugPrint('⚠️ Error al simular ubicación: $e');
      }
    }

    // Verificar geofencing local
    _verificarGeofencingLocal();
  }

  /// Mueve la ubicación simulada gradualmente
  Future<void> moverHacia(double targetLat, double targetLng) async {
    await _locationService.moveSimulatedPositionTo(targetLat, targetLng);

    // Actualizar ubicación actual
    final pos = _locationService.simulatedPosition.value;
    if (pos != null) {
      ubicacionActual.value = UbicacionModel(
        lat: pos.latitude,
        lng: pos.longitude,
        timestamp: DateTime.now(),
        precision: 5,
        velocidad: pos.speed * 3.6,
        rumbo: pos.heading,
      );
    }
  }

  // ==================== GEOFENCING LOCAL ====================

  void _verificarGeofencingLocal() {
    if (tracking.value == null || ubicacionActual.value == null) return;

    final ubicacion = ubicacionActual.value!;
    final puntos = tracking.value!.puntosControl;

    for (final punto in puntos) {
      final dentroDeZona = _locationService.isWithinZone(
        currentLat: ubicacion.lat,
        currentLng: ubicacion.lng,
        zoneLat: punto.lat,
        zoneLng: punto.lng,
        radiusMeters: punto.radio.toDouble(),
      );

      if (dentroDeZona && punto.estado == 'pendiente') {
        geofencingStatus.value = GeofencingStatusModel(
          dentroDeZona: true,
          zonaNombre: punto.nombre,
          zonaTipo: punto.tipo,
          puedeRegistrarLlegada: true,
        );
        return;
      }
    }
  }

  void _mostrarAccionRequerida(String? accion) {
    if (accion == null) return;

    switch (accion) {
      case 'registrar_llegada':
        _notification.showWarning(
          'Punto de control cercano',
          'Registra tu llegada para continuar',
        );
        break;
      case 'registrar_pesaje':
        _notification.showWarning(
          'Balanza detectada',
          'Registra el pesaje antes de continuar',
        );
        break;
      case 'registrar_salida':
        _notification.showInfo(
          'Listo para continuar',
          'Registra tu salida cuando estés listo',
        );
        break;
    }
  }

  // ==================== SINCRONIZACIÓN ====================

  Future<void> _sincronizarDatosPendientes() async {
    if (asignacionCamionId == null) return;

    final pendientes = await _offlineStorage.getPendingLocations(
      asignacionCamionId!,
    );
    if (pendientes.isEmpty) return;

    debugPrint(
      '📤 Sincronizando ${pendientes.length} ubicaciones pendientes...',
    );

    try {
      final result = await _repository.sincronizarUbicaciones(
        asignacionCamionId: asignacionCamionId!,
        ubicaciones: pendientes,
      );

      final sincronizadas = result['ubicacionesSincronizadas'] ?? 0;
      await _offlineStorage.markLocationsSynced(
        asignacionCamionId!,
        sincronizadas,
      );
      await _offlineStorage.saveLastSyncTime(asignacionCamionId!);

      _notification.showSuccess(
        'Sincronización completada',
        '$sincronizadas ubicaciones sincronizadas',
      );
    } catch (e) {
      debugPrint('❌ Error al sincronizar: $e');
    }
  }

  // ==================== FINALIZAR VIAJE ====================

  Future<void> finalizarViaje() async {
    _updateTimer?.cancel();
    await _locationService.stopTracking();

    // Sincronizar datos pendientes antes de finalizar
    if (_offlineStorage.hasPendingData.value) {
      await _sincronizarDatosPendientes();
    }

    isViajeActivo.value = false;
    tracking.value = null;
    ubicacionActual.value = null;
    geofencingStatus.value = null;
    asignacionCamionId = null;

    debugPrint('✅ Viaje finalizado');
  }

  // ==================== GETTERS ====================

  /// Obtiene el próximo punto de control
  PuntoControlModel? get proximoPuntoControl {
    if (tracking.value == null) return null;

    return tracking.value!.puntosControl
        .where((p) => p.estado == 'pendiente')
        .fold<PuntoControlModel?>(null, (prev, current) {
          if (prev == null) return current;
          return current.orden < prev.orden ? current : prev;
        });
  }

  /// Obtiene la distancia al próximo punto
  double? get distanciaProximoPunto {
    final punto = proximoPuntoControl;
    final ubicacion = ubicacionActual.value;

    if (punto == null || ubicacion == null) return null;

    return _locationService.calculateDistance(
      ubicacion.lat,
      ubicacion.lng,
      punto.lat,
      punto.lng,
    );
  }

  /// Verifica si está cerca de un punto de control
  bool get estaCercaDePuntoControl {
    return geofencingStatus.value?.dentroDeZona ?? false;
  }

  /// Verifica si puede registrar llegada
  bool get puedeRegistrarLlegada {
    return geofencingStatus.value?.puedeRegistrarLlegada ?? false;
  }

  /// Verifica si puede registrar salida
  bool get puedeRegistrarSalida {
    return geofencingStatus.value?.puedeRegistrarSalida ?? false;
  }
}
