// lib/data/repositories/lotes_repository.dart
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';

class LotesRepository {
  late final Dio _dio;

  LotesRepository() {
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
          debugPrint('🔵 Headers: ${options.headers}');
          debugPrint('🔵 Query Params: ${options.queryParameters}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('  Response [${response.statusCode}]: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Error en lotes repository: ${error.message}');
          debugPrint('❌ Response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== LOTES ASIGNADOS ====================

  /// Obtiene los lotes asignados al transportista
  /// Filtros: 'activos', 'completados', 'todos'
  Future<List<LoteAsignadoModel>> getMisLotes({
    String filtro = 'activos',
  }) async {
    try {
      debugPrint('📋 Obteniendo lotes con filtro: $filtro');

      final response = await _dio.get(
        '/transportista/lotes',
        queryParameters: {'filtro': filtro},
      );

      debugPrint('📊 Response status: ${response.statusCode}');
      debugPrint('📊 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];

        debugPrint('  Se obtuvieron ${data.length} lotes');

        return data.map((e) => LoteAsignadoModel.fromJson(e)).toList();
      }

      throw Exception(response.data['message'] ?? 'Error al obtener lotes');
    } on DioException catch (e) {
      debugPrint('❌ DioException en getMisLotes: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en getMisLotes: $e');
      rethrow;
    }
  }

  /// Obtiene el detalle de un lote
  Future<LoteDetalleViajeModel> getDetalleLote(int asignacionId) async {
    try {
      debugPrint(
        '📋 Obteniendo detalle del lote con asignacionId: $asignacionId',
      );

      final response = await _dio.get('/transportista/lotes/$asignacionId');

      debugPrint('📊 Response status: ${response.statusCode}');
      debugPrint('📊 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('  Detalle del lote obtenido exitosamente');
        return LoteDetalleViajeModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Error al obtener detalle');
    } on DioException catch (e) {
      debugPrint('❌ DioException en getDetalleLote: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en getDetalleLote: $e');
      rethrow;
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
