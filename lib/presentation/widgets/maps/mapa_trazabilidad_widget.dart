// lib/presentation/widgets/maps/mapa_trazabilidad_widget.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sumajflow_movil/core/config/tracking_config.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';

class MapaTrazabilidadWidget extends StatefulWidget {
  final Position? currentPosition;
  final WaypointModel? proximoWaypoint;
  final String estadoViaje;

  const MapaTrazabilidadWidget({
    super.key,
    required this.currentPosition,
    this.proximoWaypoint,
    required this.estadoViaje,
  });

  @override
  State<MapaTrazabilidadWidget> createState() => _MapaTrazabilidadWidgetState();
}

class _MapaTrazabilidadWidgetState extends State<MapaTrazabilidadWidget> {
  final MapController _mapController = MapController();

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  bool _routeError = false;
  http.Client? _httpClient;
  late final TileProvider _tileProvider;

  Timer? _routeUpdateTimer;
  DateTime? _lastRouteFetchAt;
  String? _lastRouteKey;
  Position? _lastRoutePosition;

  LatLng? _lastCentered;
  DateTime? _lastCenterAt;
  bool _userInteractedWithMap = false;
  Timer? _resetInteractionTimer;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();

    _tileProvider = FMTCTileProvider(
      stores: const {'sumajflowMapStore': BrowseStoreStrategy.readUpdateCreate},
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    );

    // Fetch inicial de ruta
    _fetchRouteIfNeeded(force: true);

