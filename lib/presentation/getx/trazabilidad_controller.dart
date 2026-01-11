// lib/presentation/getx/trazabilidad_controller.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart'; // Añadir dependencia
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/core/services/location_service.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/core/services/offline_storage_service.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/data/repositories/lotes_repository.dart';
import 'package:sumajflow_movil/data/repositories/tracking_repository.dart';
import 'package:sumajflow_movil/data/repositories/viaje_repository.dart';

class TrazabilidadController extends GetxController {
  final LocationService _locationService = LocationService.to;
  final NotificationService _notificationService = NotificationService.to;
  final OfflineStorageService _offlineStorage = OfflineStorageService.to;
  final TrackingRepository _trackingRepository = TrackingRepository();
  final ViajeRepository _viajeRepository = ViajeRepository();
  final LotesRepository _lotesRepository = LotesRepository();

  // Parámetros recibidos
  late final int asignacionId;

  var loteDetalle = Rxn<LoteDetalleViajeModel>();

  // Estado observable
  var isLoading = true.obs;
  var isInitializing = true.obs;
  var errorMessage = ''.obs;
  var isOnline = true.obs;

  var isTrackingActive = true.obs;
  var isPaused = false.obs;

  // Tracking
  var trackingData = Rxn<TrackingModel>();
  var currentPosition = Rxn<Position>();
  var estadoViaje = 'Desconocido'.obs;

  // Timers
  Timer? _locationUpdateTimer;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription; //   Nuevo

  // Configuración
  static const int _locationUpdateIntervalSeconds = 30;
  static const int _syncIntervalSeconds = 60;

