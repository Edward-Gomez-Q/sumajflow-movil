// lib/data/models/observacion_models.dart

import 'package:sumajflow_movil/data/enums/estado_viaje.dart';

/// Modelo de ubicación GPS
class UbicacionGPS {
  final double lat;
  final double lng;
  final double? precision;
  final double? altitud;

  UbicacionGPS({
    required this.lat,
    required this.lng,
    this.precision,
    this.altitud,
  });

  factory UbicacionGPS.fromJson(Map<String, dynamic> json) {
    return UbicacionGPS(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      precision: json['precision'] != null
          ? (json['precision'] as num).toDouble()
          : null,
      altitud: json['altitud'] != null
          ? (json['altitud'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    if (precision != null) 'precision': precision,
    if (altitud != null) 'altitud': altitud,
  };

  @override
  String toString() => 'UbicacionGPS($lat, $lng)';
}

/// Modelo de datos de pesaje
class DatosPesaje {
  final double pesoBruto;
  final double pesoTara;
  final double pesoNeto;
  final String? numeroTicket;
  final String? observacionesBalanza;

  DatosPesaje({
    required this.pesoBruto,
    required this.pesoTara,
    required this.pesoNeto,
    this.numeroTicket,
    this.observacionesBalanza,
  });

  factory DatosPesaje.fromJson(Map<String, dynamic> json) {
    return DatosPesaje(
      pesoBruto: (json['peso_bruto'] as num).toDouble(),
      pesoTara: (json['peso_tara'] as num).toDouble(),
      pesoNeto: (json['peso_neto'] as num).toDouble(),
      numeroTicket: json['numero_ticket'] as String?,
      observacionesBalanza: json['observaciones_balanza'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'peso_bruto': pesoBruto,
    'peso_tara': pesoTara,
    'peso_neto': pesoNeto,
    if (numeroTicket != null) 'numero_ticket': numeroTicket,
    if (observacionesBalanza != null)
      'observaciones_balanza': observacionesBalanza,
  };

  /// Formato legible del peso neto
  String get pesoNetoFormateado => '${pesoNeto.toStringAsFixed(2)} kg';

  /// Formato legible del peso bruto
  String get pesoBrutoFormateado => '${pesoBruto.toStringAsFixed(2)} kg';
}

/// Modelo de un evento/observación del viaje
class EventoViaje {
  final TipoEvento tipo;
  final DateTime timestamp;
  final UbicacionGPS ubicacion;
  final String? comentario;
  final List<String> evidencias;
  final DatosPesaje? datosPesaje;
  final Map<String, dynamic>? metadatosExtra;

  EventoViaje({
    required this.tipo,
    required this.timestamp,
    required this.ubicacion,
    this.comentario,
    this.evidencias = const [],
    this.datosPesaje,
    this.metadatosExtra,
  });

  factory EventoViaje.fromJson(Map<String, dynamic> json) {
    return EventoViaje(
      tipo: TipoEvento.fromString(json['tipo'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      ubicacion: UbicacionGPS.fromJson(
        json['ubicacion'] as Map<String, dynamic>,
      ),
      comentario: json['comentario'] as String?,
      evidencias:
          (json['evidencias'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      datosPesaje: json['datos_pesaje'] != null
          ? DatosPesaje.fromJson(json['datos_pesaje'] as Map<String, dynamic>)
          : null,
      metadatosExtra: json['metadatos_extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'tipo': tipo.valor,
    'timestamp': timestamp.toIso8601String(),
    'ubicacion': ubicacion.toJson(),
    if (comentario != null) 'comentario': comentario,
    'evidencias': evidencias,
    if (datosPesaje != null) 'datos_pesaje': datosPesaje!.toJson(),
    if (metadatosExtra != null) 'metadatos_extra': metadatosExtra,
  };

  /// Verifica si el evento tiene evidencias
  bool get tieneEvidencias => evidencias.isNotEmpty;

  /// Verifica si el evento tiene comentario
  bool get tieneComentario =>
      comentario != null && comentario!.trim().isNotEmpty;

  /// Formato legible de la hora
  String get horaFormateada {
    final hora = timestamp.hour.toString().padLeft(2, '0');
    final minuto = timestamp.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  /// Formato legible de fecha y hora
  String get fechaHoraFormateada {
    final dia = timestamp.day.toString().padLeft(2, '0');
    final mes = timestamp.month.toString().padLeft(2, '0');
    return '$dia/$mes ${horaFormateada}';
  }
}

/// Modelo de metadatos del viaje
class MetadatosViaje {
  final String version;
  final int totalEventos;
  final DateTime ultimoUpdate;

  MetadatosViaje({
    required this.version,
    required this.totalEventos,
    required this.ultimoUpdate,
  });

  factory MetadatosViaje.fromJson(Map<String, dynamic> json) {
    return MetadatosViaje(
      version: json['version'] as String? ?? '1.0',
      totalEventos: json['total_eventos'] as int? ?? 0,
      ultimoUpdate: json['ultimo_update'] != null
          ? DateTime.parse(json['ultimo_update'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'total_eventos': totalEventos,
    'ultimo_update': ultimoUpdate.toIso8601String(),
  };
}

/// Modelo completo de observaciones del viaje (JSONB)
class ObservacionesViaje {
  final List<EventoViaje> eventos;
  final MetadatosViaje metadata;

  ObservacionesViaje({required this.eventos, required this.metadata});

  factory ObservacionesViaje.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ObservacionesViaje.empty();
    }

    return ObservacionesViaje(
      eventos:
          (json['eventos'] as List<dynamic>?)
              ?.map((e) => EventoViaje.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] != null
          ? MetadatosViaje.fromJson(json['metadata'] as Map<String, dynamic>)
          : MetadatosViaje(
              version: '1.0',
              totalEventos: 0,
              ultimoUpdate: DateTime.now(),
            ),
    );
  }

  factory ObservacionesViaje.empty() {
    return ObservacionesViaje(
      eventos: [],
      metadata: MetadatosViaje(
        version: '1.0',
        totalEventos: 0,
        ultimoUpdate: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'eventos': eventos.map((e) => e.toJson()).toList(),
    'metadata': metadata.toJson(),
  };

  /// Obtiene el último evento registrado
  EventoViaje? get ultimoEvento => eventos.isNotEmpty ? eventos.last : null;

  /// Obtiene eventos por tipo
  List<EventoViaje> eventosPorTipo(TipoEvento tipo) {
    return eventos.where((e) => e.tipo == tipo).toList();
  }

  /// Verifica si existe un evento de cierto tipo
  bool tieneEvento(TipoEvento tipo) {
    return eventos.any((e) => e.tipo == tipo);
  }

  /// Obtiene todos los pesajes registrados
  List<EventoViaje> get pesajes {
    return eventos.where((e) => e.datosPesaje != null).toList();
  }

  /// Obtiene todas las evidencias del viaje
  List<String> get todasLasEvidencias {
    return eventos.expand((e) => e.evidencias).toList();
  }
}

/// DTO para crear un nuevo evento
class CrearEventoDTO {
  final TipoEvento tipo;
  final double lat;
  final double lng;
  final String? comentario;
  final List<String>? evidencias;
  final DatosPesaje? datosPesaje;

  CrearEventoDTO({
    required this.tipo,
    required this.lat,
    required this.lng,
    this.comentario,
    this.evidencias,
    this.datosPesaje,
  });

  Map<String, dynamic> toJson() => {
    'tipo': tipo.valor,
    'lat': lat,
    'lng': lng,
    if (comentario != null && comentario!.trim().isNotEmpty)
      'comentario': comentario,
    if (evidencias != null && evidencias!.isNotEmpty) 'evidencias': evidencias,
    if (datosPesaje != null) 'datos_pesaje': datosPesaje!.toJson(),
  };

  /// Valida que el evento tiene los datos requeridos
  String? validar() {
    if (tipo.requiereEvidencia && (evidencias == null || evidencias!.isEmpty)) {
      return 'Este evento requiere al menos una foto como evidencia';
    }
    return null;
  }
}

/// Respuesta del backend al crear un evento
class EventoResponse {
  final bool success;
  final String message;
  final String? estadoAnterior;
  final String estadoNuevo;
  final EventoViaje? evento;

  EventoResponse({
    required this.success,
    required this.message,
    this.estadoAnterior,
    required this.estadoNuevo,
    this.evento,
  });

  factory EventoResponse.fromJson(Map<String, dynamic> json) {
    return EventoResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      estadoAnterior: json['data']?['estado_anterior'] as String?,
      estadoNuevo: json['data']?['estado_nuevo'] as String? ?? '',
      evento: json['data']?['evento'] != null
          ? EventoViaje.fromJson(json['data']['evento'] as Map<String, dynamic>)
          : null,
    );
  }
}
