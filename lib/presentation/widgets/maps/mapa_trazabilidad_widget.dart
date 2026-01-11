// lib/presentation/widgets/maps/mapa_trazabilidad_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(MapaTrazabilidadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar ruta si cambió el waypoint o la posición significativamente
    if (oldWidget.proximoWaypoint != widget.proximoWaypoint ||
        _hasPositionChangedSignificantly(
          oldWidget.currentPosition,
          widget.currentPosition,
        )) {
      _fetchRoute();
    }

    // Centrar cámara en posición actual si está disponible
    if (widget.currentPosition != null) {
      _centerOnCurrentPosition();
    }
  }

  bool _hasPositionChangedSignificantly(Position? old, Position? current) {
    if (old == null || current == null) return true;

    final distance = Geolocator.distanceBetween(
      old.latitude,
      old.longitude,
      current.latitude,
      current.longitude,
    );

    // Actualizar si se movió más de 50 metros
    return distance > 50;
  }

  Future<void> _fetchRoute() async {
    if (widget.currentPosition == null || widget.proximoWaypoint == null) {
      setState(() {
        _routePoints = [];
        _isLoadingRoute = false;
      });
      return;
    }

    if (!widget.proximoWaypoint!.tieneCoordenadas) {
      setState(() {
        _routePoints = [];
        _isLoadingRoute = false;
      });
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _routeError = false;
    });

    try {
      final startLat = widget.currentPosition!.latitude;
      final startLng = widget.currentPosition!.longitude;
      final endLat = widget.proximoWaypoint!.latitud!;
      final endLng = widget.proximoWaypoint!.longitud!;

      final coordinates = '$startLng,$startLat;$endLng,$endLat';

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'] as String;

          final decodedPoints = _decodePolyline(geometry);

          setState(() {
            _routePoints = decodedPoints;
            _isLoadingRoute = false;
            _routeError = false;
          });
        } else {
          _useFallbackRoute();
        }
      } else {
        _useFallbackRoute();
      }
    } catch (e) {
      print('❌ Error al obtener ruta: $e');
      _useFallbackRoute();
    }
  }

  void _useFallbackRoute() {
    if (widget.currentPosition == null || widget.proximoWaypoint == null) {
      setState(() {
        _routePoints = [];
        _isLoadingRoute = false;
        _routeError = true;
      });
      return;
    }

    setState(() {
      _routePoints = [
        LatLng(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
        ),
        LatLng(
          widget.proximoWaypoint!.latitud!,
          widget.proximoWaypoint!.longitud!,
        ),
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

  void _centerOnCurrentPosition() {
    if (widget.currentPosition == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        _mapController.move(
          LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          15.0, // Zoom level
        );
      } catch (e) {
        print('⚠️ Error al centrar mapa: $e');
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
            initialZoom: 15.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Capa de tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'bo.edu.ucb.sumajflow',
            ),

            // Ruta al próximo waypoint
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: _routeError ? 3 : 5,
                    color: theme.colorScheme.primary,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                    isDotted: _routeError,
                  ),
                ],
              ),

            // Marcadores
            MarkerLayer(
              markers: [
                // Marcador de posición actual (usuario)
                Marker(
                  point: currentLatLng,
                  width: 50,
                  height: 50,
                  child: _buildCurrentPositionMarker(theme),
                ),

                // Marcador del próximo waypoint
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

        // Indicador de carga de ruta
        if (_isLoadingRoute)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
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

        // Advertencia de ruta aproximada
        if (_routeError && !_isLoadingRoute)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.95),
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

        // Botón para centrar en posición actual
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: _centerOnCurrentPosition,
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
        // Círculo de precisión
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
        // Indicador de dirección
        Transform.rotate(
          angle: heading * (math.pi / 180),
          child: Icon(
            Icons.navigation_rounded,
            color: theme.colorScheme.primary,
            size: 32,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
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
              ).withOpacity(0.4),
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
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
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
