/// Constantes de la API
class ApiConstants {
  // URL base del backend 192.168.0.14
  static const String baseUrl = 'http://192.168.0.14:8080';

  // Endpoints
  static const String onboardingEndpoint = '/public/transportista/onboarding';
  static const String uploadFileEndpoint = '/files/upload';
  static const String completarOnboardingEndpoint =
      '/public/onboarding/completar';
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
