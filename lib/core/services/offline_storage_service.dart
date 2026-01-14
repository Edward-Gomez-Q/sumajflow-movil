// lib/core/services/offline_storage_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/data/models/accion_offline_model.dart';

class OfflineStorageService extends GetxService {
  static OfflineStorageService get to => Get.find();

  static const String _keyPendingLocations = 'pending_locations_';
  static const String _keyTrackingState = 'tracking_state_';
  static const String _keyLastSync = 'last_sync_';
  static const String _keyPendingActions = 'pending_actions'; // NUEVO
  static const String _keyEstadoViaje = 'estado_viaje_'; // NUEVO

  late SharedPreferences _prefs;

  final RxInt pendingLocationsCount = 0.obs;
  final RxInt pendingActionsCount = 0.obs; // NUEVO
  final RxBool hasPendingData = false.obs;

  Future<OfflineStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _updatePendingCounts();
    return this;
  }

  // ==================== UBICACIONES PENDIENTES ====================

  Future<void> saveLocationOffline(
    int asignacionId,
    UbicacionOfflineModel ubicacion,
  ) async {
    try {
      final key = '$_keyPendingLocations$asignacionId';
      final existing = await getPendingLocations(asignacionId);
      existing.add(ubicacion);

      final jsonList = existing.map((u) => u.toJson()).toList();
      await _prefs.setString(key, jsonEncode(jsonList));

      await _updatePendingCounts();
      debugPrint(
        '💾 Ubicación guardada offline - Total pendientes: ${existing.length}',
      );
    } catch (e) {
      debugPrint('❌ Error al guardar ubicación offline: $e');
    }
  }

  Future<List<UbicacionOfflineModel>> getPendingLocations(
    int asignacionId,
  ) async {
    try {
      final key = '$_keyPendingLocations$asignacionId';
      final jsonString = _prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => UbicacionOfflineModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener ubicaciones pendientes: $e');
      return [];
    }
  }

  Future<void> markLocationsSynced(int asignacionId, int count) async {
    try {
      final locations = await getPendingLocations(asignacionId);

      if (count >= locations.length) {
        await clearPendingLocations(asignacionId);
      } else {
        final remaining = locations.sublist(count);
        final key = '$_keyPendingLocations$asignacionId';
        final jsonList = remaining.map((u) => u.toJson()).toList();
        await _prefs.setString(key, jsonEncode(jsonList));
      }

      await _updatePendingCounts();
      debugPrint('✅ $count ubicaciones marcadas como sincronizadas');
    } catch (e) {
      debugPrint('❌ Error al marcar ubicaciones sincronizadas: $e');
    }
  }

  Future<void> clearPendingLocations(int asignacionId) async {
    try {
      final key = '$_keyPendingLocations$asignacionId';
      await _prefs.remove(key);
      await _updatePendingCounts();
      debugPrint(
        '🗑️ Ubicaciones pendientes eliminadas para asignación $asignacionId',
      );
    } catch (e) {
      debugPrint('❌ Error al limpiar ubicaciones pendientes: $e');
    }
  }

  // ==================== ACCIONES OFFLINE (NUEVO) ====================

  Future<void> saveAccionOffline(AccionOfflineModel accion) async {
    try {
      final existing = await getPendingAcciones();
      existing.add(accion);

      final jsonList = existing.map((a) => a.toJson()).toList();
      await _prefs.setString(_keyPendingActions, jsonEncode(jsonList));

      await _updatePendingCounts();
      debugPrint(
        '💾 Acción guardada offline: ${accion.tipo} (Total: ${existing.length})',
      );
    } catch (e) {
      debugPrint('❌ Error al guardar acción offline: $e');
    }
  }

  Future<List<AccionOfflineModel>> getPendingAcciones() async {
    try {
      final jsonString = _prefs.getString(_keyPendingActions);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => AccionOfflineModel.fromJson(json))
          .where((a) => !a.sincronizado)
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener acciones pendientes: $e');
      return [];
    }
  }

  Future<void> updateAccionOffline(AccionOfflineModel accion) async {
    try {
      final existing = await _getAllAcciones();
      final index = existing.indexWhere((a) => a.id == accion.id);

      if (index != -1) {
        existing[index] = accion;
        final jsonList = existing.map((a) => a.toJson()).toList();
        await _prefs.setString(_keyPendingActions, jsonEncode(jsonList));
        await _updatePendingCounts();
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar acción offline: $e');
    }
  }

  Future<List<AccionOfflineModel>> _getAllAcciones() async {
    try {
      final jsonString = _prefs.getString(_keyPendingActions);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => AccionOfflineModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markAccionesSynced(List<String> accionIds) async {
    try {
      final existing = await _getAllAcciones();
      final remaining = existing
          .where((a) => !accionIds.contains(a.id))
          .toList();

      if (remaining.isEmpty) {
        await _prefs.remove(_keyPendingActions);
      } else {
        final jsonList = remaining.map((a) => a.toJson()).toList();
        await _prefs.setString(_keyPendingActions, jsonEncode(jsonList));
      }

      await _updatePendingCounts();
      debugPrint('✅ ${accionIds.length} acciones marcadas como sincronizadas');
    } catch (e) {
      debugPrint('❌ Error al marcar acciones como sincronizadas: $e');
    }
  }

  Future<void> clearAllPendingActions() async {
    try {
      await _prefs.remove(_keyPendingActions);
      await _updatePendingCounts();
      debugPrint('🗑️ Todas las acciones pendientes eliminadas');
    } catch (e) {
      debugPrint('❌ Error al limpiar acciones pendientes: $e');
    }
  }

  // ==================== ESTADO DEL VIAJE (NUEVO) ====================

  Future<void> saveEstadoViajeOffline(int asignacionId, String estado) async {
    try {
      final key = '$_keyEstadoViaje$asignacionId';
      await _prefs.setString(key, estado);
      debugPrint('💾 Estado viaje guardado offline: $estado');
    } catch (e) {
      debugPrint('❌ Error al guardar estado offline: $e');
    }
  }

  String? getEstadoViajeOffline(int asignacionId) {
    try {
      final key = '$_keyEstadoViaje$asignacionId';
      return _prefs.getString(key);
    } catch (e) {
      debugPrint('❌ Error al obtener estado offline: $e');
      return null;
    }
  }

  Future<void> clearEstadoViajeOffline(int asignacionId) async {
    try {
      final key = '$_keyEstadoViaje$asignacionId';
      await _prefs.remove(key);
    } catch (e) {
      debugPrint('❌ Error al limpiar estado offline: $e');
    }
  }

  // ==================== UTILIDADES ====================

  Future<void> _updatePendingCounts() async {
    int locationsCount = 0;
    int actionsCount = 0;

    // Contar ubicaciones
    final locationKeys = _prefs.getKeys().where(
      (k) => k.startsWith(_keyPendingLocations),
    );
    for (final key in locationKeys) {
      final jsonString = _prefs.getString(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(jsonString);
          locationsCount += list.length;
        } catch (_) {}
      }
    }

    // Contar acciones
    final acciones = await getPendingAcciones();
    actionsCount = acciones.length;

    pendingLocationsCount.value = locationsCount;
    pendingActionsCount.value = actionsCount;
    hasPendingData.value = (locationsCount + actionsCount) > 0;

    debugPrint(
      '📊 Datos pendientes - Ubicaciones: $locationsCount, Acciones: $actionsCount',
    );
  }

  int get totalPendingLocations => pendingLocationsCount.value;
  int get totalPendingActions => pendingActionsCount.value;

  Future<void> clearAllOfflineData() async {
    try {
      final keys = _prefs.getKeys().where(
        (k) =>
            k.startsWith(_keyPendingLocations) ||
            k.startsWith(_keyTrackingState) ||
            k.startsWith(_keyLastSync) ||
            k.startsWith(_keyEstadoViaje) ||
            k == _keyPendingActions,
      );

      for (final key in keys) {
        await _prefs.remove(key);
      }

      await _updatePendingCounts();
      debugPrint('🗑️ Todos los datos offline eliminados');
    } catch (e) {
      debugPrint('❌ Error al limpiar datos offline: $e');
    }
  }

  // ==================== TRACKING STATE (sin cambios) ====================

  Future<void> saveTrackingState(
    int asignacionId,
    Map<String, dynamic> state,
  ) async {
    try {
      final key = '$_keyTrackingState$asignacionId';
      await _prefs.setString(key, jsonEncode(state));
      debugPrint('💾 Estado de tracking guardado');
    } catch (e) {
      debugPrint('❌ Error al guardar estado de tracking: $e');
    }
  }

  Future<Map<String, dynamic>?> getTrackingState(int asignacionId) async {
    try {
      final key = '$_keyTrackingState$asignacionId';
      final jsonString = _prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) return null;
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('❌ Error al obtener estado de tracking: $e');
      return null;
    }
  }

  Future<void> clearTrackingState(int asignacionId) async {
    try {
      final key = '$_keyTrackingState$asignacionId';
      await _prefs.remove(key);
    } catch (e) {
      debugPrint('❌ Error al limpiar estado de tracking: $e');
    }
  }

  Future<void> saveLastSyncTime(int asignacionId) async {
    try {
      final key = '$_keyLastSync$asignacionId';
      await _prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error al guardar última sincronización: $e');
    }
  }

  Future<DateTime?> getLastSyncTime(int asignacionId) async {
    try {
      final key = '$_keyLastSync$asignacionId';
      final dateStr = _prefs.getString(key);
      if (dateStr == null || dateStr.isEmpty) return null;
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('❌ Error al obtener última sincronización: $e');
      return null;
    }
  }
}
