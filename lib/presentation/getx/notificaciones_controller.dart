// lib/presentation/getx/notificaciones_controller.dart

import 'package:get/get.dart';
import 'package:flutter/rendering.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/data/models/notificacion_model.dart';
import 'package:sumajflow_movil/data/repositories/notificaciones_repository.dart';

class NotificacionesController extends GetxController {
  final NotificacionesRepository _repository = NotificacionesRepository();
  final NotificationService _notificationService = NotificationService.to;

  // Estados observables
  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var notificaciones = <NotificacionModel>[].obs;
  var countNoLeidas = 0.obs;
  var filtroActual = 'todas'.obs;

  @override
  void onInit() {
    super.onInit();
    cargarNotificaciones();
    cargarContador();
  }

  /// Carga las notificaciones según el filtro actual
  Future<void> cargarNotificaciones() async {
    isLoading.value = true;
    try {
      debugPrint('🔄 Cargando notificaciones (filtro: ${filtroActual.value})');

      final soloNoLeidas = filtroActual.value == 'noLeidas';
      final result = await _repository.getNotificaciones(
        soloNoLeidas: soloNoLeidas,
      );

      notificaciones.value = result;
      debugPrint('✅ ${result.length} notificaciones cargadas');
    } catch (e) {
      debugPrint('❌ Error al cargar notificaciones: $e');
      _notificationService.showError(
        'Error',
        'No se pudieron cargar las notificaciones',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga el contador de notificaciones no leídas
  Future<void> cargarContador() async {
    try {
      final count = await _repository.contarNoLeidas();
      countNoLeidas.value = count;
    } catch (e) {
      debugPrint('❌ Error al cargar contador: $e');
    }
  }

  /// Refresca las notificaciones
  Future<void> refrescar() async {
    isRefreshing.value = true;
    try {
      await cargarNotificaciones();
      await cargarContador();
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Cambia el filtro de visualización
  Future<void> cambiarFiltro(String nuevoFiltro) async {
    if (filtroActual.value != nuevoFiltro) {
      filtroActual.value = nuevoFiltro;
      await cargarNotificaciones();
    }
  }

  /// Marca una notificación como leída
  Future<void> marcarComoLeida(int notificacionId) async {
    try {
      await _repository.marcarComoLeida(notificacionId);

      // Actualizar localmente
      final index = notificaciones.indexWhere((n) => n.id == notificacionId);
      if (index != -1) {
        notificaciones[index] = notificaciones[index].copyWith(leido: true);
        notificaciones.refresh();
      }

      // Actualizar contador
      await cargarContador();
    } catch (e) {
      debugPrint('❌ Error al marcar como leída: $e');
      _notificationService.showError(
        'Error',
        'No se pudo marcar la notificación como leída',
      );
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> marcarTodasComoLeidas() async {
    try {
      await _repository.marcarTodasComoLeidas();

      // Actualizar localmente
      notificaciones.value = notificaciones.map((n) {
        return n.copyWith(leido: true);
      }).toList();

      countNoLeidas.value = 0;

      _notificationService.showSuccess(
        'Éxito',
        'Todas las notificaciones marcadas como leídas',
      );
    } catch (e) {
      debugPrint('❌ Error al marcar todas como leídas: $e');
      _notificationService.showError(
        'Error',
        'No se pudieron marcar todas como leídas',
      );
    }
  }

  /// Elimina una notificación
  Future<void> eliminarNotificacion(int notificacionId) async {
    try {
      await _repository.eliminarNotificacion(notificacionId);

      // Actualizar localmente
      notificaciones.removeWhere((n) => n.id == notificacionId);

      // Actualizar contador
      await cargarContador();

      _notificationService.showSuccess('Éxito', 'Notificación eliminada');
    } catch (e) {
      debugPrint('❌ Error al eliminar notificación: $e');
      _notificationService.showError(
        'Error',
        'No se pudo eliminar la notificación',
      );
    }
  }

  /// Obtiene las notificaciones visibles según el filtro
  List<NotificacionModel> get notificacionesVisibles {
    return notificaciones;
  }

  /// Verifica si hay notificaciones no leídas
  bool get hayNoLeidas => countNoLeidas.value > 0;
}
