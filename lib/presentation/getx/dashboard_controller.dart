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
  var lotesCompletados = <LoteAsignadoModel>[].obs;
  var todosLosLotes = <LoteAsignadoModel>[].obs;

  // Estadísticas
  var totalEnTransito = 0.obs;
  var totalCompletados = 0.obs;
  var totalDistanciaKm = 0.0.obs;
  var totalHorasViaje = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    cargarLotesIniciales();
  }

  /// Carga inicial de lotes
  Future<void> cargarLotesIniciales() async {
    isLoading.value = true;
    try {
      await cargarTodosLosLotes();
      await calcularEstadisticas();
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga TODOS los lotes y los separa por estado
  Future<void> cargarTodosLosLotes() async {
    try {
      debugPrint('🔄 Cargando TODOS los lotes');

      final lotes = await _lotesRepository.getMisLotes(filtro: 'todos');

      debugPrint('✅ Lotes cargados: ${lotes.length}');

      // Separar por estado
      todosLosLotes.value = lotes;
      lotesActivos.value = lotes.where((lote) => lote.estaActivo).toList();
      lotesCompletados.value = lotes
          .where((lote) => lote.estaCompletado)
          .toList();

      debugPrint('   Activos: ${lotesActivos.length}');
      debugPrint('   Completados: ${lotesCompletados.length}');
    } catch (e) {
      debugPrint('❌ Error al cargar lotes: $e');
      _notificationService.showError(
        'Error',
        'No se pudieron cargar los lotes: ${e.toString()}',
      );
    }
  }

  /// Carga lotes según el filtro seleccionado
  Future<void> cargarLotesPorFiltro(String filtro) async {
    try {
      debugPrint('🔄 Cambiando filtro a: $filtro');
      filtroActual.value = filtro;

      // Si ya tenemos todos los lotes cargados, solo cambiamos la vista
      // Si no, recargamos todo
      if (todosLosLotes.isEmpty) {
        await cargarTodosLosLotes();
      }
    } catch (e) {
      debugPrint('❌ Error al cambiar filtro: $e');
    }
  }

  /// Refresca los datos
  Future<void> refrescar() async {
    isRefreshing.value = true;
    try {
      await cargarTodosLosLotes();
      await calcularEstadisticas();
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Calcula las estadísticas del dashboard
  Future<void> calcularEstadisticas() async {
    try {
      // Contar en tránsito
      totalEnTransito.value = lotesActivos.where((lote) {
        return lote.estaEnCurso;
      }).length;

      // Contar completados
      totalCompletados.value = lotesCompletados.length;

      // Datos de ejemplo (reemplazar con datos reales cuando estén disponibles)
      totalDistanciaKm.value = lotesCompletados.length * 45.5;
      totalHorasViaje.value = lotesCompletados.length * 2.3;

      debugPrint('📊 Estadísticas actualizadas:');
      debugPrint('   En tránsito: ${totalEnTransito.value}');
      debugPrint('   Completados: ${totalCompletados.value}');
      debugPrint('   Distancia total: ${totalDistanciaKm.value} km');
      debugPrint('   Tiempo total: ${totalHorasViaje.value} hrs');
    } catch (e) {
      debugPrint('❌ Error al calcular estadísticas: $e');
    }
  }

  /// Cambia el filtro de visualización
  void cambiarFiltro(String nuevoFiltro) {
    if (filtroActual.value != nuevoFiltro) {
      filtroActual.value = nuevoFiltro;
    }
  }

  /// Obtiene la lista actualmente visible según el filtro
  List<LoteAsignadoModel> get lotesVisibles {
    switch (filtroActual.value) {
      case 'activos':
        return lotesActivos;
      case 'completados':
        return lotesCompletados;
      case 'todos':
        return todosLosLotes;
      default:
        return lotesActivos;
    }
  }

  /// Obtiene el lote activo actual (solo uno)
  LoteAsignadoModel? get loteActivo {
    // Priorizar lotes en curso, luego pendientes
    final enCurso = lotesActivos.where((l) => l.estaEnCurso).toList();
    if (enCurso.isNotEmpty) return enCurso.first;

    final pendientes = lotesActivos
        .where((l) => l.estaPendienteIniciar)
        .toList();
    if (pendientes.isNotEmpty) return pendientes.first;

    return null;
  }
}
