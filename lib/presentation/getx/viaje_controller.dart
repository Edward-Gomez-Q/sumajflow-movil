// lib/presentation/getx/viaje_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/core/config/tracking_config.dart';
import 'package:sumajflow_movil/core/services/location_service.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/core/services/offline_storage_service.dart';
import 'package:sumajflow_movil/core/exceptions/network_exception.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:sumajflow_movil/data/models/accion_offline_model.dart';
import 'package:sumajflow_movil/data/repositories/lotes_repository.dart';
import 'package:sumajflow_movil/data/repositories/viaje_repository.dart';
import 'package:sumajflow_movil/presentation/getx/tracking_controller.dart';

/// Controller de UI y eventos de negocio del viaje
/// Flujo de 8 pasos sincronizado con backend
class ViajeController extends GetxController {
  final int asignacionId;
  final LoteDetalleViajeModel? loteDetalleInicial;

  // Servicios
  final LocationService _locationService = LocationService.to;
  final NotificationService _notificationService = NotificationService.to;
  final OfflineStorageService _offlineStorage = OfflineStorageService.to;
  final ViajeRepository _viajeRepository = ViajeRepository();
  final LotesRepository _lotesRepository = LotesRepository();

  // Tracking controller (composición)
  late final TrackingController trackingController;

  // Estado UI
  final isLoading = false.obs;
  final isInitializing = true.obs;
  final errorMessage = ''.obs;

  // Estado offline
  final modoOffline = false.obs;
  final accionesPendientes = <AccionOfflineModel>[].obs;
  final sincronizandoAcciones = false.obs;

  // Datos
  final loteDetalle = Rxn<LoteDetalleViajeModel>();
  final estadoActual = EstadoViaje.esperandoIniciar.obs;

  // Formularios generales
  final comentarioTemp = ''.obs;
  final evidenciasTemporales = <File>[].obs;
  final evidenciasSubidas = <String>[].obs;
  final subiendoEvidencia = false.obs;

  // Formulario de pesaje
  final pesoBrutoTemp = 0.0.obs;
  final pesoTaraTemp = 0.0.obs;

  // Formulario de llegada a mina
  final palaOperativa = true.obs;
  final mineralVisible = true.obs;

  // Formulario de carguío
  final mineralCargadoCompletamente = true.obs;

  // Formulario de llegada a almacén
  final confirmacionLlegada = true.obs;

  // Geofencing
  final distanciaAlDestino = Rxn<double>();
  final dentroDeGeofence = false.obs;

  ViajeController({required this.asignacionId, this.loteDetalleInicial});

  @override
  void onInit() {
    super.onInit();

    // Crear tracking controller
    trackingController = TrackingController(asignacionId: asignacionId);

    // Sincronizar estado inicial
    if (loteDetalleInicial != null) {
      loteDetalle.value = loteDetalleInicial;
      _sincronizarEstadoDesdeBackend(loteDetalleInicial!.estado);
    }

    // Recuperar estado offline
    _recuperarEstadoOffline();

    _inicializar();

    // Escuchar cambios de ubicación del tracking controller
    ever(trackingController.currentPosition, (_) => _calcularGeofencing());

    // Monitorear cambios de conectividad
    ever(trackingController.isOnline, (online) {
      modoOffline.value = !online;
      if (online && accionesPendientes.isNotEmpty) {
        debugPrint(
          '🔄 Conexión restaurada, sincronizando acciones pendientes...',
        );
        _sincronizarAccionesPendientes();
      }
    });
  }

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================

