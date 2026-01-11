// lib/data/repositories/viaje_repository.dart

import 'package:dio/dio.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/data/models/viaje_models.dart';

class ViajeRepository {
  late final Dio _dio;

  ViajeRepository() {
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
          print('🔵 Request: ${options.method} ${options.path}');
          print('🔵 Body: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('  Response [${response.statusCode}]: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Error en viaje repository: ${error.message}');
          print('❌ Response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Inicia el viaje: "Esperando iniciar" → "En camino a la mina"
  Future<TransicionEstadoResponse> iniciarViaje({
    required int asignacionId,
    required double lat,
    required double lng,
    String? observaciones,
  }) async {
    try {
      print('📋 Iniciando viaje - AsignacionId: $asignacionId');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/iniciar',
        data: {
          'lat': lat,
          'lng': lng,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('  Viaje iniciado exitosamente');
        return TransicionEstadoResponse.fromJson(response.data);
      }

      throw Exception(response.data['message'] ?? 'Error al iniciar viaje');
    } on DioException catch (e) {
      print('❌ DioException en iniciarViaje: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Exception en iniciarViaje: $e');
      rethrow;
    }
  }

  /// Manejo de errores de Dio
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
