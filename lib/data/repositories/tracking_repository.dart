// lib/data/repositories/tracking_repository.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/exceptions/network_exception.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:flutter/foundation.dart';

class TrackingRepository {
  late final Dio _dio;

  TrackingRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) {
          return status != null && status < 500;
        },
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
          // Solo loguear errores no esperados
          if (error.type != DioExceptionType.connectionTimeout &&
              error.type != DioExceptionType.receiveTimeout &&
              error.type != DioExceptionType.connectionError &&
              error.type != DioExceptionType.sendTimeout) {
            debugPrint('❌ TrackingRepository Error: ${error.type}');
          }

          // IMPORTANTE: Usar reject para que el error se propague correctamente
          return handler.reject(error);
        },
      ),
    );
  }

  /// Actualiza la ubicación del camión
  Future<ActualizacionUbicacionResponse> actualizarUbicacion({
    required int asignacionCamionId,
    required double lat,
    required double lng,
    double? precision,
    double? velocidad,
    double? rumbo,
    double? altitud,
    DateTime? timestampCaptura,
  }) async {
    try {
      final response = await _dio.post(
        '/tracking/ubicacion',
        data: {
          'asignacionCamionId': asignacionCamionId,
          'lat': lat,
          'lng': lng,
          if (precision != null) 'precision': precision,
          if (velocidad != null) 'velocidad': velocidad,
          if (rumbo != null) 'rumbo': rumbo,
          if (altitud != null) 'altitud': altitud,
          'timestampCaptura': (timestampCaptura ?? DateTime.now())
              .toIso8601String(),
          'esOffline': false,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ActualizacionUbicacionResponse(
          success: true,
          mensaje: 'Ubicación actualizada',
        );
      }

      throw NetworkException(
        response.data['message'] ?? 'Error al actualizar ubicación',
        type: NetworkExceptionType.serverError,
      );
    } on DioException catch (e) {
      // Convertir DioException a NetworkException
      throw _handleDioError(e);
    } catch (e) {
      // Cualquier otra excepción se convierte a NetworkException
      if (e is NetworkException) rethrow;
      throw NetworkException(
        'Error inesperado al actualizar ubicación',
        type: NetworkExceptionType.unknown,
      );
    }
  }

  /// Sincroniza ubicaciones guardadas offline
  Future<SincronizacionResponse> sincronizarUbicaciones({
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
        final data = response.data['data'] ?? {};
        return SincronizacionResponse(
          success: response.data['success'] ?? false,
          ubicacionesSincronizadas: data['ubicacionesSincronizadas'] ?? 0,
          ubicacionesFallidas: data['ubicacionesFallidas'] ?? 0,
        );
      }

      throw NetworkException(
        'Error al sincronizar ubicaciones',
        type: NetworkExceptionType.serverError,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException(
        'Error inesperado al sincronizar',
        type: NetworkExceptionType.unknown,
      );
    }
  }

  NetworkException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Sin conexión al servidor',
          type: NetworkExceptionType.timeout,
        );

      case DioExceptionType.connectionError:
        // Verificar si es específicamente un error de red
        if (e.error is SocketException) {
          return NetworkException(
            'Sin conexión a internet',
            type: NetworkExceptionType.noConnection,
          );
        }
        return NetworkException(
          'Error de conexión',
          type: NetworkExceptionType.noConnection,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
          return NetworkException(
            'Error del servidor',
            type: NetworkExceptionType.serverError,
          );
        }
        return NetworkException(
          e.response?.data?['message'] ?? 'Error del servidor',
          type: NetworkExceptionType.serverError,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          'Operación cancelada',
          type: NetworkExceptionType.unknown,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          'Error de certificado SSL',
          type: NetworkExceptionType.unknown,
        );

      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return NetworkException(
            'Sin conexión a internet',
            type: NetworkExceptionType.noConnection,
          );
        }
        return NetworkException(
          'Error de conexión desconocido',
          type: NetworkExceptionType.unknown,
        );

      default:
        return NetworkException(
          'Error de conexión',
          type: NetworkExceptionType.unknown,
        );
    }
  }
}

class ActualizacionUbicacionResponse {
  final bool success;
  final String mensaje;

  ActualizacionUbicacionResponse({
    required this.success,
    required this.mensaje,
  });
}

class SincronizacionResponse {
  final bool success;
  final int ubicacionesSincronizadas;
  final int ubicacionesFallidas;

  SincronizacionResponse({
    required this.success,
    required this.ubicacionesSincronizadas,
    required this.ubicacionesFallidas,
  });
}