  Future<void> _inicializar() async {
    try {
      isInitializing.value = true;
      errorMessage.value = '';

      debugPrint(
        '🎯 Inicializando ViajeController - AsignacionId: $asignacionId',
      );

      if (loteDetalle.value == null) {
        final detalle = await _lotesRepository.getDetalleLote(asignacionId);
        loteDetalle.value = detalle;
        _sincronizarEstadoDesdeBackend(detalle.estado);
      }
      if (estadoActual.value == EstadoViaje.esperandoIniciar) {
        debugPrint('📍 Obteniendo ubicación inicial antes de iniciar viaje...');
        final hasPermission = await _locationService.checkPermissions();
        if (!hasPermission) {
          throw Exception(
            'Se requieren permisos de ubicación. Por favor, acepta los permisos en la configuración.',
          );
        }

        final gpsEnabled = await _locationService.checkGpsStatus();
        if (!gpsEnabled) {
          throw Exception(
            'GPS deshabilitado. Por favor, activa el GPS para continuar.',
          );
        }

        final pos = await _locationService.getCurrentPosition();
        if (pos != null) {
          trackingController.currentPosition.value = pos;
          debugPrint(
            '✅ Ubicación inicial obtenida: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
          );
        } else {
          debugPrint(
            '⚠️ No se pudo obtener ubicación inicial, se reintentará al presionar "Iniciar Viaje"',
          );
        }
      }

      // 2. Si el viaje ya inició, iniciar tracking
      if (estadoActual.value != EstadoViaje.esperandoIniciar) {
        await trackingController.iniciarTracking();
      }

      // 3. Calcular geofencing inicial
      _calcularGeofencing();

      isInitializing.value = false;
      debugPrint('✅ ViajeController inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error al inicializar ViajeController: $e');
      errorMessage.value = e.toString();
      isInitializing.value = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          _notificationService.showError('Error', e.toString());
        }
      });
    }
  }

  Future<void> _recuperarEstadoOffline() async {
    try {
      // Recuperar estado del viaje
      final estadoGuardado = _offlineStorage.getEstadoViajeOffline(
        asignacionId,
      );
      if (estadoGuardado != null) {
        debugPrint('📱 Estado offline encontrado: $estadoGuardado');
      }

      // Recuperar acciones pendientes
      final pendientes = await _offlineStorage.getPendingAcciones();
      final mias = pendientes
          .where((a) => a.asignacionId == asignacionId)
          .toList();
      accionesPendientes.value = mias;

      if (mias.isNotEmpty) {
        debugPrint('📱 ${mias.length} acciones pendientes de sincronizar');
        modoOffline.value = true;
      }
    } catch (e) {
      debugPrint('❌ Error recuperando estado offline: $e');
    }
  }

  void _sincronizarEstadoDesdeBackend(String estadoBackend) {
    estadoActual.value = EstadoViaje.fromString(estadoBackend);
    _limpiarGeofencing();
    debugPrint(
      '📊 Estado sincronizado: $estadoBackend -> ${estadoActual.value}',
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      _calcularGeofencing();
    });
  }

  Future<void> refrescar() async {
    debugPrint('🔄 Refrescando controlador...');
    await _inicializar();
  }

  // ============================================================
  // FLUJO PRINCIPAL - 8 PASOS
  // ============================================================

  Future<void> ejecutarAccionPrincipal() async {
    if (isLoading.value) {
      debugPrint('⏳ Acción en progreso, ignorando...');
      return;
    }

    try {
      isLoading.value = true;

      // ⭐ CAMBIO 2: VALIDAR Y OBTENER UBICACIÓN SI NO ESTÁ DISPONIBLE
      // Este es el cambio principal que soluciona el error
      Position? pos = trackingController.currentPosition.value;

      // ⭐ CAMBIO 2.1: Si no hay ubicación guardada, intentamos obtenerla
      if (pos == null) {
        debugPrint('📍 Ubicación no disponible, obteniendo posición actual...');

        // ⭐ CAMBIO 2.2: Verificar permisos antes de intentar obtener ubicación
        final hasPermission = await _locationService.checkPermissions();
        if (!hasPermission) {
          throw Exception(
            'Se requieren permisos de ubicación para continuar. '
            'Por favor, acepta los permisos en la configuración de tu dispositivo.',
          );
        }

        // ⭐ CAMBIO 2.3: Verificar que el GPS esté habilitado
        final gpsEnabled = await _locationService.checkGpsStatus();
        if (!gpsEnabled) {
          throw Exception(
            'GPS deshabilitado. Por favor, activa el GPS en la configuración de tu dispositivo.',
          );
        }

        // ⭐ CAMBIO 2.4: Intentar obtener la ubicación actual
        pos = await _locationService.getCurrentPosition();

        // ⭐ CAMBIO 2.5: Si después de intentar obtenerla sigue siendo null, lanzar error descriptivo
        if (pos == null) {
          throw Exception(
            'No se pudo obtener tu ubicación actual. '
            'Asegúrate de estar en un lugar con buena señal GPS e intenta nuevamente.',
          );
        }

        // ⭐ CAMBIO 2.6: Guardar la ubicación en el tracking controller
        // para que esté disponible en futuras llamadas
        trackingController.currentPosition.value = pos;
        debugPrint(
          '✅ Ubicación obtenida exitosamente: '
          '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)} '
          '(precisión: ${pos.accuracy.toStringAsFixed(1)}m)',
        );
      } else {
        // ⭐ CAMBIO 2.7: Si ya hay ubicación, solo logueamos que la estamos usando
        debugPrint(
          '📍 Usando ubicación actual: '
          '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)} '
          '(precisión: ${pos.accuracy.toStringAsFixed(1)}m)',
        );
      }

      debugPrint('🎬 Ejecutando acción para estado: ${estadoActual.value}');

      final online = trackingController.isOnline.value;

      switch (estadoActual.value) {
        case EstadoViaje.esperandoIniciar:
          await _paso1_IniciarViaje(pos, online);
          break;

        case EstadoViaje.enCaminoMina:
          await _paso2_LlegadaMina(pos, online);
          break;

        case EstadoViaje.esperandoCarguio:
          await _paso3_ConfirmarCarguio(pos, online);
          break;

        case EstadoViaje.enCaminoBalanzaCoop:
          await _paso4_PesajeCooperativa(pos, online);
          break;

        case EstadoViaje.enCaminoBalanzaDestino:
          await _paso5_PesajeDestino(pos, online);
          break;

        case EstadoViaje.enCaminoAlmacenDestino:
          await _paso6_LlegadaAlmacen(pos, online);
          break;

        case EstadoViaje.descargando:
          await _paso7_ConfirmarDescarga(pos, online);
          break;

        default:
          debugPrint('⚠️ No hay acción definida para este estado');
          break;
      }
    } catch (e) {
      debugPrint('❌ Error en ejecutarAccionPrincipal: $e');
      _mostrarNotificacion('Error', e.toString(), esError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PASO 1: INICIAR VIAJE
  // ============================================================

  Future<void> _paso1_IniciarViaje(Position pos, bool online) async {
    debugPrint('🚀 PASO 1: Iniciar viaje (${online ? "online" : "offline"})');

    if (online) {
      try {
        final response = await _viajeRepository.iniciarViaje(
          asignacionId: asignacionId,
          lat: pos.latitude,
          lng: pos.longitude,
          observaciones: comentarioTemp.value.isNotEmpty
              ? comentarioTemp.value
              : null,
        );

        if (response.success) {
          debugPrint('✅ Viaje iniciado exitosamente');
          _sincronizarEstadoDesdeBackend(response.estadoNuevo);
          await trackingController.iniciarTracking();
          _mostrarNotificacion('Viaje iniciado', response.proximoPaso);
          _limpiarFormulario();
        } else {
          throw Exception(response.message);
        }
      } on NetworkException catch (e) {
        debugPrint('📴 Sin conexión: ${e.message}');
        await _guardarAccionOffline('iniciar_viaje', pos);
        await _cambiarEstadoLocal(EstadoViaje.enCaminoMina);
        await trackingController.iniciarTracking();
        _mostrarNotificacion(
          'Modo Offline',
          'Viaje iniciado localmente. Se sincronizará cuando recuperes conexión.',
          esInfo: true,
        );
        _limpiarFormulario();
      }
    } else {
      await _guardarAccionOffline('iniciar_viaje', pos);
      await _cambiarEstadoLocal(EstadoViaje.enCaminoMina);
      await trackingController.iniciarTracking();
      _mostrarNotificacion(
        'Modo Offline',
        'Viaje iniciado localmente.',
        esInfo: true,
      );
      _limpiarFormulario();
    }
  }

  // ============================================================
  // PASO 2: LLEGADA A MINA
  // ============================================================

  Future<void> _paso2_LlegadaMina(Position pos, bool online) async {
    debugPrint('🏔️ PASO 2: Llegada a mina (${online ? "online" : "offline"})');

    if (online) {
      try {
        final response = await _viajeRepository.confirmarLlegadaMina(
          asignacionId: asignacionId,
          lat: pos.latitude,
          lng: pos.longitude,
          palaOperativa: palaOperativa.value,
          mineralVisible: mineralVisible.value,
          observaciones: comentarioTemp.value.isNotEmpty
              ? comentarioTemp.value
              : null,
          fotoReferenciaUrl: evidenciasSubidas.isNotEmpty
              ? evidenciasSubidas.first
              : null,
        );

        if (response.success) {
          _sincronizarEstadoDesdeBackend(response.estadoNuevo);
          _mostrarNotificacion('Llegada confirmada', response.proximoPaso);
          _limpiarFormulario();
        } else {
          throw Exception(response.message);
        }
      } on NetworkException catch (e) {
        debugPrint('📴 Sin conexión: ${e.message}');
        await _guardarAccionOffline('confirmar_llegada_mina', pos);
        await _cambiarEstadoLocal(EstadoViaje.esperandoCarguio);
        _mostrarNotificacion(
          'Modo Offline',
          'Llegada registrada localmente.',
          esInfo: true,
        );
        _limpiarFormulario();
      }
    } else {
      await _guardarAccionOffline('confirmar_llegada_mina', pos);
      await _cambiarEstadoLocal(EstadoViaje.esperandoCarguio);
      _mostrarNotificacion(
        'Modo Offline',
        'Llegada registrada localmente.',
        esInfo: true,
      );
      _limpiarFormulario();
    }
  }

  // ============================================================
  // PASO 3: CONFIRMAR CARGUÍO
  // ============================================================

  Future<void> _paso3_ConfirmarCarguio(Position pos, bool online) async {
    debugPrint('🚛 PASO 3: Carguío (${online ? "online" : "offline"})');

    // Validar evidencias
    if (evidenciasTemporales.isEmpty && evidenciasSubidas.isEmpty) {
      throw Exception('Debes tomar al menos una foto como evidencia');
    }

    // Subir evidencias si hay conexión
    if (online && evidenciasTemporales.isNotEmpty) {
      try {
        await _subirEvidenciasPendientes();
      } on NetworkException catch (e) {
        debugPrint('📴 No se pudieron subir evidencias');
      }
    }

    if (online) {
      try {
        final response = await _viajeRepository.confirmarCarguio(
          asignacionId: asignacionId,
          lat: pos.latitude,
          lng: pos.longitude,
          mineralCargadoCompletamente: mineralCargadoCompletamente.value,
          observaciones: comentarioTemp.value.isNotEmpty
              ? comentarioTemp.value
              : null,
          fotoCamionCargadoUrl: evidenciasSubidas.isNotEmpty
              ? evidenciasSubidas.first
              : null,
        );

        if (response.success) {
          _sincronizarEstadoDesdeBackend(response.estadoNuevo);
          _mostrarNotificacion('Carguío completado', response.proximoPaso);
          _limpiarFormulario();
        } else {
          throw Exception(response.message);
        }
      } on NetworkException catch (e) {
        debugPrint('📴 Sin conexión: ${e.message}');
        await _guardarAccionOffline('confirmar_carguio', pos);
        await _cambiarEstadoLocal(EstadoViaje.enCaminoBalanzaCoop);
        _mostrarNotificacion(
          'Modo Offline',
          'Carguío registrado localmente.',
          esInfo: true,
        );
        _limpiarFormulario();
      }
    } else {
      await _guardarAccionOffline('confirmar_carguio', pos);
      await _cambiarEstadoLocal(EstadoViaje.enCaminoBalanzaCoop);
      _mostrarNotificacion(
        'Modo Offline',
        'Carguío registrado localmente.',
        esInfo: true,
      );
      _limpiarFormulario();
    }
  }

  // ============================================================
  // PASO 4: PESAJE COOPERATIVA
  // ============================================================

  Future<void> _paso4_PesajeCooperativa(Position pos, bool online) async {
    debugPrint(
      '⚖️ PASO 4: Pesaje cooperativa (${online ? "online" : "offline"})',
    );
    _validarDatosPesaje();

    // Subir evidencias si hay conexión
    if (online && evidenciasTemporales.isNotEmpty) {
      try {
        await _subirEvidenciasPendientes();
      } on NetworkException catch (e) {
        debugPrint('📴 No se pudieron subir evidencias');
      }
    }

    if (online) {
      try {
        final response = await _viajeRepository.registrarPesajeCooperativa(
          asignacionId: asignacionId,
          lat: pos.latitude,
          lng: pos.longitude,
          pesoBrutoKg: pesoBrutoTemp.value,
          pesoTaraKg: pesoTaraTemp.value,
          observaciones: comentarioTemp.value.isNotEmpty
              ? comentarioTemp.value
              : null,
          ticketPesajeUrl: evidenciasSubidas.isNotEmpty
              ? evidenciasSubidas.first
              : null,
        );

        if (response.success) {
          _sincronizarEstadoDesdeBackend(response.estadoNuevo);
          _mostrarNotificacion('Pesaje registrado', response.proximoPaso);
          _limpiarFormulario();
        } else {
          throw Exception(response.message);
        }
      } on NetworkException catch (e) {
        debugPrint('📴 Sin conexión: ${e.message}');
        await _guardarAccionOffline('registrar_pesaje_coop', pos);
        await _cambiarEstadoLocal(EstadoViaje.enCaminoBalanzaDestino);
        _mostrarNotificacion(
          'Modo Offline',
          'Pesaje registrado localmente.',
          esInfo: true,
        );
        _limpiarFormulario();
      }
    } else {
      await _guardarAccionOffline('registrar_pesaje_coop', pos);
      await _cambiarEstadoLocal(EstadoViaje.enCaminoBalanzaDestino);
      _mostrarNotificacion(
        'Modo Offline',
        'Pesaje registrado localmente.',
        esInfo: true,
      );
      _limpiarFormulario();
    }
  }

  // ============================================================
  // PASO 5: PESAJE DESTINO
  // ============================================================

  Future<void> _paso5_PesajeDestino(Position pos, bool online) async {
    debugPrint('⚖️ PASO 5: Pesaje destino (${online ? "online" : "offline"})');
    _validarDatosPesaje();

    // Subir evidencias si hay conexión
    if (online && evidenciasTemporales.isNotEmpty) {
      try {
        await _subirEvidenciasPendientes();
      } on NetworkException catch (e) {
        debugPrint('📴 No se pudieron subir evidencias');
      }
    }

    if (online) {
      try {
        final response = await _viajeRepository.registrarPesajeDestino(
          asignacionId: asignacionId,
          lat: pos.latitude,
          lng: pos.longitude,
          pesoBrutoKg: pesoBrutoTemp.value,
          pesoTaraKg: pesoTaraTemp.value,
          observaciones: comentarioTemp.value.isNotEmpty
              ? comentarioTemp.value
              : null,
          ticketPesajeUrl: evidenciasSubidas.isNotEmpty
              ? evidenciasSubidas.first
              : null,
        );

        if (response.success) {
          _sincronizarEstadoDesdeBackend(response.estadoNuevo);
          _mostrarNotificacion('Pesaje registrado', response.proximoPaso);
          _limpiarFormulario();
        } else {
          throw Exception(response.message);
        }
      } on NetworkException catch (e) {
        debugPrint('📴 Sin conexión: ${e.message}');
        await _guardarAccionOffline('registrar_pesaje_destino', pos);
        await _cambiarEstadoLocal(EstadoViaje.enCaminoAlmacenDestino);
        _mostrarNotificacion(
          'Modo Offline',
          'Pesaje registrado localmente.',
          esInfo: true,
        );
        _limpiarFormulario();
      }
    } else {
      await _guardarAccionOffline('registrar_pesaje_destino', pos);
      await _cambiarEstadoLocal(EstadoViaje.enCaminoAlmacenDestino);
      _mostrarNotificacion(
        'Modo Offline',
        'Pesaje registrado localmente.',
        esInfo: true,
      );
      _limpiarFormulario();
    }
  }

  // ============================================================
  // PASO 6: LLEGADA A ALMACÉN
  // ============================================================

  Future<void> _paso6_LlegadaAlmacen(Position pos, bool online) async {
    debugPrint(
      '🏭 PASO 6: Llegada a almacén (${online ? "online" : "offline"})',
    );

    if (online) {
      try {
        final response = await _viajeRepository.confirmarLlegadaAlmacen(
          asignacionId: asignacionId,
          lat: pos.latitude,
          lng: pos.longitude,
          confirmacionLlegada: confirmacionLlegada.value,
          observaciones: comentarioTemp.value.isNotEmpty
              ? comentarioTemp.value
              : null,
        );

        if (response.success) {
          _sincronizarEstadoDesdeBackend(response.estadoNuevo);
          _mostrarNotificacion(
            'Llegada confirmada',
            response.proximoPaso,
            esInfo: true,
          );
          _limpiarFormulario();
        } else {
          throw Exception(response.message);
        }
      } on NetworkException catch (e) {
        debugPrint('📴 Sin conexión: ${e.message}');
        await _guardarAccionOffline('confirmar_llegada_almacen', pos);
        await _cambiarEstadoLocal(EstadoViaje.descargando);
        _mostrarNotificacion(
          'Modo Offline',
          'Llegada registrada localmente.',
          esInfo: true,
        );
        _limpiarFormulario();
      }
    } else {
      await _guardarAccionOffline('confirmar_llegada_almacen', pos);
      await _cambiarEstadoLocal(EstadoViaje.descargando);
      _mostrarNotificacion(
        'Modo Offline',
        'Llegada registrada localmente.',
        esInfo: true,
      );
      _limpiarFormulario();
    }
  }

  // ============================================================
  // PASO 7: CONFIRMAR DESCARGA
  // ============================================================

  Future<void> _paso7_ConfirmarDescarga(Position pos, bool online) async {
    debugPrint('📦 PASO 7: Descarga (${online ? "online" : "offline"})');

    if (evidenciasTemporales.isEmpty && evidenciasSubidas.isEmpty) {
      throw Exception('Debes tomar al menos una foto como evidencia');
    }

    // Subir evidencias si hay conexión
    if (online && evidenciasTemporales.isNotEmpty) {
      try {
        await _subirEvidenciasPendientes();
      } on NetworkException catch (e) {
        debugPrint('📴 No se pudieron subir evidencias');
      }
    }

    if (online) {
      try {
        final response = await _viajeRepository.confirmarDescarga(
          asignacionId: asignacionId,
          lat: pos.latitude,
          lng: pos.longitude,
          observaciones: comentarioTemp.value.isNotEmpty
              ? comentarioTemp.value
              : null,
        );

        if (response.success) {
          _sincronizarEstadoDesdeBackend(response.estadoNuevo);

          // IMPORTANTE: Ahora necesitamos llamar a finalizar ruta
          // para completar el viaje (PASO 8)
          await _paso8_FinalizarRuta(pos, online);
        } else {
          throw Exception(response.message);
        }
      } on NetworkException catch (e) {
        debugPrint('📴 Sin conexión: ${e.message}');
        await _guardarAccionOffline('confirmar_descarga', pos);
        await _cambiarEstadoLocal(EstadoViaje.completado);
        trackingController.detenerTracking();
        _mostrarNotificacion(
          'Modo Offline',
          '¡Descarga confirmada! Se sincronizará cuando recuperes conexión.',
        );
        _limpiarFormulario();
      }
    } else {
      await _guardarAccionOffline('confirmar_descarga', pos);
      await _cambiarEstadoLocal(EstadoViaje.completado);
      trackingController.detenerTracking();
      _mostrarNotificacion('Modo Offline', '¡Descarga confirmada!');
      _limpiarFormulario();
    }
  }

  // ============================================================
  // PASO 8: FINALIZAR RUTA (Automático después de descarga)
  // ============================================================

  Future<void> _paso8_FinalizarRuta(Position pos, bool online) async {
    debugPrint('✅ PASO 8: Finalizar ruta (${online ? "online" : "offline"})');

    if (online) {
      try {
        final response = await _viajeRepository.finalizarRuta(
          asignacionId: asignacionId,
          lat: pos.latitude,
          lng: pos.longitude,
          observacionesFinales: comentarioTemp.value.isNotEmpty
              ? comentarioTemp.value
              : null,
        );

        if (response.success) {
          _sincronizarEstadoDesdeBackend(response.estadoNuevo);
          trackingController.detenerTracking();
          _mostrarNotificacion('¡Viaje completado!', 'Excelente trabajo');
          _limpiarFormulario();
        } else {
          throw Exception(response.message);
        }
      } on NetworkException catch (e) {
        debugPrint('📴 Sin conexión: ${e.message}');
        await _guardarAccionOffline('finalizar_ruta', pos);
        await _cambiarEstadoLocal(EstadoViaje.completado);
        trackingController.detenerTracking();
        _mostrarNotificacion(
          'Modo Offline',
          '¡Viaje completado! Se sincronizará cuando recuperes conexión.',
        );
        _limpiarFormulario();
      }
    } else {
      await _guardarAccionOffline('finalizar_ruta', pos);
      await _cambiarEstadoLocal(EstadoViaje.completado);
      trackingController.detenerTracking();
      _mostrarNotificacion('Modo Offline', '¡Viaje completado!');
      _limpiarFormulario();
    }
  }

  // ============================================================
  // GESTIÓN DE ACCIONES OFFLINE
  // ============================================================

  Future<void> _guardarAccionOffline(String tipo, Position pos) async {
    final accion = AccionOfflineModel(
      tipo: tipo,
      asignacionId: asignacionId,
      datos: {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'observaciones': comentarioTemp.value,
        'evidencias': evidenciasSubidas.toList(),
        'pesoBruto': pesoBrutoTemp.value,
        'pesoTara': pesoTaraTemp.value,
        'palaOperativa': palaOperativa.value,
        'mineralVisible': mineralVisible.value,
        'mineralCargadoCompletamente': mineralCargadoCompletamente.value,
        'confirmacionLlegada': confirmacionLlegada.value,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
    );

    await _offlineStorage.saveAccionOffline(accion);
    accionesPendientes.add(accion);
    debugPrint('💾 Acción guardada offline: $tipo');
  }

  Future<void> _cambiarEstadoLocal(EstadoViaje nuevoEstado) async {
    estadoActual.value = nuevoEstado;
    _limpiarGeofencing();
    await _offlineStorage.saveEstadoViajeOffline(
      asignacionId,
      nuevoEstado.toString(),
    );
    debugPrint('📊 Estado cambiado localmente a: $nuevoEstado');
  }

  void _limpiarGeofencing() {
    distanciaAlDestino.value = null;
    dentroDeGeofence.value = false;
    debugPrint('🧹 Geofencing limpiado al cambiar de estado');
  }

  Future<void> _sincronizarAccionesPendientes() async {
    if (sincronizandoAcciones.value) {
      debugPrint('⏳ Ya hay una sincronización en progreso');
      return;
    }

    if (!trackingController.isOnline.value) {
      debugPrint('📴 Sin conexión, no se puede sincronizar');
      return;
    }

    if (accionesPendientes.isEmpty) {
      debugPrint('✅ No hay acciones pendientes');
      return;
    }

    try {
      sincronizandoAcciones.value = true;
      debugPrint(
        '🔄 Sincronizando ${accionesPendientes.length} acciones pendientes...',
      );

      final accionesSincronizadas = <String>[];
      int exitosas = 0;
      int fallidas = 0;

      for (var accion in accionesPendientes) {
        try {
          await _ejecutarAccionOffline(accion);
          accionesSincronizadas.add(accion.id);
          exitosas++;
          debugPrint('✅ Acción sincronizada: ${accion.tipo}');
        } catch (e) {
          fallidas++;
          debugPrint('❌ Error sincronizando acción ${accion.tipo}: $e');

          if (e is NetworkException) {
            debugPrint('📴 Conexión perdida, deteniendo sincronización');
            break;
          }

          final accionActualizada = accion.copyWith(
            intentos: accion.intentos + 1,
          );
          await _offlineStorage.updateAccionOffline(accionActualizada);

          if (accionActualizada.intentos >= 3) {
            debugPrint(
              '⚠️ Acción descartada después de 3 intentos: ${accion.tipo}',
            );
            accionesSincronizadas.add(accion.id);
          }
        }
      }

      if (accionesSincronizadas.isNotEmpty) {
        await _offlineStorage.markAccionesSynced(accionesSincronizadas);
        accionesPendientes.removeWhere(
          (a) => accionesSincronizadas.contains(a.id),
        );
      }

      debugPrint(
        '🔄 Sincronización completada - Éxito: $exitosas, Fallidas: $fallidas',
      );

      if (exitosas > 0) {
        _mostrarNotificacion(
          'Sincronización completada',
          '$exitosas ${exitosas == 1 ? "acción sincronizada" : "acciones sincronizadas"}',
          esInfo: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Error en sincronización: $e');
    } finally {
      sincronizandoAcciones.value = false;
    }
  }

  Future<void> _ejecutarAccionOffline(AccionOfflineModel accion) async {
    final datos = accion.datos;
    final lat = datos['lat'] as double;
    final lng = datos['lng'] as double;

    switch (accion.tipo) {
      case 'iniciar_viaje':
        await _viajeRepository.iniciarViaje(
          asignacionId: asignacionId,
          lat: lat,
          lng: lng,
          observaciones: datos['observaciones'],
        );
        break;

      case 'confirmar_llegada_mina':
        await _viajeRepository.confirmarLlegadaMina(
          asignacionId: asignacionId,
          lat: lat,
          lng: lng,
          palaOperativa: datos['palaOperativa'] ?? true,
          mineralVisible: datos['mineralVisible'] ?? true,
          observaciones: datos['observaciones'],
          fotoReferenciaUrl: (datos['evidencias'] as List?)?.firstOrNull,
        );
        break;

      case 'confirmar_carguio':
        await _viajeRepository.confirmarCarguio(
          asignacionId: asignacionId,
          lat: lat,
          lng: lng,
          mineralCargadoCompletamente:
              datos['mineralCargadoCompletamente'] ?? true,
          observaciones: datos['observaciones'],
          fotoCamionCargadoUrl: (datos['evidencias'] as List?)?.firstOrNull,
        );
        break;

      case 'registrar_pesaje_coop':
        await _viajeRepository.registrarPesajeCooperativa(
          asignacionId: asignacionId,
          lat: lat,
          lng: lng,
          pesoBrutoKg: datos['pesoBruto'],
          pesoTaraKg: datos['pesoTara'],
          observaciones: datos['observaciones'],
          ticketPesajeUrl: (datos['evidencias'] as List?)?.firstOrNull,
        );
        break;

      case 'registrar_pesaje_destino':
        await _viajeRepository.registrarPesajeDestino(
          asignacionId: asignacionId,
          lat: lat,
          lng: lng,
          pesoBrutoKg: datos['pesoBruto'],
          pesoTaraKg: datos['pesoTara'],
          observaciones: datos['observaciones'],
          ticketPesajeUrl: (datos['evidencias'] as List?)?.firstOrNull,
        );
        break;

      case 'confirmar_llegada_almacen':
        await _viajeRepository.confirmarLlegadaAlmacen(
          asignacionId: asignacionId,
          lat: lat,
          lng: lng,
          confirmacionLlegada: datos['confirmacionLlegada'] ?? true,
          observaciones: datos['observaciones'],
        );
        break;

      case 'confirmar_descarga':
        await _viajeRepository.confirmarDescarga(
          asignacionId: asignacionId,
          lat: lat,
          lng: lng,
          observaciones: datos['observaciones'],
        );
        break;

      case 'finalizar_ruta':
        await _viajeRepository.finalizarRuta(
          asignacionId: asignacionId,
          lat: lat,
          lng: lng,
          observacionesFinales: datos['observaciones'],
        );
        break;

      default:
        debugPrint('⚠️ Tipo de acción desconocido: ${accion.tipo}');
    }
  }

  // ============================================================
  // VALIDACIONES
  // ============================================================

  void _validarDatosPesaje() {
    if (pesoBrutoTemp.value <= 0) {
      throw Exception('Ingresa el peso bruto');
    }
    if (pesoTaraTemp.value <= 0) {
      throw Exception('Ingresa el peso tara');
    }
    if (pesoTaraTemp.value >= pesoBrutoTemp.value) {
      throw Exception('El peso tara debe ser menor al peso bruto');
    }
    if (evidenciasTemporales.isEmpty && evidenciasSubidas.isEmpty) {
      throw Exception('Toma una foto del ticket de pesaje');
    }
  }

  void _mostrarNotificacion(
    String titulo,
    String mensaje, {
    bool esError = false,
    bool esInfo = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        if (esError) {
          _notificationService.showError(titulo, mensaje);
        } else if (esInfo) {
          _notificationService.showInfo(titulo, mensaje);
        } else {
          _notificationService.showSuccess(titulo, mensaje);
        }
      } else {
        debugPrint('📢 $titulo: $mensaje');
      }
    });
  }

  // ============================================================
  // EVIDENCIAS
  // ============================================================

  void agregarEvidencia(File file) {
    if (evidenciasTemporales.length < 5) {
      evidenciasTemporales.add(file);
      debugPrint('📸 Evidencia agregada: ${file.path}');
    }
  }

  void eliminarEvidencia(int index) {
    if (index >= 0 && index < evidenciasTemporales.length) {
      evidenciasTemporales.removeAt(index);
      debugPrint('🗑️ Evidencia eliminada en índice: $index');
    }
  }

  Future<void> _subirEvidenciasPendientes() async {
    if (evidenciasTemporales.isEmpty) {
      debugPrint('ℹ️ No hay evidencias pendientes de subir');
      return;
    }

    subiendoEvidencia.value = true;
    debugPrint('📤 Subiendo ${evidenciasTemporales.length} evidencias...');

    try {
      for (final file in evidenciasTemporales) {
        debugPrint('📤 Subiendo evidencia: ${file.path}');
        final objectName = await _viajeRepository.uploadEvidencia(
          file,
          asignacionId,
        );
        evidenciasSubidas.add(objectName);
        debugPrint('✅ Evidencia subida: $objectName');
      }
      evidenciasTemporales.clear();
      debugPrint('✅ Todas las evidencias subidas correctamente');
    } catch (e) {
      debugPrint('❌ Error al subir evidencias: $e');
      rethrow;
    } finally {
      subiendoEvidencia.value = false;
    }
  }

  // ============================================================
  // FORMULARIOS
  // ============================================================

  void actualizarComentario(String valor) => comentarioTemp.value = valor;
  void actualizarPesoBruto(double valor) => pesoBrutoTemp.value = valor;
  void actualizarPesoTara(double valor) => pesoTaraTemp.value = valor;
  void actualizarPalaOperativa(bool valor) => palaOperativa.value = valor;
  void actualizarMineralVisible(bool valor) => mineralVisible.value = valor;
  void actualizarMineralCargado(bool valor) =>
      mineralCargadoCompletamente.value = valor;
  void actualizarConfirmacionLlegada(bool valor) =>
      confirmacionLlegada.value = valor;

  double get pesoNetoCalculado {
    if (pesoBrutoTemp.value <= 0 || pesoTaraTemp.value <= 0) return 0;
    if (pesoTaraTemp.value >= pesoBrutoTemp.value) return 0;
    return pesoBrutoTemp.value - pesoTaraTemp.value;
  }

  void _limpiarFormulario() {
    comentarioTemp.value = '';
    pesoBrutoTemp.value = 0.0;
    pesoTaraTemp.value = 0.0;
    evidenciasTemporales.clear();
    evidenciasSubidas.clear();
    palaOperativa.value = true;
    mineralVisible.value = true;
    mineralCargadoCompletamente.value = true;
    confirmacionLlegada.value = true;
    _limpiarGeofencing();
    debugPrint('🧹 Formulario limpiado');
  }

  // ============================================================
  // GEOFENCING
  // ============================================================

  void _calcularGeofencing() {
    final pos = trackingController.currentPosition.value;
    final waypoint = proximoWaypoint;

    if (pos == null || waypoint == null || !waypoint.tieneCoordenadas) {
      distanciaAlDestino.value = null;
      dentroDeGeofence.value = false;
      return;
    }

    final distancia = _locationService.calculateDistance(
      pos.latitude,
      pos.longitude,
      waypoint.latitud!,
      waypoint.longitud!,
    );

    distanciaAlDestino.value = distancia;
    final dentroAntes = dentroDeGeofence.value;
    dentroDeGeofence.value = distancia <= _getRadioGeofence();

    if (!dentroAntes && dentroDeGeofence.value) {
      debugPrint('📍 Entró en geofence - Distancia: ${distancia.toInt()}m');
    }
  }

  double _getRadioGeofence() {
    switch (estadoActual.value) {
      case EstadoViaje.enCaminoMina:
        return TrackingConfig.radioMina;
      case EstadoViaje.enCaminoBalanzaCoop:
      case EstadoViaje.enCaminoBalanzaDestino:
        return TrackingConfig.radioBalanza;
      case EstadoViaje.enCaminoAlmacenDestino:
        return TrackingConfig.radioAlmacen;
      default:
        return TrackingConfig.radioMina;
    }
  }

  // ============================================================
  // GETTERS PARA UI
  // ============================================================

  bool get isOnline => trackingController.isOnline.value;
  bool get isPaused => trackingController.isPaused.value;
  bool get estaDentroDelGeofence => dentroDeGeofence.value;

  WaypointModel? get proximoWaypoint {
    final lote = loteDetalle.value;
    if (lote == null) return null;

    switch (estadoActual.value) {
      case EstadoViaje.esperandoIniciar:
      case EstadoViaje.enCaminoMina:
        return lote.puntoOrigen;
      case EstadoViaje.enCaminoBalanzaCoop:
        return lote.puntoBalanzaCoop;
      case EstadoViaje.enCaminoBalanzaDestino:
        return lote.puntoBalanzaDestino;
      case EstadoViaje.enCaminoAlmacenDestino:
        return lote.puntoAlmacenDestino;
      default:
        return null;
    }
  }

  String get distanciaFormateada {
    final dist = distanciaAlDestino.value;
    if (dist == null) return 'Calculando...';
    if (dist < 1000) return '${dist.toInt()} m';
    return '${(dist / 1000).toStringAsFixed(1)} km';
  }

  String get textoBotonPrincipal {
    switch (estadoActual.value) {
      case EstadoViaje.esperandoIniciar:
        return 'Iniciar Viaje';
      case EstadoViaje.enCaminoMina:
        return dentroDeGeofence.value ? 'Confirmar Llegada' : 'En camino...';
      case EstadoViaje.esperandoCarguio:
        return 'Confirmar Carguío';
      case EstadoViaje.enCaminoBalanzaCoop:
        return dentroDeGeofence.value ? 'Registrar Pesaje' : 'En camino...';
      case EstadoViaje.enCaminoBalanzaDestino:
        return dentroDeGeofence.value ? 'Registrar Pesaje' : 'En camino...';
      case EstadoViaje.enCaminoAlmacenDestino:
        return dentroDeGeofence.value ? 'Confirmar Llegada' : 'En camino...';
      case EstadoViaje.descargando:
        return 'Finalizar Descarga';
      case EstadoViaje.completado:
        return 'Viaje Completado';
      default:
        return 'Continuar';
    }
  }

  IconData get iconoBotonPrincipal {
    switch (estadoActual.value) {
      case EstadoViaje.esperandoIniciar:
        return Icons.play_arrow_rounded;
      case EstadoViaje.enCaminoMina:
      case EstadoViaje.enCaminoBalanzaCoop:
      case EstadoViaje.enCaminoBalanzaDestino:
      case EstadoViaje.enCaminoAlmacenDestino:
        return dentroDeGeofence.value
            ? Icons.check_rounded
            : Icons.navigation_rounded;
      case EstadoViaje.esperandoCarguio:
        return Icons.inventory_2_rounded;
      case EstadoViaje.descargando:
        return Icons.download_rounded;
      case EstadoViaje.completado:
        return Icons.check_circle_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  RxBool get botonPrincipalHabilitado {
    final habilitado = _evaluarBotonHabilitado();
    return habilitado.obs;
  }

  bool _evaluarBotonHabilitado() {
    if (isLoading.value) return false;

    switch (estadoActual.value) {
      case EstadoViaje.esperandoIniciar:
        return true;
      case EstadoViaje.enCaminoMina:
      case EstadoViaje.enCaminoBalanzaCoop:
      case EstadoViaje.enCaminoBalanzaDestino:
      case EstadoViaje.enCaminoAlmacenDestino:
        return dentroDeGeofence.value;
      case EstadoViaje.esperandoCarguio:
        return evidenciasTemporales.isNotEmpty || evidenciasSubidas.isNotEmpty;
      case EstadoViaje.descargando:
        return evidenciasTemporales.isNotEmpty || evidenciasSubidas.isNotEmpty;
      case EstadoViaje.completado:
        return false;
      default:
        return false;
    }
  }

  String get descripcionEstadoActual {
    switch (estadoActual.value) {
      case EstadoViaje.esperandoIniciar:
        return 'Listo para comenzar el viaje';
      case EstadoViaje.enCaminoMina:
        return 'Dirígete a la mina ${loteDetalle.value?.minaNombre ?? ""}';
      case EstadoViaje.esperandoCarguio:
        return 'Confirma cuando el carguío esté completo';
      case EstadoViaje.enCaminoBalanzaCoop:
        return 'Hacia balanza de cooperativa';
      case EstadoViaje.enCaminoBalanzaDestino:
        return 'Hacia balanza de destino';
      case EstadoViaje.enCaminoAlmacenDestino:
        return 'Hacia almacén de descarga';
      case EstadoViaje.descargando:
        return 'Descargando mineral';
      case EstadoViaje.completado:
        return 'Viaje finalizado exitosamente';
      default:
        return '';
    }
  }

  double get progresoViaje => estadoActual.value.progreso;

  @override
  void onClose() {
    debugPrint('🔚 Cerrando ViajeController...');
    trackingController.detenerTracking();
    super.onClose();
  }
}
