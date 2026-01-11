// lib/presentation/widgets/maps/map_four_waypoints.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapFourWaypoints extends StatefulWidget {
  final List<WaypointModel> waypoints;
  final double height;

  const MapFourWaypoints({
    super.key,
    required this.waypoints,
    this.height = 350,
  });

  @override
  State<MapFourWaypoints> createState() => _MapFourWaypointsState();
}

class _MapFourWaypointsState extends State<MapFourWaypoints> {
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _routeError = false;
  http.Client? _httpClient; //   Cliente HTTP para poder cancelar peticiones

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client(); //   Inicializar cliente
    _fetchRoute();
  }

  @override
  void didUpdateWidget(MapFourWaypoints oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waypoints != widget.waypoints) {
      _fetchRoute();
    }
  }

  @override
  void dispose() {
    //   Cancelar peticiones pendientes y cerrar cliente
    _httpClient?.close();
    _httpClient = null;
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    //   Verificar si el widget está montado antes de setState
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _routeError = false;
    });

    try {
      final waypointsValidos = widget.waypoints
          .where((w) => w.tieneCoordenadas)
          .toList();

      if (waypointsValidos.isEmpty) {
        if (!mounted) return; //   Verificar antes de setState
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (waypointsValidos.length < 4) {
        if (!mounted) return; //   Verificar antes de setState
        setState(() {
          _routePoints = waypointsValidos
              .map((w) => LatLng(w.latitud!, w.longitud!))
              .toList();
          _isLoading = false;
          _routeError = true;
        });
        return;
      }

      final coordinates = waypointsValidos
          .map((w) => '${w.longitud},${w.latitud}')
          .join(';');

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline',
      );

      //   Usar el cliente HTTP que puede ser cancelado
      final response = await _httpClient
          ?.get(url)
          .timeout(const Duration(seconds: 10));

      //   Verificar si la respuesta es null (widget fue disposed)
      if (response == null || !mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'] as String;

          final decodedPoints = _decodePolyline(geometry);

          if (!mounted) return; //   Verificar antes de setState
          setState(() {
            _routePoints = decodedPoints;
            _isLoading = false;
            _routeError = false;
          });
        } else {
          _useFallbackRoute(waypointsValidos);
        }
      } else {
        _useFallbackRoute(waypointsValidos);
      }
    } catch (e) {
      //   Si el widget fue disposed, no hacer nada
      if (!mounted) return;

      final waypointsValidos = widget.waypoints
          .where((w) => w.tieneCoordenadas)
          .toList();
      _useFallbackRoute(waypointsValidos);
    }
  }

  void _useFallbackRoute(List<WaypointModel> waypoints) {
    if (!mounted) return; //   Verificar antes de setState

    setState(() {
      _routePoints = waypoints
          .map((w) => LatLng(w.latitud!, w.longitud!))
          .toList();
      _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waypointsValidos = widget.waypoints
        .where((w) => w.tieneCoordenadas)
        .toList();

    if (waypointsValidos.isEmpty) {
      return _buildEmptyState(theme);
    }

    final boundsPoints = waypointsValidos
        .map((w) => LatLng(w.latitud!, w.longitud!))
        .toList();
    final bounds = LatLngBounds.fromPoints(boundsPoints);

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(60),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'bo.edu.ucb.sumajflow',
                ),

                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: _routeError ? 2.5 : 4,
                        color: theme.colorScheme.primary,
                        borderStrokeWidth: 1.5,
                        borderColor: Colors.white,
                        isDotted: _routeError,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: waypointsValidos.map((waypoint) {
                    return Marker(
                      point: LatLng(waypoint.latitud!, waypoint.longitud!),
                      width: 38,
                      height: 38,
                      child: TweenAnimationBuilder<double>(
                        duration: Duration(
                          milliseconds: 400 + (waypoint.orden * 150),
                        ),
                        curve: Curves.elasticOut,
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _hexToColor(waypoint.color),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: _hexToColor(
                                  waypoint.color,
                                ).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              waypoint.orden.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cargando mapa...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_routeError && !_isLoading)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 10),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Mapa no disponible',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
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
