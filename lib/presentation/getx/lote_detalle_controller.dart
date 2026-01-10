// lib/presentation/getx/lote_detalle_controller.dart

import 'package:get/get.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:sumajflow_movil/data/repositories/lotes_repository.dart';

class LoteDetalleController extends GetxController {
  final LotesRepository _lotesRepository = LotesRepository();
  final NotificationService _notificationService = NotificationService.to;

  // ID de la asignación recibido por constructor
  final int asignacionId;

  // Estado observable
  var isLoading = false.obs;
  var loteDetalle = Rxn<LoteDetalleViajeModel>();

  // Constructor que recibe el asignacionId
  LoteDetalleController(this.asignacionId);

  @override
  void onInit() {
    super.onInit();
    cargarDetalleLote();
  }

  /// Carga el detalle del lote
  Future<void> cargarDetalleLote() async {
    isLoading.value = true;
    try {
      print('🔄 Cargando detalle del lote - AsignacionId: $asignacionId');

      final detalle = await _lotesRepository.getDetalleLote(asignacionId);

      loteDetalle.value = detalle;

      print('✅ Detalle del lote cargado exitosamente');
      print('   Estado: ${detalle.estado}');
      print('   Código: ${detalle.codigoLote}');
      print('   Waypoints válidos: ${detalle.tieneRutaCompleta}');
    } catch (e) {
      print('❌ Error al cargar detalle del lote: $e');
      _notificationService.showError(
        'Error',
        'No se pudo cargar el detalle del lote: ${e.toString()}',
      );
      // Volver atrás si hay error
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresca el detalle
  Future<void> refrescar() async {
    await cargarDetalleLote();
  }

  /// Determina el texto del botón principal según el estado
  String get textoBotonPrincipal {
    if (loteDetalle.value == null) return '';

    final estado = loteDetalle.value!.estado;

    switch (estado) {
      case 'Esperando iniciar':
        return 'Empezar Viaje';
      case 'Completado':
        return ''; // No mostrar botón
      default:
        return 'Reanudar Viaje';
    }
  }

  /// Verifica si debe mostrar el botón principal
  bool get mostrarBotonPrincipal {
    return textoBotonPrincipal.isNotEmpty;
  }

  /// Obtiene el color del estado
  String get colorEstado {
    if (loteDetalle.value == null) return '#6B7280';

    final estado = loteDetalle.value!.estado;

    switch (estado) {
      case 'Esperando iniciar':
        return '#F59E0B'; // Amber
      case 'En camino a la mina':
      case 'En camino balanza cooperativa':
      case 'En camino balanza destino':
      case 'En camino almacén destino':
        return '#3B82F6'; // Blue
      case 'Esperando carguío':
        return '#8B5CF6'; // Purple
      case 'Descargando':
        return '#EC4899'; // Pink
      case 'Completado':
        return '#10B981'; // Green
      default:
        return '#6B7280'; // Gray
    }
  }

  /// Obtiene el texto descriptivo del estado
  String get estadoDescriptivo {
    if (loteDetalle.value == null) return '';

    final estado = loteDetalle.value!.estado;

    switch (estado) {
      case 'Esperando iniciar':
        return 'Pendiente de inicio';
      case 'En camino a la mina':
        return 'Dirigiéndose a la mina';
      case 'Esperando carguío':
        return 'Esperando carga de mineral';
      case 'En camino balanza cooperativa':
        return 'Hacia balanza cooperativa';
      case 'En camino balanza destino':
        return 'Hacia balanza de destino';
      case 'En camino almacén destino':
        return 'Hacia almacén de destino';
      case 'Descargando':
        return 'Descargando mineral';
      case 'Completado':
        return 'Viaje completado';
      default:
        return estado;
    }
  }

  /// Acción del botón principal (navegar a la vista de viaje activo)
  void onPresionarBotonPrincipal() {
    if (loteDetalle.value == null) return;

    final estado = loteDetalle.value!.estado;

    if (estado == 'Esperando iniciar') {
      // Navegar a vista de inicio de viaje
      Get.toNamed(
        '/viaje/iniciar',
        arguments: {
          'asignacionId': asignacionId,
          'loteDetalle': loteDetalle.value,
        },
      );
    } else {
      // Navegar a vista de viaje en curso
      Get.toNamed(
        '/viaje/activo',
        arguments: {
          'asignacionId': asignacionId,
          'loteDetalle': loteDetalle.value,
        },
      );
    }
  }

  /// Obtiene el progreso del viaje (0.0 a 1.0)
  double get progresoViaje {
    if (loteDetalle.value == null) return 0.0;

    final estado = loteDetalle.value!.estado;

    switch (estado) {
      case 'Esperando iniciar':
        return 0.0;
      case 'En camino a la mina':
        return 0.15;
      case 'Esperando carguío':
        return 0.30;
      case 'En camino balanza cooperativa':
        return 0.45;
      case 'En camino balanza destino':
        return 0.60;
      case 'En camino almacén destino':
        return 0.75;
      case 'Descargando':
        return 0.90;
      case 'Completado':
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Obtiene el número del paso actual
  int get pasoActual {
    if (loteDetalle.value == null) return 0;

    final estado = loteDetalle.value!.estado;

    if (estado == 'Esperando iniciar') return 0;
    if (estado == 'En camino a la mina' || estado == 'Esperando carguío') {
      return 1;
    }
    if (estado == 'En camino balanza cooperativa') return 2;
    if (estado == 'En camino balanza destino') return 3;
    if (estado == 'En camino almacén destino' ||
        estado == 'Descargando' ||
        estado == 'Completado')
      return 4;

    return 0;
  }
}
