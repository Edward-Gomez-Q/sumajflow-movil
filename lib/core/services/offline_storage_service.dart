// lib/core/services/offline_storage_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';

/// Servicio para almacenamiento local de datos offline
class OfflineStorageService extends GetxService {
  static OfflineStorageService get to => Get.find();

  static const String _keyPendingLocations = 'pending_locations_';
  static const String _keyTrackingState = 'tracking_state_';
  static const String _keyLastSync = 'last_sync_';

  late SharedPreferences _prefs;

  // Estado observable
  final RxInt pendingLocationsCount = 0.obs;
  final RxBool hasPendingData = false.obs;

  Future<OfflineStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _updatePendingCount();
    return this;
  }

  // ==================== UBICACIONES PENDIENTES ====================

  /// Guarda una ubicación para sincronizar después
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

      await _updatePendingCount();
      debugPrint(
        '💾 Ubicación guardada offline - Total pendientes: ${existing.length}',
      );
    } catch (e) {
      debugPrint('❌ Error al guardar ubicación offline: $e');
    }
  }

  /// Obtiene las ubicaciones pendientes de una asignación
  Future<List<UbicacionOfflineModel>> getPendingLocations(
    int asignacionId,
  ) async {
    try {
      final key = '$_keyPendingLocations$asignacionId';
      final jsonString = _prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => UbicacionOfflineModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener ubicaciones pendientes: $e');
      return [];
    }
  }

  /// Obtiene todas las asignaciones con ubicaciones pendientes
  Future<Map<int, List<UbicacionOfflineModel>>> getAllPendingLocations() async {
    final Map<int, List<UbicacionOfflineModel>> result = {};

    try {
      final keys = _prefs.getKeys().where(
        (k) => k.startsWith(_keyPendingLocations),
      );

      for (final key in keys) {
        final asignacionIdStr = key.replaceFirst(_keyPendingLocations, '');
        final asignacionId = int.tryParse(asignacionIdStr);

        if (asignacionId != null) {
          final locations = await getPendingLocations(asignacionId);
          if (locations.isNotEmpty) {
            result[asignacionId] = locations;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error al obtener todas las ubicaciones pendientes: $e');
    }

    return result;
  }

  /// Marca ubicaciones como sincronizadas
  Future<void> markLocationsSynced(int asignacionId, int count) async {
    try {
      final locations = await getPendingLocations(asignacionId);

      if (count >= locations.length) {
        // Eliminar todas
        await clearPendingLocations(asignacionId);
      } else {
        // Eliminar solo las sincronizadas (las primeras 'count')
        final remaining = locations.sublist(count);
        final key = '$_keyPendingLocations$asignacionId';
        final jsonList = remaining.map((u) => u.toJson()).toList();
        await _prefs.setString(key, jsonEncode(jsonList));
      }

      await _updatePendingCount();
      debugPrint('  $count ubicaciones marcadas como sincronizadas');
    } catch (e) {
      debugPrint('❌ Error al marcar ubicaciones sincronizadas: $e');
    }
  }

  /// Limpia las ubicaciones pendientes de una asignación
  Future<void> clearPendingLocations(int asignacionId) async {
    try {
      final key = '$_keyPendingLocations$asignacionId';
      await _prefs.remove(key);
      await _updatePendingCount();
      debugPrint(
        '🗑️ Ubicaciones pendientes eliminadas para asignación $asignacionId',
      );
    } catch (e) {
      debugPrint('❌ Error al limpiar ubicaciones pendientes: $e');
    }
  }

  // ==================== ESTADO DEL TRACKING ====================

  /// Guarda el estado del tracking para recuperar después
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

  /// Obtiene el estado guardado del tracking
  Future<Map<String, dynamic>?> getTrackingState(int asignacionId) async {
    try {
      final key = '$_keyTrackingState$asignacionId';
      final jsonString = _prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('❌ Error al obtener estado de tracking: $e');
      return null;
    }
  }

  /// Limpia el estado de tracking
  Future<void> clearTrackingState(int asignacionId) async {
    try {
      final key = '$_keyTrackingState$asignacionId';
      await _prefs.remove(key);
    } catch (e) {
      debugPrint('❌ Error al limpiar estado de tracking: $e');
    }
  }

  // ==================== SINCRONIZACIÓN ====================

  /// Guarda la última fecha de sincronización
  Future<void> saveLastSyncTime(int asignacionId) async {
    try {
      final key = '$_keyLastSync$asignacionId';
      await _prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error al guardar última sincronización: $e');
    }
  }

  /// Obtiene la última fecha de sincronización
  Future<DateTime?> getLastSyncTime(int asignacionId) async {
    try {
      final key = '$_keyLastSync$asignacionId';
      final dateStr = _prefs.getString(key);

      if (dateStr == null || dateStr.isEmpty) {
        return null;
      }

      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('❌ Error al obtener última sincronización: $e');
      return null;
    }
  }

  // ==================== UTILIDADES ====================

  /// Actualiza el contador de ubicaciones pendientes
  Future<void> _updatePendingCount() async {
    int count = 0;

    final keys = _prefs.getKeys().where(
      (k) => k.startsWith(_keyPendingLocations),
    );

    for (final key in keys) {
      final jsonString = _prefs.getString(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(jsonString);
          count += list.length;
        } catch (_) {}
      }
    }

    pendingLocationsCount.value = count;
    hasPendingData.value = count > 0;
  }

  /// Obtiene el total de ubicaciones pendientes
  int get totalPendingLocations => pendingLocationsCount.value;

  /// Limpia todos los datos offline
  Future<void> clearAllOfflineData() async {
    try {
      final keys = _prefs.getKeys().where(
        (k) =>
            k.startsWith(_keyPendingLocations) ||
            k.startsWith(_keyTrackingState) ||
            k.startsWith(_keyLastSync),
      );

      for (final key in keys) {
        await _prefs.remove(key);
      }

      await _updatePendingCount();
      debugPrint('🗑️ Todos los datos offline eliminados');
    } catch (e) {
      debugPrint('❌ Error al limpiar datos offline: $e');
    }
  }
}
