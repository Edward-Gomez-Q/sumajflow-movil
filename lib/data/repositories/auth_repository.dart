// lib/data/repositories/auth_repository.dart
import 'package:sumajflow_movil/data/providers/api_provider.dart';

class AuthRepository {
  final ApiProvider _apiProvider = ApiProvider();

  /// Login con email y contraseña
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiProvider.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }

      throw Exception(response.data['message'] ?? 'Credenciales inválidas');
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiProvider.post('/auth/refresh', {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }

      throw Exception('Error al refrescar el token');
    } catch (e) {
      rethrow;
    }
  }
}
