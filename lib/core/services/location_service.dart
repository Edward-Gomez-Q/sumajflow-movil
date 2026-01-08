// lib/core/services/location_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Servicio para manejo de GPS y geolocalización
class LocationService extends GetxService {
  static LocationService get to => Get.find();

  // Estado observable
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isTracking = false.obs;
  final RxBool hasPermission = false.obs;
  final RxBool isGpsEnabled = false.obs;
  final RxString errorMessage = ''.obs;

  // Modo simulación
  final RxBool simulationMode = false.obs;
  final Rx<Position?> simulatedPosition = Rx<Position?>(null);

  // Stream de posiciones
  StreamSubscription<Position>? _positionStreamSubscription;

  // Callbacks
  Function(Position)? onPositionUpdate;
  Function(String)? onError;

  // Configuración
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // metros mínimos entre actualizaciones
  );

  Future<LocationService> init() async {
    await checkPermissions();
    await checkGpsStatus();
    return this;
  }

  /// Verifica y solicita permisos de ubicación
  Future<bool> checkPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        hasPermission.value = false;
        errorMessage.value =
            'Permisos de ubicación denegados permanentemente. '
            'Por favor, habilítalos en la configuración del dispositivo.';
        return false;
      }

      if (permission == LocationPermission.denied) {
        hasPermission.value = false;
        errorMessage.value = 'Permisos de ubicación denegados';
        return false;
      }

      hasPermission.value = true;
      errorMessage.value = '';
      return true;
    } catch (e) {
      hasPermission.value = false;
      errorMessage.value = 'Error al verificar permisos: $e';
      return false;
    }
  }

  /// Verifica si el GPS está habilitado
  Future<bool> checkGpsStatus() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      isGpsEnabled.value = enabled;

      if (!enabled) {
        errorMessage.value = 'GPS deshabilitado. Por favor, actívalo.';
      }

      return enabled;
    } catch (e) {
      isGpsEnabled.value = false;
      errorMessage.value = 'Error al verificar GPS: $e';
      return false;
    }
  }

  /// Obtiene la posición actual una vez
  Future<Position?> getCurrentPosition() async {
    // Si está en modo simulación, devolver posición simulada
    if (simulationMode.value && simulatedPosition.value != null) {
      return simulatedPosition.value;
    }

    if (!await checkPermissions()) return null;
    if (!await checkGpsStatus()) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      currentPosition.value = position;
      return position;
    } catch (e) {
      errorMessage.value = 'Error al obtener ubicación: $e';
      onError?.call(errorMessage.value);
      return null;
    }
  }

  /// Inicia el tracking continuo de ubicación
  Future<bool> startTracking({
    Function(Position)? onUpdate,
    Function(String)? onErrorCallback,
    int intervalSeconds = 30,
  }) async {
    if (isTracking.value) {
      debugPrint('⚠️ Tracking ya está activo');
      return true;
    }

    // Si está en modo simulación, no iniciar tracking real
    if (simulationMode.value) {
      isTracking.value = true;
      debugPrint('🎮 Tracking en modo simulación');
      return true;
    }

    if (!await checkPermissions()) return false;
    if (!await checkGpsStatus()) return false;

    onPositionUpdate = onUpdate;
    onError = onErrorCallback;

    try {
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: _locationSettings,
          ).listen(
            (Position position) {
              currentPosition.value = position;
              onPositionUpdate?.call(position);
              debugPrint(
                '📍 Nueva ubicación: ${position.latitude}, ${position.longitude}',
              );
            },
            onError: (error) {
              errorMessage.value = 'Error de tracking: $error';
              onError?.call(errorMessage.value);
              debugPrint('❌ Error de tracking: $error');
            },
          );

      isTracking.value = true;
      debugPrint('✅ Tracking iniciado');
      return true;
    } catch (e) {
      errorMessage.value = 'Error al iniciar tracking: $e';
      onError?.call(errorMessage.value);
      return false;
    }
  }

  /// Detiene el tracking
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    isTracking.value = false;
    onPositionUpdate = null;
    onError = null;
    debugPrint('⏹️ Tracking detenido');
  }

  /// Calcula la distancia entre dos puntos en metros
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calcula el bearing (dirección) entre dos puntos
  double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Verifica si está dentro de una zona (geofencing)
  bool isWithinZone({
    required double currentLat,
    required double currentLng,
    required double zoneLat,
    required double zoneLng,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(
      currentLat,
      currentLng,
      zoneLat,
      zoneLng,
    );
    return distance <= radiusMeters;
  }

  // ==================== MODO SIMULACIÓN ====================

  /// Activa el modo simulación
  void enableSimulationMode() {
    simulationMode.value = true;
    debugPrint('🎮 Modo simulación activado');
  }

  /// Desactiva el modo simulación
  void disableSimulationMode() {
    simulationMode.value = false;
    simulatedPosition.value = null;
    debugPrint('🎮 Modo simulación desactivado');
  }

  /// Establece una posición simulada
  void setSimulatedPosition(
    double lat,
    double lng, {
    double? speed,
    double? heading,
  }) {
    if (!simulationMode.value) {
      enableSimulationMode();
    }

    simulatedPosition.value = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 4000.0,
      altitudeAccuracy: 10.0,
      heading: heading ?? 0.0,
      headingAccuracy: 10.0,
      speed: speed ?? 0.0,
      speedAccuracy: 1.0,
    );

    currentPosition.value = simulatedPosition.value;

    // Notificar a los listeners
    if (isTracking.value && onPositionUpdate != null) {
      onPositionUpdate!(simulatedPosition.value!);
    }

    debugPrint('🎮 Posición simulada: $lat, $lng');
  }

  /// Mueve la posición simulada gradualmente hacia un punto
  Future<void> moveSimulatedPositionTo(
    double targetLat,
    double targetLng, {
    int steps = 10,
    Duration stepDelay = const Duration(milliseconds: 500),
  }) async {
    if (simulatedPosition.value == null) {
      setSimulatedPosition(targetLat, targetLng);
      return;
    }

    final startLat = simulatedPosition.value!.latitude;
    final startLng = simulatedPosition.value!.longitude;

    final latStep = (targetLat - startLat) / steps;
    final lngStep = (targetLng - startLng) / steps;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDelay);

      final newLat = startLat + (latStep * i);
      final newLng = startLng + (lngStep * i);

      // Calcular velocidad aproximada
      final distance = calculateDistance(
        startLat + (latStep * (i - 1)),
        startLng + (lngStep * (i - 1)),
        newLat,
        newLng,
      );
      final speedMps = distance / (stepDelay.inMilliseconds / 1000);
      final speedKmh = speedMps * 3.6;

      // Calcular dirección
      final heading = calculateBearing(
        simulatedPosition.value!.latitude,
        simulatedPosition.value!.longitude,
        newLat,
        newLng,
      );

      setSimulatedPosition(newLat, newLng, speed: speedKmh, heading: heading);
    }
  }

  /// Abre la configuración de ubicación del dispositivo
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Abre la configuración de la app
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }
}
