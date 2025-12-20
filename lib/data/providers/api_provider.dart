// lib/data/providers/api_provider.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';

/// Proveedor de API para comunicación con el backend
class ApiProvider {
  late final Dio _dio;

  ApiProvider() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor para logging (opcional)
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  /// POST request genérico
  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload de archivo con carpeta específica
  Future<String> uploadFile(File file, {String folder = 'general'}) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'folder': folder,
      });

      final response = await _dio.post(
        ApiConstants.uploadFileEndpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          return response.data['data']['objectName'];
        } else {
          throw Exception(response.data['message'] ?? 'Error al subir archivo');
        }
      } else {
        throw Exception('Error al subir archivo: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          e.response!.data['message'] ?? 'Error al subir archivo',
        );
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al subir archivo: $e');
    }
  }

  /// GET request genérico
  Future<Response> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener URL de un archivo
  Future<String> getFileUrl(String objectName) async {
    try {
      final response = await _dio.get(
        '/files/url',
        queryParameters: {'objectName': objectName},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['url'];
      } else {
        throw Exception('Error al obtener URL del archivo');
      }
    } catch (e) {
      throw Exception('Error al obtener URL: $e');
    }
  }
}
