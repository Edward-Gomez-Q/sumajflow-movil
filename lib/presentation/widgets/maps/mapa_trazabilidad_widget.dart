import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
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
  bool _isInitialLoad = true;
  http.Client? _httpClient;
  late final TileProvider _tileProvider;

  Timer? _routeDebounce;
  Timer? _periodicRouteUpdate;
  DateTime? _lastRouteFetchAt;
  String? _lastRouteKey;

  static const double _routeRecalcDistanceMeters = 150;
  static const Duration _minTimeBetweenRouteFetch = Duration(seconds: 20);
  static const Duration _routeDebounceDuration = Duration(seconds: 1);
  static const Duration _periodicUpdateInterval = Duration(seconds: 10);

  LatLng? _lastCentered;
  DateTime? _lastCenterAt;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();

    _tileProvider = FMTCTileProvider(
      stores: const {'sumajflowMapStore': BrowseStoreStrategy.readUpdateCreate},
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    );

    _scheduleFetchRoute(reason: 'init');
    _startPeriodicRouteUpdate();
  }

  void _startPeriodicRouteUpdate() {
    _periodicRouteUpdate?.cancel();
    _periodicRouteUpdate = Timer.periodic(_periodicUpdateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Solo actualizar si hay posición y waypoint
      if (widget.currentPosition != null &&
          widget.proximoWaypoint != null &&
          widget.proximoWaypoint!.tieneCoordenadas) {
        debugPrint(
          '🔄 Actualización periódica de ruta (cada ${_periodicUpdateInterval.inSeconds}s)',
        );
        _fetchRoute(force: false, reason: 'periodic', showLoading: false);
      }
    });
  }

  @override
  void didUpdateWidget(MapaTrazabilidadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final waypointChanged = oldWidget.proximoWaypoint != widget.proximoWaypoint;

    final movedEnough = _hasPositionChangedSignificantly(
      oldWidget.currentPosition,
      widget.currentPosition,
      meters: _routeRecalcDistanceMeters,
    );

    if (waypointChanged) {
      _scheduleFetchRoute(
        reason: 'waypointChanged',
        force: true,
        showLoading: false,
      );
    } else if (movedEnough) {
      _scheduleFetchRoute(reason: 'movedEnough', showLoading: false);
    }

    _maybeCenterOnCurrentPosition();
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    _periodicRouteUpdate?.cancel();
    _httpClient?.close();
    _httpClient = null;
    super.dispose();
  }

  bool _hasPositionChangedSignificantly(
    Position? old,
    Position? current, {
    required double meters,
  }) {
    if (old == null || current == null) return true;

    final distance = Geolocator.distanceBetween(
      old.latitude,
      old.longitude,
      current.latitude,
      current.longitude,
    );

    return distance > meters;
  }

  void _scheduleFetchRoute({
    required String reason,
    bool force = false,
    bool showLoading = true,
  }) {
    if (!mounted) return;

    _routeDebounce?.cancel();
    _routeDebounce = Timer(_routeDebounceDuration, () {
      if (!mounted) return;
      _fetchRoute(force: force, reason: reason, showLoading: showLoading);
    });
  }

  bool _canFetchByTime({required bool force}) {
    if (force) return true;
    final last = _lastRouteFetchAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _minTimeBetweenRouteFetch;
  }

  String _routeKey({
    required double sLat,
    required double sLng,
    required double eLat,
    required double eLng,
  }) {
    String r(double v) => v.toStringAsFixed(4);
    return '${r(sLat)},${r(sLng)}|${r(eLat)},${r(eLng)}';
  }

  Future<http.Response> _getWithRetry(Uri url) async {
    const attempts = 3;

    for (int i = 0; i < attempts; i++) {
      try {
        final client = _httpClient;
        if (client == null) throw const SocketException('HTTP client is null');

        final res = await client.get(url).timeout(const Duration(seconds: 10));
        return res;
      } on TimeoutException {
        if (i == attempts - 1) rethrow;
      } on SocketException {
        if (i == attempts - 1) rethrow;
      } on HttpException {
        if (i == attempts - 1) rethrow;
      } on http.ClientException {
        if (i == attempts - 1) rethrow;
      } catch (_) {
        if (i == attempts - 1) rethrow;
      }

      await Future.delayed(Duration(milliseconds: 300 * (1 << i)));
    }

    throw Exception('Retries agotados');
  }

  Future<void> _fetchRoute({
    required bool force,
    required String reason,
    bool showLoading = true,
  }) async {
    if (!mounted) return;

    final pos = widget.currentPosition;
    final wp = widget.proximoWaypoint;

    if (pos == null || wp == null || !wp.tieneCoordenadas) {
      if (!mounted) return;
      setState(() {
        _routePoints = [];
        _isLoadingRoute = false;
        _routeError = false;
        _isInitialLoad = false;
      });
      return;
    }

    final startLat = pos.latitude;
    final startLng = pos.longitude;
    final endLat = wp.latitud!;
    final endLng = wp.longitud!;

    if (!_canFetchByTime(force: force)) {
      return;
    }

    final key = _routeKey(
      sLat: startLat,
      sLng: startLng,
      eLat: endLat,
      eLng: endLng,
    );
    if (!force && _lastRouteKey == key && _routePoints.isNotEmpty) {
      return;
    }

    _lastRouteKey = key;
    _lastRouteFetchAt = DateTime.now();

    // 👇 MODIFICADO: Solo mostrar loading si es la carga inicial o se solicita explícitamente
    if (showLoading && _isInitialLoad) {
      setState(() {
        _isLoadingRoute = true;
        _routeError = false;
      });
    }

    try {
      final coordinates = '$startLng,$startLat;$endLng,$endLat';

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline',
      );

      final response = await _getWithRetry(url);

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
            _isInitialLoad = false;
          });
          return;
        }
      }

      _useFallbackRoute();
    } catch (_) {
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
        _isInitialLoad = false;
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
      _isInitialLoad = false;
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
    if (!mounted) return;
    final pos = widget.currentPosition;
    if (pos == null) return;

    final now = DateTime.now();
    final current = LatLng(pos.latitude, pos.longitude);

    if (_lastCentered == null) {
      _center(current);
      return;
    }

    if (_lastCenterAt != null &&
        now.difference(_lastCenterAt!) < const Duration(seconds: 2)) {
      return;
    }

    final dist = Geolocator.distanceBetween(
      _lastCentered!.latitude,
      _lastCentered!.longitude,
      current.latitude,
      current.longitude,
    );

    if (dist > 80) {
      _center(current);
    }
  }

  void _center(LatLng target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(target, 15.0);
        _lastCentered = target;
        _lastCenterAt = DateTime.now();
      } catch (_) {}
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
            initialZoom: 15.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'bo.edu.ucb.sumajflow',
              tileProvider: _tileProvider,
              errorTileCallback: (tile, error, stackTrace) {},
            ),

            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: _routeError ? 3 : 5,
                    color: theme.colorScheme.primary,
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

        // 👇 MODIFICADO: Solo mostrar loading en la carga inicial
        if (_isLoadingRoute && _isInitialLoad)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Calculando ruta...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_routeError && !_isLoadingRoute)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ruta aproximada en línea recta',
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
            onPressed: () => _center(currentLatLng),
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
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
