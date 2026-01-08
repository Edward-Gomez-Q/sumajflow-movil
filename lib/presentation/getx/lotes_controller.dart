// lib/presentation/getx/lotes_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/data/repositories/tracking_repository.dart';

class LotesController extends GetxController {
  final TrackingRepository _repository = TrackingRepository();
  final NotificationService _notification = NotificationService.to;

  // Estados
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString filtroActual = 'activos'.obs;
  final RxString errorMessage = ''.obs;

  // Datos
  final RxList<LoteAsignadoModel> lotes = <LoteAsignadoModel>[].obs;
  final RxList<LoteAsignadoModel> lotesActivos = <LoteAsignadoModel>[].obs;
  final RxList<LoteAsignadoModel> lotesCompletados = <LoteAsignadoModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    cargarLotes();
  }

  /// Carga los lotes asignados al transportista
  Future<void> cargarLotes({bool showLoading = true}) async {
    if (showLoading) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      // Cargar activos
      final activos = await _repository.getMisLotes(filtro: 'activos');
      lotesActivos.assignAll(activos);

      // Cargar completados
      final completados = await _repository.getMisLotes(filtro: 'completados');
      lotesCompletados.assignAll(completados);

      // Actualizar lista según filtro actual
      _actualizarListaFiltrada();

      debugPrint(
        '✅ Lotes cargados - Activos: ${activos.length}, Completados: ${completados.length}',
      );
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _notification.showError('Error', errorMessage.value);
      debugPrint('❌ Error al cargar lotes: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Refresca los lotes (pull to refresh)
  Future<void> refrescarLotes() async {
    isRefreshing.value = true;
    await cargarLotes(showLoading: false);
  }

  /// Cambia el filtro de visualización
  void cambiarFiltro(String filtro) {
    filtroActual.value = filtro;
    _actualizarListaFiltrada();
  }

  void _actualizarListaFiltrada() {
    switch (filtroActual.value) {
      case 'activos':
        lotes.assignAll(lotesActivos);
        break;
      case 'completados':
        lotes.assignAll(lotesCompletados);
        break;
      default:
        lotes.assignAll([...lotesActivos, ...lotesCompletados]);
    }
  }

  /// Obtiene el conteo de lotes activos
  int get cantidadActivos => lotesActivos.length;

  /// Obtiene el conteo de lotes completados
  int get cantidadCompletados => lotesCompletados.length;

  /// Verifica si hay lotes pendientes de iniciar
  bool get hayLotesPendientes =>
      lotesActivos.any((l) => l.estaPendienteIniciar);

  /// Obtiene los lotes pendientes de iniciar
  List<LoteAsignadoModel> get lotesPendientes =>
      lotesActivos.where((l) => l.estaPendienteIniciar).toList();

  /// Obtiene los lotes en curso
  List<LoteAsignadoModel> get lotesEnCurso =>
      lotesActivos.where((l) => l.estaEnCurso).toList();
}
