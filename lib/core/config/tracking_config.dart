// lib/core/config/tracking_config.dart

/// Configuración centralizada de intervalos de tracking
class TrackingConfig {
  // Intervalos de actualización
  static const int locationUpdateInterval = 5;
  static const int syncInterval = 10;
  static const int routeUpdateInterval = 15;

  // Umbrales de distancia
  static const double routeRecalcDistanceMeters = 50.0;
  static const double significantMovementMeters = 10.0;

  // Timeouts
  static const Duration locationTimeout = Duration(seconds: 10);
  static const Duration routeFetchTimeout = Duration(seconds: 8);

  // Rate limiting
  static const Duration minTimeBetweenRouteFetch = Duration(seconds: 15);
  static const Duration routeDebounceDuration = Duration(seconds: 2);

  // Geofencing
  static const double radioMina = 500.0;
  static const double radioBalanza = 200.0;
  static const double radioAlmacen = 300.0;
}
