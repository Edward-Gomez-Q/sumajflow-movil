// lib/presentation/getx/login_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/data/repositories/auth_repository.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final NotificationService _notificationService = NotificationService.to;

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Estados
  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var rememberMe = false.obs;

  // Validación
  var isEmailValid = false.obs;
  var isPasswordValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    _loadSavedCredentials();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void _setupListeners() {
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);
  }

  void _validateEmail() {
    final email = emailController.text;
    isEmailValid.value = _isValidEmail(email);
  }

  void _validatePassword() {
    final password = passwordController.text;
    isPasswordValid.value = password.isNotEmpty && password.length >= 6;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  /// Cargar credenciales guardadas (si el usuario activó "Recordarme")
  Future<void> _loadSavedCredentials() async {
    // Aquí puedes implementar lógica para cargar credenciales de SharedPreferences
    // Por ahora lo dejamos vacío
  }

  /// Login principal
  Future<void> login(BuildContext context) async {
    if (!_validateForm()) {
      return;
    }

    isLoading.value = true;

    try {
      final response = await _authRepository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      debugPrint('  Login exitoso');
      debugPrint('📥 Respuesta completa: $response');

      // Extraer datos
      final token = response['token'] as String?;
      final user = response['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw Exception('Datos incompletos en la respuesta del servidor');
      }

      // Extraer información del usuario
      final usuarioId = user['id'] as int?;
      final correo = user['correo'] as String?;
      final rol = user['rol'] as String?;

      debugPrint('🔍 Token: $token');
      debugPrint('🔍 Usuario ID: $usuarioId');
      debugPrint('🔍 Correo: $correo');
      debugPrint('🔍 Rol: $rol');

      if (usuarioId == null || correo == null || rol == null) {
        throw Exception('Información de usuario incompleta');
      }

      // Verificar que sea transportista
      if (rol != 'transportista') {
        throw Exception('Esta aplicación es solo para transportistas');
      }
      final transportistaId = 0;

      await AuthService.to.saveAuthData(
        token: token,
        usuarioId: usuarioId,
        transportistaId: transportistaId,
        correo: correo,
      );

      debugPrint('  Datos guardados en AuthService');

      isLoading.value = false;

      _notificationService.showSuccess(
        'Bienvenido',
        'Has iniciado sesión correctamente',
      );

      // Navegar al dashboard
      if (context.mounted) {
        context.go(RouteNames.dashboard);
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint('❌ Error en login: $e');

      final errorMessage = _notificationService.handleApiError(e);
      _notificationService.showError('Error de inicio de sesión', errorMessage);
    }
  }

  bool _validateForm() {
    if (emailController.text.trim().isEmpty) {
      _notificationService.showWarning(
        'Campo requerido',
        'Por favor ingresa tu correo electrónico',
      );
      return false;
    }

    if (!isEmailValid.value) {
      _notificationService.showWarning(
        'Email inválido',
        'Por favor ingresa un correo electrónico válido',
      );
      return false;
    }

    if (passwordController.text.isEmpty) {
      _notificationService.showWarning(
        'Campo requerido',
        'Por favor ingresa tu contraseña',
      );
      return false;
    }

    if (!isPasswordValid.value) {
      _notificationService.showWarning(
        'Contraseña inválida',
        'La contraseña debe tener al menos 6 caracteres',
      );
      return false;
    }

    return true;
  }

  /// Limpiar formulario
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    obscurePassword.value = true;
  }
}