    // Timer periódico para actualizar ruta
    _routeUpdateTimer = Timer.periodic(
      Duration(seconds: TrackingConfig.routeUpdateInterval),
      (_) => _fetchRouteIfNeeded(),
    );
  }

  @override
  void didUpdateWidget(MapaTrazabilidadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final waypointChanged = oldWidget.proximoWaypoint != widget.proximoWaypoint;
    final positionChanged = _hasPositionChangedSignificantly(
      oldWidget.currentPosition,
      widget.currentPosition,
    );

    if (waypointChanged) {
      debugPrint('🎯 Waypoint cambió, recalculando ruta');
      _fetchRouteIfNeeded(force: true);
    } else if (positionChanged) {
      _fetchRouteIfNeeded();
    }

    _maybeCenterOnCurrentPosition();
  }

  @override
  void dispose() {
    _routeUpdateTimer?.cancel();
    _resetInteractionTimer?.cancel();
    _httpClient?.close();
    _httpClient = null;
    super.dispose();
  }

  bool _hasPositionChangedSignificantly(Position? old, Position? current) {
    if (old == null || current == null) return false;
    if (_lastRoutePosition == null) return true;

    final distance = Geolocator.distanceBetween(
      _lastRoutePosition!.latitude,
      _lastRoutePosition!.longitude,
      current.latitude,
      current.longitude,
    );

    return distance > TrackingConfig.routeRecalcDistanceMeters;
  }

  bool _canFetchByTime() {
    final last = _lastRouteFetchAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >=
        TrackingConfig.minTimeBetweenRouteFetch;
  }

  String _routeKey({
    required double sLat,
    required double sLng,
    required double eLat,
    required double eLng,
  }) {
    String r(double v) => v.toStringAsFixed(3);
    return '${r(sLat)},${r(sLng)}|${r(eLat)},${r(eLng)}';
  }

  Future<void> _fetchRouteIfNeeded({bool force = false}) async {
    if (!mounted) return;

    final pos = widget.currentPosition;
    final wp = widget.proximoWaypoint;

    if (pos == null || wp == null || !wp.tieneCoordenadas) {
      if (_routePoints.isNotEmpty) {
        setState(() {
          _routePoints = [];
          _isLoadingRoute = false;
          _routeError = false;
        });
      }
      return;
    }

    if (!force && !_canFetchByTime()) {
      return;
    }

    final key = _routeKey(
      sLat: pos.latitude,
      sLng: pos.longitude,
      eLat: wp.latitud!,
      eLng: wp.longitud!,
    );

    if (!force && _lastRouteKey == key && _routePoints.isNotEmpty) {
      return;
    }

    _lastRouteKey = key;
    _lastRouteFetchAt = DateTime.now();
    _lastRoutePosition = pos;

    if (_isLoadingRoute) return;

    setState(() => _isLoadingRoute = true);

    try {
      final coordinates =
          '${pos.longitude},${pos.latitude};${wp.longitud},${wp.latitud}';

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline',
      );

      // CORRECCIÓN: Usar try-catch para manejar el timeout
      http.Response? response;

      try {
        response = await _httpClient!
            .get(url)
            .timeout(
              TrackingConfig.routeFetchTimeout,
              onTimeout: () {
                // No lanzar excepción aquí, retornar null
                throw TimeoutException('Route fetch timeout');
              },
            );
      } on TimeoutException {
        // Timeout controlado - usar fallback silenciosamente
        if (!mounted) return;
        _useFallbackRoute();
        return;
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'] as String;
          final decodedPoints = _decodePolyline(geometry);

          if (!mounted) return;
          setState(() {
            _routePoints = decodedPoints;
            _isLoadingRoute = false;
            _routeError = false;
          });
          return;
        }
      }

      _useFallbackRoute();
    } on http.ClientException catch (_) {
      // Error de cliente HTTP (sin conexión, etc.)
      if (!mounted) return;
      _useFallbackRoute();
    } on FormatException catch (_) {
      // Error al parsear JSON
      if (!mounted) return;
      _useFallbackRoute();
    } catch (e) {
      // Cualquier otro error
      if (_routePoints.isEmpty) {
        debugPrint('⚠️ Error al obtener ruta: ${e.runtimeType}');
      }
      if (!mounted) return;
      _useFallbackRoute();
    }
  }

  void _useFallbackRoute() {
    if (!mounted) return;

    final pos = widget.currentPosition;
    final wp = widget.proximoWaypoint;

    if (pos == null || wp == null || !wp.tieneCoordenadas) {
      setState(() {
        _routePoints = [];
        _isLoadingRoute = false;
        _routeError = true;
      });
      return;
    }

    setState(() {
      _routePoints = [
        LatLng(pos.latitude, pos.longitude),
        LatLng(wp.latitud!, wp.longitud!),
      ];
      _isLoadingRoute = false;
      _routeError = true;
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  void _maybeCenterOnCurrentPosition() {
    if (!mounted || _userInteractedWithMap) return;

    final pos = widget.currentPosition;
    if (pos == null) return;

    final now = DateTime.now();
    final current = LatLng(pos.latitude, pos.longitude);

    if (_lastCentered == null) {
      _center(current);
      return;
    }

    if (_lastCenterAt != null &&
        now.difference(_lastCenterAt!) < const Duration(seconds: 3)) {
      return;
    }

    final dist = Geolocator.distanceBetween(
      _lastCentered!.latitude,
      _lastCentered!.longitude,
      current.latitude,
      current.longitude,
    );

    if (dist > 50) {
      _center(current);
    }
  }

  void _center(LatLng target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(target, 16.0);
        _lastCentered = target;
        _lastCenterAt = DateTime.now();
      } catch (_) {
        // Ignorar errores del controlador del mapa
      }
    });
  }

  void _onMapInteraction() {
    _userInteractedWithMap = true;
    _resetInteractionTimer?.cancel();
    _resetInteractionTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _userInteractedWithMap = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.currentPosition == null) {
      return _buildEmptyState(theme, 'Obteniendo ubicación...');
    }

    final currentLatLng = LatLng(
      widget.currentPosition!.latitude,
      widget.currentPosition!.longitude,
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentLatLng,
            initialZoom: 16.0,
            minZoom: 5.0,
            maxZoom: 18.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onPositionChanged: (_, __) => _onMapInteraction(),
            onTap: (_, __) => _onMapInteraction(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'bo.edu.ucb.sumajflow',
              tileProvider: _tileProvider,
              maxNativeZoom: 19,
              maxZoom: 22,
            ),

            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: _routeError ? 3 : 5,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                Marker(
                  point: currentLatLng,
                  width: 50,
                  height: 50,
                  child: _buildCurrentPositionMarker(theme),
                ),
                if (widget.proximoWaypoint != null &&
                    widget.proximoWaypoint!.tieneCoordenadas)
                  Marker(
                    point: LatLng(
                      widget.proximoWaypoint!.latitud!,
                      widget.proximoWaypoint!.longitud!,
                    ),
                    width: 50,
                    height: 50,
                    child: _buildWaypointMarker(theme),
                  ),
              ],
            ),
          ],
        ),

        if (_routeError && !_isLoadingRoute)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ruta aproximada (sin conexión)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              _userInteractedWithMap = false;
              _center(currentLatLng);
            },
            backgroundColor: theme.colorScheme.surface,
            child: Icon(
              Icons.my_location_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPositionMarker(ThemeData theme) {
    final heading = widget.currentPosition?.heading ?? 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        Transform.rotate(
          angle: heading * (math.pi / 180),
          child: Icon(
            Icons.navigation_rounded,
            color: theme.colorScheme.primary,
            size: 32,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaypointMarker(ThemeData theme) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _hexToColor(widget.proximoWaypoint!.color),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: _hexToColor(
              widget.proximoWaypoint!.color,
            ).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.proximoWaypoint!.iconoEmoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
