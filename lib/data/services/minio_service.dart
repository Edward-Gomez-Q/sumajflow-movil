// lib/data/services/minio_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class MinioService {
  final Dio _dio;
  final String baseUrl;

  MinioService({required this.baseUrl, Dio? dio}) : _dio = dio ?? Dio();

  /// Sube un archivo a MinIO
  /// [file]: Archivo a subir
  /// [folder]: Carpeta donde se guardará (ej: 'documentos-transportistas')
  /// Retorna el objectName del archivo subido
  Future<String> uploadFile(File file, String folder) async {
    try {
      // Obtener el tipo MIME del archivo
      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';

      // Crear FormData
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ),
        'folder': folder,
      });

      // Hacer petición
      final response = await _dio.post(
        '$baseUrl/files/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        // Retornar el objectName
        return response.data['data']['objectName'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Error al subir archivo');
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
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene la URL pública de un archivo
  Future<String> getFileUrl(String objectName) async {
    try {
      final response = await _dio.get(
        '$baseUrl/files/url',
        queryParameters: {'objectName': objectName},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['url'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Error al obtener URL');
      }
    } catch (e) {
      throw Exception('Error al obtener URL: $e');
    }
  }

  /// Elimina un archivo
  Future<void> deleteFile(String objectName) async {
    try {
      await _dio.delete(
        '$baseUrl/files',
        queryParameters: {'objectName': objectName},
      );
    } catch (e) {
      throw Exception('Error al eliminar archivo: $e');
    }
  }
}
