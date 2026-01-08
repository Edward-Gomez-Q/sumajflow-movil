// lib/presentation/widgets/mapa_ruta_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/data/services/routing_service.dart';

class MapaRutaWidget extends StatefulWidget {
  final LoteDetalleViajeModel lote;
  final bool mostrarAdvertencia;

  const MapaRutaWidget({
    super.key,
    required this.lote,
    this.mostrarAdvertencia = true,
  });

  @override
  State<MapaRutaWidget> createState() => _MapaRutaWidgetState();
}

class _MapaRutaWidgetState extends State<MapaRutaWidget> {
  List<LatLng>? _rutaCarretera;
  bool _cargandoRuta = true;
  bool _errorRuta = false;

  @override
  void initState() {
    super.initState();
    _cargarRutaCarretera();
  }

  Future<void> _cargarRutaCarretera() async {
    if (!widget.lote.tieneRutaCompleta) {
      setState(() {
        _cargandoRuta = false;
      });
      return;
    }

    final waypoints = widget.lote.waypoints
        .where((w) => w.tieneCoordenadas)
        .map((w) => LatLng(w.latitud!, w.longitud!))
        .toList();

    if (waypoints.length < 2) {
      setState(() {
        _cargandoRuta = false;
      });
      return;
    }

    final ruta = await RoutingService.obtenerRutaPorCarretera(waypoints);

    if (mounted) {
      setState(() {
        _rutaCarretera = ruta;
        _cargandoRuta = false;
        _errorRuta = ruta == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.lote.tieneRutaCompleta) {
      return _buildNoMapaDisponible(context);
    }

    return Stack(
      children: [
        _buildMapa(context),
        if (_cargandoRuta) _buildCargandoRuta(context),
        if (widget.mostrarAdvertencia &&
            (_errorRuta || !widget.lote.rutaCalculadaConExito))
          _buildAdvertenciaDistancia(context),
      ],
    );
  }

  Widget _buildMapa(BuildContext context) {
    final waypoints = widget.lote.waypoints;

    // Calcular el centro y zoom apropiados
    final bounds = LatLngBounds.fromPoints(
      waypoints
          .where((w) => w.tieneCoordenadas)
          .map((w) => LatLng(w.latitud!, w.longitud!))
          .toList(),
    );

    // Determinar qué puntos usar para la línea
    List<LatLng> puntosLinea;
    if (_rutaCarretera != null && _rutaCarretera!.isNotEmpty) {
      puntosLinea = _rutaCarretera!;
    } else {
      // Fallback a línea recta si no hay ruta
      puntosLinea = waypoints
          .where((w) => w.tieneCoordenadas)
          .map((w) => LatLng(w.latitud!, w.longitud!))
          .toList();
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: bounds.center,
        initialZoom: 10,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'bo.edu.ucb.sumajflow',
        ),
        // Línea de la ruta
        PolylineLayer(
          polylines: [
            Polyline(
              points: puntosLinea,
              color: _rutaCarretera != null && !_errorRuta
                  ? Colors.blue
                  : Colors.grey.shade500,
              strokeWidth: _rutaCarretera != null && !_errorRuta ? 4 : 3,
              isDotted: _rutaCarretera == null || _errorRuta,
            ),
          ],
        ),
        // Marcadores de los waypoints
        MarkerLayer(
          markers: waypoints
              .where((w) => w.tieneCoordenadas)
              .map((w) => _buildMarker(context, w))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCargandoRuta(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Calculando ruta por carretera...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildMarker(BuildContext context, WaypointModel waypoint) {
    final color = _parseColor(waypoint.color);

    return Marker(
      point: LatLng(waypoint.latitud!, waypoint.longitud!),
      width: 50,
      height: 70,
      child: GestureDetector(
        onTap: () => _mostrarInfoWaypoint(context, waypoint),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${waypoint.orden}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '${waypoint.orden}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMapaDisponible(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Mapa no disponible', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              'Coordenadas incompletas',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvertenciaDistancia(BuildContext context) {
    final mensaje = _errorRuta
        ? 'No se pudo calcular ruta - mostrando línea recta'
        : 'Distancia en línea recta (estimada)';

    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarInfoWaypoint(BuildContext context, WaypointModel waypoint) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _parseColor(waypoint.color),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      waypoint.iconoEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        waypoint.tituloDescriptivo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        waypoint.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Lat: ${waypoint.latitud?.toStringAsFixed(6) ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Lng: ${waypoint.longitud?.toStringAsFixed(6) ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
