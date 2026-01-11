// lib/data/repositories/tracking_repository.dart

import 'package:dio/dio.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:flutter/rendering.dart';

class TrackingRepository {
  late final Dio _dio;

  TrackingRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthService.to.authToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('❌ Error en tracking repository: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== TRACKING ====================

  /// Inicia el tracking de un viaje
  Future<TrackingModel> iniciarTracking({
    required int asignacionCamionId,
    double? latInicial,
    double? lngInicial,
  }) async {
    try {
      final response = await _dio.post(
        '/tracking/iniciar',
        data: {
          'asignacionCamionId': asignacionCamionId,
          'latInicial': latInicial,
          'lngInicial': lngInicial,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return TrackingModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Error al iniciar tracking');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Actualiza la ubicación actual
  Future<ActualizacionUbicacionResponse> actualizarUbicacion({
    required int asignacionCamionId,
    required double lat,
    required double lng,
    double? precision,
    double? velocidad,
    double? rumbo,
    double? altitud,
    DateTime? timestampCaptura,
    bool esOffline = false,
  }) async {
    try {
      final response = await _dio.post(
        '/tracking/ubicacion',
        data: {
          'asignacionCamionId': asignacionCamionId,
          'lat': lat,
          'lng': lng,
          'precision': precision,
          'velocidad': velocidad,
          'rumbo': rumbo,
          'altitud': altitud,
          'timestampCaptura': timestampCaptura?.toIso8601String(),
          'esOffline': esOffline,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ActualizacionUbicacionResponse.fromJson(response.data['data']);
      }

      throw Exception(
        response.data['message'] ?? 'Error al actualizar ubicación',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Obtiene el tracking actual de una asignación
  Future<TrackingModel> getTracking(int asignacionCamionId) async {
    try {
      final response = await _dio.get(
        '/tracking/asignacion/$asignacionCamionId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TrackingModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Error al obtener tracking');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== PUNTOS DE CONTROL ====================

  /// Registra llegada a un punto de control
  Future<TrackingModel> registrarLlegada({
    required int asignacionCamionId,
    required String tipoPunto,
    double? lat,
    double? lng,
    String? observaciones,
  }) async {
    try {
      final response = await _dio.post(
        '/tracking/punto-control/llegada',
        data: {
          'asignacionCamionId': asignacionCamionId,
          'tipoPunto': tipoPunto,
          'accion': 'llegada',
          'lat': lat,
          'lng': lng,
          'observaciones': observaciones,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TrackingModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Error al registrar llegada');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Registra salida de un punto de control
  Future<TrackingModel> registrarSalida({
    required int asignacionCamionId,
    required String tipoPunto,
    String? observaciones,
  }) async {
    try {
      final response = await _dio.post(
        '/tracking/punto-control/salida',
        data: {
          'asignacionCamionId': asignacionCamionId,
          'tipoPunto': tipoPunto,
          'accion': 'salida',
          'observaciones': observaciones,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TrackingModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Error al registrar salida');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== SINCRONIZACIÓN OFFLINE ====================

  /// Sincroniza ubicaciones capturadas offline
  Future<Map<String, dynamic>> sincronizarUbicaciones({
    required int asignacionCamionId,
    required List<UbicacionOfflineModel> ubicaciones,
  }) async {
    try {
      final response = await _dio.post(
        '/tracking/sincronizar',
        data: {
          'asignacionCamionId': asignacionCamionId,
          'ubicaciones': ubicaciones.map((u) => u.toJson()).toList(),
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }

      throw Exception(response.data['message'] ?? 'Error al sincronizar');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== UTILIDADES ====================

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final message = e.response!.data['message'] ?? 'Error del servidor';
      return Exception(message);
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Tiempo de conexión agotado');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de respuesta agotado');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Sin conexión a internet');
    }
    return Exception('Error de conexión: ${e.message}');
  }
}
