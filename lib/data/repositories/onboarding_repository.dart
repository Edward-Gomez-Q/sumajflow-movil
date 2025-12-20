// lib/data/repositories/onboarding_repository.dart
import 'package:sumajflow_movil/data/providers/api_provider.dart';

class OnboardingRepository {
  final ApiProvider _apiProvider = ApiProvider();

  /// Iniciar onboarding (envía código WhatsApp)
  Future<Map<String, dynamic>> iniciarOnboarding(String token) async {
    try {
      final response = await _apiProvider.post('/public/onboarding/iniciar', {
        'token': token,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception(
        response.data['message'] ?? 'Error al iniciar onboarding',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Verificar código de WhatsApp
  Future<Map<String, dynamic>> verificarCodigo(
    String token,
    String codigo,
  ) async {
    try {
      final response = await _apiProvider.post(
        '/public/onboarding/verificar-codigo',
        {'token': token, 'codigo': codigo},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception(response.data['message'] ?? 'Código incorrecto');
    } catch (e) {
      rethrow;
    }
  }

  /// Reenviar código
  Future<Map<String, dynamic>> reenviarCodigo(String token) async {
    try {
      final response = await _apiProvider.post(
        '/public/onboarding/reenviar-codigo',
        {'token': token},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception('Error al reenviar código');
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener datos de la invitación (nombre, teléfono, etc.)
  Future<Map<String, dynamic>> obtenerDatosInvitacion(String token) async {
    try {
      final response = await _apiProvider.post(
        '/public/onboarding/obtener-datos',
        {'token': token},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception(
        response.data['message'] ?? 'Error al obtener datos de invitación',
      );
    } catch (e) {
      rethrow;
    }
  }
}
