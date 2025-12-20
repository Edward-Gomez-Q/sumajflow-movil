// lib/data/repositories/transportista_repository.dart
import 'dart:io';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/data/models/transportista_model.dart';
import 'package:sumajflow_movil/data/providers/api_provider.dart';

/// Repositorio para operaciones relacionadas con transportistas
class TransportistaRepository {
  final ApiProvider _apiProvider = ApiProvider();

  Future<Map<String, dynamic>?> completarOnboarding({
    required String token,
    required TransportistaModel transportista,
  }) async {
    try {
      final data = {
        'token': token,
        'ci': transportista.ci,
        'fechaNacimiento': transportista.fechaNacimiento,
        'correo': transportista.correo,
        'contrasena': transportista.contrasena,
        'placaVehiculo': transportista.placaVehiculo,
        'marcaVehiculo': transportista.marcaVehiculo,
        'modeloVehiculo': transportista.modeloVehiculo,
        'colorVehiculo': transportista.colorVehiculo,
        'pesoTara': transportista.pesoTara,
        'capacidadCarga': transportista.capacidadCarga,
        'licenciaConducirUrl': transportista.licenciaConducirUrl,
        'categoriaLicencia': transportista.categoriaLicencia,
        'fechaVencimientoLicencia': transportista.fechaVencimientoLicencia,
      };

      print('📤 Enviando datos al backend: $data');

      final response = await _apiProvider.post(
        ApiConstants.completarOnboardingEndpoint,
        data,
      );

      print('📥 Status code: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Onboarding completado exitosamente');

        // ✅ Asegurarse de devolver la estructura correcta
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else {
          print('⚠️ La respuesta no es un Map<String, dynamic>');
          return null;
        }
      } else {
        print('❌ Error en respuesta del servidor: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error en completarOnboarding: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Sube un archivo a MinIO usando el ApiProvider
  Future<String> uploadFile(File file, String folder) async {
    try {
      print('📤 Subiendo archivo a MinIO en carpeta: $folder');
      final objectName = await _apiProvider.uploadFile(file, folder: folder);
      print('✅ Archivo subido exitosamente: $objectName');
      return objectName;
    } catch (e) {
      print('❌ Error al subir archivo: $e');
      rethrow;
    }
  }

  /// Valida un token de invitación
  Future<Map<String, dynamic>?> validarToken(String token) async {
    try {
      final response = await _apiProvider.get(
        '${ApiConstants.onboardingEndpoint}/validar/$token',
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('❌ Error al validar token: $e');
      return null;
    }
  }
}
