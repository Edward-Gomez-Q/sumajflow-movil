// lib/data/repositories/perfil_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/data/models/perfil_models.dart';

class PerfilRepository {
  late final Dio _dio;

  PerfilRepository() {
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

  /// Obtener perfil completo
  Future<PerfilModel> getPerfil() async {
    try {
      debugPrint('📋 Obteniendo perfil');

      final response = await _dio.get('/transportista/perfil');

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Perfil obtenido exitosamente');
        return PerfilModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Error al obtener perfil');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Obtener datos del transportista
  Future<TransportistaPerfilModel> getDatosTransportista() async {
    try {
      debugPrint('🚚 Obteniendo datos del transportista');

      final response = await _dio.get(
        '/transportista/perfil/datos-transportista',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Datos del transportista obtenidos');
        return TransportistaPerfilModel.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Error al obtener datos');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Actualizar datos personales
  Future<void> updateDatosPersonales(PersonaPerfilModel persona) async {
    try {
      debugPrint('📝 Actualizando datos personales');

      final response = await _dio.put(
        '/transportista/perfil/datos-personales',
        data: persona.toJson(),
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Error al actualizar datos',
        );
      }

      debugPrint('✅ Datos personales actualizados');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Actualizar datos del transportista
  Future<void> updateDatosTransportista(
    TransportistaPerfilModel transportista,
  ) async {
    try {
      debugPrint('🚚 Actualizando datos del transportista');

      final response = await _dio.put(
        '/transportista/perfil/datos-transportista',
        data: transportista.toJson(),
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ??
              'Error al actualizar datos del transportista',
        );
      }

      debugPrint('✅ Datos del transportista actualizados');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Actualizar correo electrónico
  Future<void> updateCorreo(String nuevoCorreo, String contrasenaActual) async {
    try {
      debugPrint('📧 Actualizando correo');

      final response = await _dio.put(
        '/transportista/perfil/correo',
        data: {'correo': nuevoCorreo, 'contrasena_actual': contrasenaActual},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Error al actualizar correo',
        );
      }

      debugPrint('✅ Correo actualizado');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Actualizar contraseña
  Future<void> updateContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    try {
      debugPrint('🔐 Actualizando contraseña');

      final response = await _dio.put(
        '/transportista/perfil/contrasena',
        data: {
          'contrasenaActual': contrasenaActual,
          'nuevaContrasena': nuevaContrasena,
          'confirmarContrasena': confirmarContrasena,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Error al actualizar contraseña',
        );
      }

      debugPrint('✅ Contraseña actualizada');
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