  TrazabilidadController({
    required this.asignacionId,
    LoteDetalleViajeModel? loteDetalleInicial,
  }) {
    if (loteDetalleInicial != null) {
      loteDetalle.value = loteDetalleInicial;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _inicializar();
    _monitorearConectividad(); //   Nuevo
  }

  ///   Monitorea cambios de conectividad
  void _monitorearConectividad() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      final wasOffline = !isOnline.value;
      isOnline.value = hasConnection;

      if (hasConnection && wasOffline) {
        print('🌐 Conexión restaurada - Sincronizando datos offline...');
        _sincronizarDatosOffline();
      } else if (!hasConnection) {
        print('📡 Sin conexión - Modo offline activado');
        _notificationService.showWarning(
          'Sin conexión',
          'Los datos se guardarán localmente',
        );
      }
    });
  }

  Future<void> reanudarTracking() async {
    print('▶️ Reanudando tracking - AsignacionId: $asignacionId');

    try {
      isTrackingActive.value = true;
      isPaused.value = false;

      // Verificar permisos y GPS
      final hasPermission = await _locationService.checkPermissions();
      if (!hasPermission) {
        throw Exception('Permisos de ubicación requeridos');
      }

      final gpsEnabled = await _locationService.checkGpsStatus();
      if (!gpsEnabled) {
        throw Exception('GPS deshabilitado');
      }

      // Obtener ubicación actual
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        currentPosition.value = position;
        print(
          '📍 Ubicación actual: ${position.latitude}, ${position.longitude}',
        );
      }

      // Reiniciar tracking continuo
      await _iniciarTrackingContinuo();

      // Reiniciar sincronización periódica
      _iniciarSincronizacionPeriodica();

      _notificationService.showSuccess(
        'Tracking reanudado',
        'El seguimiento se ha reanudado correctamente',
      );

      print('  Tracking reanudado correctamente');
    } catch (e) {
      print('❌ Error al reanudar tracking: $e');

      isTrackingActive.value = false;
      isPaused.value = true;

      _notificationService.showError('Error al reanudar', e.toString());
    }
  }

  Future<void> _inicializar() async {
    try {
      isInitializing.value = true;
      isLoading.value = true;

      print('🎯 Inicializando TrazabilidadController');
      print('   AsignacionId: $asignacionId');

      // Obtener detalle del lote si no existe
      if (loteDetalle.value == null) {
        print('📥 Obteniendo detalle del lote...');
        final detalle = await _lotesRepository.getDetalleLote(asignacionId);
        loteDetalle.value = detalle;
      }

      print('   Estado inicial: ${loteDetalle.value?.estado ?? "Desconocido"}');

      // Verificar permisos de ubicación
      final hasPermission = await _locationService.checkPermissions();
      if (!hasPermission) {
        throw Exception('Permisos de ubicación requeridos');
      }

      // Verificar GPS
      final gpsEnabled = await _locationService.checkGpsStatus();
      if (!gpsEnabled) {
        throw Exception('GPS deshabilitado. Por favor, actívalo.');
      }

      // Obtener ubicación inicial
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        throw Exception('No se pudo obtener la ubicación inicial');
      }

      currentPosition.value = position;
      print(
        '📍 Ubicación inicial: ${position.latitude}, ${position.longitude}',
      );

      //   Verificar si existe tracking o iniciar viaje
      await _verificarOIniciarViaje(position);

      // Iniciar tracking continuo
      await _iniciarTrackingContinuo();

      // Iniciar sincronización periódica
      _iniciarSincronizacionPeriodica();

      isInitializing.value = false;
      isLoading.value = false;

      print('  TrazabilidadController inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar TrazabilidadController: $e');
      errorMessage.value = e.toString();
      isInitializing.value = false;
      isLoading.value = false;

      _notificationService.showError('Error de inicialización', e.toString());
    }
  }

  Future<void> _verificarOIniciarViaje(Position position) async {
    try {
      print('🔍 Verificando tracking existente...');

      try {
        //   Intentar obtener tracking existente del backend
        final tracking = await _trackingRepository.getTracking(asignacionId);

        trackingData.value = tracking;
        estadoViaje.value = tracking.estadoViaje;

        print('  Tracking existente encontrado - Reanudando');
        print('   Estado: ${tracking.estadoViaje}');
        print('   Última sincronización: ${tracking.ultimaSincronizacion}');

        _notificationService.showSuccess(
          'Viaje reanudado',
          'Continuando desde ${tracking.estadoViaje}',
        );

        return;
      } catch (e) {
        print('⚠️ No existe tracking, verificando si debe iniciar viaje...');
      }

      //   Si no existe tracking y el estado es "Esperando iniciar", iniciar viaje
      if (loteDetalle.value?.estado == 'Esperando iniciar') {
        print('🚀 Iniciando viaje nuevo...');

        final response = await _viajeRepository.iniciarViaje(
          asignacionId: asignacionId,
          lat: position.latitude,
          lng: position.longitude,
        );

        print('  Viaje iniciado: ${response.message}');
        print('   Estado anterior: ${response.estadoAnterior}');
        print('   Estado nuevo: ${response.estadoNuevo}');

        estadoViaje.value = response.estadoNuevo;

        _notificationService.showSuccess(
          'Viaje iniciado',
          response.proximoPaso,
        );

        // Obtener tracking recién creado
        await Future.delayed(const Duration(milliseconds: 500));
        final tracking = await _trackingRepository.getTracking(asignacionId);
        trackingData.value = tracking;
      } else {
        // Si el estado no es "Esperando iniciar", solo usar el estado actual
        estadoViaje.value = loteDetalle.value?.estado ?? 'Desconocido';
        print('ℹ️ Estado del lote: ${estadoViaje.value}');
      }
    } catch (e) {
      print('❌ Error al verificar/iniciar viaje: $e');
      rethrow;
    }
  }

  Future<void> _iniciarTrackingContinuo() async {
    try {
      print('📡 Iniciando tracking continuo de ubicación');

      final success = await _locationService.startTracking(
        onUpdate: _onLocationUpdate,
        onErrorCallback: _onLocationError,
        intervalSeconds: _locationUpdateIntervalSeconds,
      );

      if (!success) {
        throw Exception('No se pudo iniciar el tracking de ubicación');
      }

      // Timer de respaldo
      _locationUpdateTimer = Timer.periodic(
        Duration(seconds: _locationUpdateIntervalSeconds),
        (_) => _actualizarUbicacionManual(),
      );

      print('  Tracking continuo iniciado');
    } catch (e) {
      print('❌ Error al iniciar tracking continuo: $e');
      rethrow;
    }
  }

  void _onLocationUpdate(Position position) {
    if (!isTrackingActive.value) {
      print('⏸️ Tracking pausado - Ignorando actualización de ubicación');
      return;
    }

    currentPosition.value = position;

    print('📍 Nueva ubicación: ${position.latitude}, ${position.longitude}');
    print('   Velocidad: ${position.speed} m/s');
    print('   Precisión: ${position.accuracy} m');

    _enviarUbicacionAlBackend(position);
  }

  void _onLocationError(String error) {
    print('❌ Error de ubicación: $error');
    _guardarUbicacionOffline();
  }

  Future<void> _enviarUbicacionAlBackend(Position position) async {
    //   Solo enviar si el tracking está activo
    if (!isTrackingActive.value) {
      print('⏸️ Tracking pausado - No se envía ubicación al backend');
      return;
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
      );

      if (response.success) {
        print('  Ubicación enviada correctamente');
        isOnline.value = true;

        if (response.nuevoEstadoViaje != null &&
            response.nuevoEstadoViaje != estadoViaje.value) {
          estadoViaje.value = response.nuevoEstadoViaje!;
          print(
            '🔄 Estado del viaje actualizado: ${response.nuevoEstadoViaje}',
          );
        }

        if (response.requiereAccion && response.accionRequerida != null) {
          _notificarAccionRequerida(response);
        }
      }
    } catch (e) {
      print('❌ Error al enviar ubicación: $e');
      isOnline.value = false;
      await _guardarUbicacionOffline(position);
    }
  }

  Future<void> _guardarUbicacionOffline([Position? position]) async {
    try {
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

      print(
        '💾 Ubicación guardada offline (total pendientes: ${_offlineStorage.totalPendingLocations})',
      );
    } catch (e) {
      print('❌ Error al guardar ubicación offline: $e');
    }
  }

  Future<void> _actualizarUbicacionManual() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _onLocationUpdate(position);
      }
    } catch (e) {
      print('❌ Error en actualización manual: $e');
    }
  }

  void _iniciarSincronizacionPeriodica() {
    _syncTimer = Timer.periodic(
      Duration(seconds: _syncIntervalSeconds),
      (_) => _sincronizarDatosOffline(),
    );

    print(
      '🔄 Sincronización periódica iniciada (cada $_syncIntervalSeconds segundos)',
    );
  }

  Future<void> _sincronizarDatosOffline() async {
    try {
      final ubicacionesPendientes = await _offlineStorage.getPendingLocations(
        asignacionId,
      );

      if (ubicacionesPendientes.isEmpty) {
        print('ℹ️ No hay ubicaciones pendientes de sincronizar');
        return;
      }

      print(
        '🔄 Sincronizando ${ubicacionesPendientes.length} ubicaciones offline...',
      );

      final response = await _trackingRepository.sincronizarUbicaciones(
        asignacionCamionId: asignacionId,
        ubicaciones: ubicacionesPendientes,
      );

      // Marcar como sincronizadas
      await _offlineStorage.markLocationsSynced(
        asignacionId,
        ubicacionesPendientes.length,
      );

      isOnline.value = true; //   Confirmar que estamos online

      print('  Sincronización completada');
      print('   Sincronizadas: ${response['ubicacionesSincronizadas']}');
      print('   Fallidas: ${response['ubicacionesFallidas'] ?? 0}');

      _notificationService.showSuccess(
        'Datos sincronizados',
        '${response['ubicacionesSincronizadas']} ubicaciones enviadas',
      );
    } catch (e) {
      print('❌ Error al sincronizar datos offline: $e');
      isOnline.value = false;
    }
  }

  void pausarTracking() {
    print('⏸️ Pausando tracking - AsignacionId: $asignacionId');

    isTrackingActive.value = false;
    isPaused.value = true;

    // Cancelar timers
    _locationUpdateTimer?.cancel();
    _syncTimer?.cancel();

    // Detener tracking de ubicación
    _locationService.stopTracking();

    // Sincronizar datos pendientes antes de pausar
    _sincronizarDatosOffline();

    _notificationService.showInfo(
      'Tracking pausado',
      'El seguimiento se ha detenido temporalmente',
    );

    print('  Tracking pausado correctamente');
  }

  void _notificarAccionRequerida(ActualizacionUbicacionResponse response) {
    String titulo = '';
    String mensaje = '';

    switch (response.accionRequerida) {
      case 'registrar_llegada':
        titulo = 'Has llegado';
        mensaje =
            'Confirma tu llegada a ${response.geofencingStatus?.zonaNombre ?? "el punto de control"}';
        break;
      case 'registrar_pesaje':
        titulo = 'Registrar pesaje';
        mensaje =
            'Debes registrar el pesaje en ${response.geofencingStatus?.zonaNombre ?? "la balanza"}';
        break;
      case 'registrar_salida':
        titulo = 'Registrar salida';
        mensaje =
            'Confirma tu salida de ${response.geofencingStatus?.zonaNombre ?? "el punto de control"}';
        break;
      default:
        return;
    }

    _notificationService.showInfo(titulo, mensaje);
  }

  WaypointModel? get proximoWaypoint {
    if (loteDetalle.value == null) return null;

    switch (estadoViaje.value) {
      case 'En camino a la mina':
        return loteDetalle.value!.puntoOrigen;
      case 'En camino balanza cooperativa':
        return loteDetalle.value!.puntoBalanzaCoop;
      case 'En camino balanza destino':
        return loteDetalle.value!.puntoBalanzaDestino;
      case 'En camino almacén destino':
        return loteDetalle.value!.puntoAlmacenDestino;
      default:
        return null;
    }
  }

  double? get distanciaProximoWaypoint {
    if (currentPosition.value == null || proximoWaypoint == null) return null;
    if (!proximoWaypoint!.tieneCoordenadas) return null;

    return _locationService.calculateDistance(
      currentPosition.value!.latitude,
      currentPosition.value!.longitude,
      proximoWaypoint!.latitud!,
      proximoWaypoint!.longitud!,
    );
  }

  String get distanciaProximoWaypointTexto {
    final distancia = distanciaProximoWaypoint;
    if (distancia == null) return 'Calculando...';

    if (distancia < 1000) {
      return '${distancia.toInt()} m';
    } else {
      return '${(distancia / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  void onClose() {
    print('🛑 Deteniendo TrazabilidadController - AsignacionId: $asignacionId');

    //   Cancelar timers
    _locationUpdateTimer?.cancel();
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();

    //   Detener tracking de ubicación
    _locationService.stopTracking();

    // Sincronizar datos pendientes antes de salir
    if (isOnline.value) {
      _sincronizarDatosOffline();
    }

    print('  TrazabilidadController detenido correctamente');

    super.onClose();
  }
}
