// lib/data/models/viaje_models.dart

/// Modelo para la respuesta al iniciar un viaje
class TransicionEstadoResponse {
  final bool success;
  final String message;
  final String estadoAnterior;
  final String estadoNuevo;
  final String proximoPaso;
  final ProximoPuntoControl? proximoPuntoControl;

  TransicionEstadoResponse({
    required this.success,
    required this.message,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.proximoPaso,
    this.proximoPuntoControl,
  });

  factory TransicionEstadoResponse.fromJson(Map<String, dynamic> json) {
    return TransicionEstadoResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      estadoAnterior: json['estadoAnterior'] ?? '',
      estadoNuevo: json['estadoNuevo'] ?? '',
      proximoPaso: json['proximoPaso'] ?? '',
      proximoPuntoControl: json['proximoPuntoControl'] != null
          ? ProximoPuntoControl.fromJson(json['proximoPuntoControl'])
          : null,
    );
  }
}

/// Modelo para el próximo punto de control
class ProximoPuntoControl {
  final String tipo;
  final String nombre;
  final double latitud;
  final double longitud;

  ProximoPuntoControl({
    required this.tipo,
    required this.nombre,
    required this.latitud,
    required this.longitud,
  });

  factory ProximoPuntoControl.fromJson(Map<String, dynamic> json) {
    return ProximoPuntoControl(
      tipo: json['tipo'] ?? '',
      nombre: json['nombre'] ?? '',
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
    );
  }
}
