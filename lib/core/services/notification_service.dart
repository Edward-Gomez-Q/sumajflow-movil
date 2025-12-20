// lib/core/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get to => _instance;

  /// Muestra un mensaje de éxito
  void showSuccess(String title, String message) {
    _showNotification(
      title: title,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// Muestra un mensaje de error
  void showError(String title, String message) {
    _showNotification(
      title: title,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  /// Muestra un mensaje de advertencia
  void showWarning(String title, String message) {
    _showNotification(
      title: title,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// Muestra un mensaje de información
  void showInfo(String title, String message) {
    _showNotification(
      title: title,
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  /// Método privado para mostrar la notificación
  void _showNotification({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(icon, color: Colors.white),
        shouldIconPulse: true,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      );
    } else {
      // Si Get.context no está disponible, imprimir en consola
      debugPrint('⚠️ NotificationService: Get.context no disponible');
      debugPrint('📢 $title: $message');
    }
  }

  /// Maneja errores de API de forma centralizada
  String handleApiError(dynamic error) {
    debugPrint('❌ API Error: $error');

    if (error is String) {
      return error;
    }

    // Si es una excepción con mensaje
    if (error.toString().contains('Exception:')) {
      final message = error.toString().replaceAll('Exception:', '').trim();
      return message;
    }

    return 'Ha ocurrido un error. Por favor, intenta nuevamente.';
  }
}
