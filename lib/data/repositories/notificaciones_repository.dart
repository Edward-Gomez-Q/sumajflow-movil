// lib/data/repositories/notificaciones_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/data/models/notificacion_model.dart';

class NotificacionesRepository {
  late final Dio _dio;

  NotificacionesRepository() {
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
          debugPrint('🔵 Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ Response [${response.statusCode}]');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Obtener todas las notificaciones del usuario
  Future<List<NotificacionModel>> getNotificaciones({
    bool? soloNoLeidas,
  }) async {
    try {
      debugPrint('📋 Obteniendo notificaciones (soloNoLeidas: $soloNoLeidas)');

      final queryParams = <String, dynamic>{};
      if (soloNoLeidas != null) {
        queryParams['soloNoLeidas'] = soloNoLeidas;
      }

      final response = await _dio.get(
        '/notificaciones',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        debugPrint('✅ ${data.length} notificaciones obtenidas');

        return data.map((json) => NotificacionModel.fromJson(json)).toList();
      }

      throw Exception(
        response.data['message'] ?? 'Error al obtener notificaciones',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Contar notificaciones no leídas
  Future<int> contarNoLeidas() async {
    try {
      debugPrint('🔢 Contando notificaciones no leídas');

      final response = await _dio.get('/notificaciones/no-leidas/count');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final count = response.data['count'] as int;
        debugPrint('✅ $count notificaciones no leídas');
        return count;
      }

      throw Exception(
        response.data['message'] ?? 'Error al contar notificaciones',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Marcar una notificación específica como leída
  Future<void> marcarComoLeida(int notificacionId) async {
    try {
      debugPrint('✔️ Marcando notificación $notificacionId como leída');

      final response = await _dio.put('/notificaciones/$notificacionId/leer');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Error al marcar como leída',
        );
      }

      debugPrint('✅ Notificación marcada como leída');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> marcarTodasComoLeidas() async {
    try {
      debugPrint('✔️ Marcando todas las notificaciones como leídas');

      final response = await _dio.put('/notificaciones/leer-todas');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Error al marcar todas como leídas',
        );
      }

      debugPrint('✅ Todas las notificaciones marcadas como leídas');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Eliminar una notificación específica
  Future<void> eliminarNotificacion(int notificacionId) async {
    try {
      debugPrint('🗑️ Eliminando notificación $notificacionId');

      final response = await _dio.delete('/notificaciones/$notificacionId');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Error al eliminar notificación',
        );
      }

      debugPrint('✅ Notificación eliminada');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

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
