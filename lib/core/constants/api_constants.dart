/// Constantes de la API
class ApiConstants {
  static const String ip = '192.168.0.15';
  static const String baseUrl = 'http://$ip:8080';
  static const String wsUrl = 'ws://$ip:8080/ws-native';

  // Endpoints
  static const String onboardingEndpoint = '/public/transportista/onboarding';
  static const String uploadFileEndpoint = '/files/upload';
  static const String completarOnboardingEndpoint =
      '/public/onboarding/completar';
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
