// lib/presentation/getx/dashboard_controller.dart

import 'package:get/get.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:sumajflow_movil/data/repositories/lotes_repository.dart';
import 'package:flutter/rendering.dart';

class DashboardController extends GetxController {
  final LotesRepository _lotesRepository = LotesRepository();
  final NotificationService _notificationService = NotificationService.to;

  // Estados observables
  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var filtroActual = 'activos'.obs;

  // Listas de lotes
  var lotesActivos = <LoteAsignadoModel>[].obs;
  var todosLosLotes = <LoteAsignadoModel>[].obs;

  // Estadísticas
  var totalEnTransito = 0.obs;
  var totalCompletados = 0.obs;

  @override
  void onInit() {
    super.onInit();
    cargarLotesIniciales();
  }

  /// Carga inicial de lotes
  Future<void> cargarLotesIniciales() async {
    isLoading.value = true;
    try {
      await cargarLotesPorFiltro('activos');
      await calcularEstadisticas();
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga lotes según el filtro seleccionado
  Future<void> cargarLotesPorFiltro(String filtro) async {
    try {
      debugPrint('🔄 Cargando lotes con filtro: $filtro');

      filtroActual.value = filtro;

      final lotes = await _lotesRepository.getMisLotes(filtro: filtro);

      debugPrint('  Lotes cargados: ${lotes.length}');

      if (filtro == 'activos') {
        lotesActivos.value = lotes;
      } else {
        todosLosLotes.value = lotes;
      }

      // Siempre actualizar estadísticas
      await calcularEstadisticas();
    } catch (e) {
      debugPrint('❌ Error al cargar lotes: $e');
      _notificationService.showError(
        'Error',
        'No se pudieron cargar los lotes: ${e.toString()}',
      );
    }
  }

  /// Refresca los datos
  Future<void> refrescar() async {
    isRefreshing.value = true;
    try {
      await cargarLotesPorFiltro(filtroActual.value);
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Calcula las estadísticas del dashboard
  Future<void> calcularEstadisticas() async {
    try {
      // Obtener todos los lotes para estadísticas
      final todosLotes = await _lotesRepository.getMisLotes(filtro: 'todos');

      // Contar en tránsito (activos pero no pendientes ni completados)
      totalEnTransito.value = todosLotes.where((lote) {
        return lote.estaEnCurso;
      }).length;

      // Contar completados
      totalCompletados.value = todosLotes.where((lote) {
        return lote.estaCompletado;
      }).length;

      debugPrint('📊 Estadísticas actualizadas:');
      debugPrint('   En tránsito: ${totalEnTransito.value}');
      debugPrint('   Completados: ${totalCompletados.value}');
    } catch (e) {
      debugPrint('❌ Error al calcular estadísticas: $e');
      // No mostramos error al usuario, solo log
    }
  }

  /// Cambia el filtro de visualización
  void cambiarFiltro(String nuevoFiltro) {
    if (filtroActual.value != nuevoFiltro) {
      cargarLotesPorFiltro(nuevoFiltro);
    }
  }

  /// Obtiene la lista actualmente visible según el filtro
  List<LoteAsignadoModel> get lotesVisibles {
    switch (filtroActual.value) {
      case 'activos':
        return lotesActivos;
      case 'completados':
      case 'todos':
        return todosLosLotes;
      default:
        return lotesActivos;
    }
  }

  /// Obtiene solo los primeros N lotes para el dashboard
  List<LoteAsignadoModel> get lotesParaDashboard {
    return lotesActivos.take(3).toList();
  }
}
