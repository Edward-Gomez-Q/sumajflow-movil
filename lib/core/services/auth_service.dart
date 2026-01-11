// lib/core/services/auth_service.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final Rx<String?> _authToken = Rx<String?>(null);
  final Rx<int?> _usuarioId = Rx<int?>(null);
  final Rx<int?> _transportistaId = Rx<int?>(null);
  final Rx<String?> _correo = Rx<String?>(null);

  String? get authToken => _authToken.value;
  int? get usuarioId => _usuarioId.value;
  int? get transportistaId => _transportistaId.value;
  String? get correo => _correo.value;
  bool get isAuthenticated => _authToken.value != null;

  Future<AuthService> init() async {
    await _loadAuthData();
    return this;
  }

  /// Carga los datos de autenticación guardados
  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken.value = prefs.getString('auth_token');
      _usuarioId.value = prefs.getInt('usuario_id');
      _transportistaId.value = prefs.getInt('transportista_id');
      _correo.value = prefs.getString('correo');

      if (_authToken.value != null) {
        print('  Sesión cargada: Usuario ID ${_usuarioId.value}');
      }
    } catch (e) {
      print('❌ Error al cargar datos de autenticación: $e');
    }
  }

  /// Guarda los datos de autenticación después del onboarding
  Future<void> saveAuthData({
    required String token,
    required int usuarioId,
    required int transportistaId,
    required String correo,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('auth_token', token);
      await prefs.setInt('usuario_id', usuarioId);
      await prefs.setInt('transportista_id', transportistaId);
      await prefs.setString('correo', correo);

      _authToken.value = token;
      _usuarioId.value = usuarioId;
      _transportistaId.value = transportistaId;
      _correo.value = correo;

      print('  Datos de autenticación guardados');
      print('   - Token: ${token.substring(0, 20)}...');
      print('   - Usuario ID: $usuarioId');
      print('   - Transportista ID: $transportistaId');
      print('   - Correo: $correo');
    } catch (e) {
      print('❌ Error al guardar datos de autenticación: $e');
      rethrow;
    }
  }

  /// Limpia los datos de autenticación (logout)
  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('auth_token');
      await prefs.remove('usuario_id');
      await prefs.remove('transportista_id');
      await prefs.remove('correo');

      _authToken.value = null;
      _usuarioId.value = null;
      _transportistaId.value = null;
      _correo.value = null;

      print('  Sesión cerrada correctamente');
    } catch (e) {
      print('❌ Error al limpiar datos de autenticación: $e');
      rethrow;
    }
  }
}
