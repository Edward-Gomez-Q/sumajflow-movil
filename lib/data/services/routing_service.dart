// lib/data/services/routing_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1';

  /// Obtiene una ruta siguiendo carreteras entre múltiples waypoints
  /// Returns null si hay error
  static Future<List<LatLng>?> obtenerRutaPorCarretera(
    List<LatLng> waypoints,
  ) async {
    if (waypoints.length < 2) {
      return waypoints;
    }

    try {
      // Construir la URL con todos los waypoints
      final coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final url = Uri.parse(
        '$_osrmBaseUrl/driving/$coordinates'
        '?overview=full&geometries=geojson&steps=false',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          // Convertir las coordenadas a LatLng
          return coordinates.map((coord) {
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();
        }
      }

      return null;
    } catch (e) {
      print('Error al obtener ruta: $e');
      return null;
    }
  }
}
