// lib/core/services/location_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationService extends GetxService {
  static LocationService get to => Get.find();

  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool isTracking = false.obs;
  final RxBool hasPermission = false.obs;
  final RxBool isGpsEnabled = false.obs;
  final RxString errorMessage = ''.obs;

  final RxBool simulationMode = false.obs;
  final Rx<Position?> simulatedPosition = Rx<Position?>(null);

  StreamSubscription<Position>? _positionStreamSubscription;

  Function(Position)? onPositionUpdate;
  Function(String)? onError;

  static const LocationSettings _streamSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  static const LocationSettings _currentPositionSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  );

  Future<LocationService> init() async {
    await checkPermissions();
    await checkGpsStatus();
    return this;
  }

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

  Future<Position?> getCurrentPosition() async {
    if (simulationMode.value && simulatedPosition.value != null) {
      return simulatedPosition.value;
    }

    if (!await checkPermissions()) return null;
    if (!await checkGpsStatus()) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _currentPositionSettings,
      );

      currentPosition.value = position;
      return position;
    } catch (e) {
      errorMessage.value = 'Error al obtener ubicación: $e';
      onError?.call(errorMessage.value);
      return null;
    }
  }

  Future<bool> startTracking({
    Function(Position)? onUpdate,
    Function(String)? onErrorCallback,
    int intervalSeconds = 30,
  }) async {
    if (isTracking.value) {
      debugPrint('⚠️ Tracking ya está activo');
      return true;
    }

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
            locationSettings: _streamSettings,
          ).listen(
            (Position position) {
              currentPosition.value = position;
              onPositionUpdate?.call(position);
              debugPrint(
                '📍 Nueva ubicación: ${position.latitude}, ${position.longitude}',
              );
            },
            onError: (error) {
              debugPrint('❌ Error de tracking: $error');

              if (error is TimeoutException) {
                debugPrint('⏱️ Timeout del stream GPS, reintentando...');
                return;
              }

              errorMessage.value = 'Error de tracking: $error';
              onError?.call(errorMessage.value);
            },
            cancelOnError: false,
          );

      isTracking.value = true;
      debugPrint('  Tracking iniciado');
      return true;
    } catch (e) {
      errorMessage.value = 'Error al iniciar tracking: $e';
      onError?.call(errorMessage.value);
      return false;
    }
  }

  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    isTracking.value = false;
    onPositionUpdate = null;
    onError = null;
    debugPrint('⏹️ Tracking detenido');
  }

  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

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

  void enableSimulationMode() {
    simulationMode.value = true;
    debugPrint('🎮 Modo simulación activado');
  }

  void disableSimulationMode() {
    simulationMode.value = false;
    simulatedPosition.value = null;
    debugPrint('🎮 Modo simulación desactivado');
  }

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

    if (isTracking.value && onPositionUpdate != null) {
      onPositionUpdate!(simulatedPosition.value!);
    }

    debugPrint('🎮 Posición simulada: $lat, $lng');
  }

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

      final distance = calculateDistance(
        startLat + (latStep * (i - 1)),
        startLng + (lngStep * (i - 1)),
        newLat,
        newLng,
      );
      final speedMps = distance / (stepDelay.inMilliseconds / 1000);
      final speedKmh = speedMps * 3.6;

      final heading = calculateBearing(
        simulatedPosition.value!.latitude,
        simulatedPosition.value!.longitude,
        newLat,
        newLng,
      );

      setSimulatedPosition(newLat, newLng, speed: speedKmh, heading: heading);
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }
}
