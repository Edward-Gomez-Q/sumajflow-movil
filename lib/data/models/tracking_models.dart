// lib/data/models/tracking_models.dart

class TrackingModel {
  final String? id;
  final int asignacionCamionId;
  final int loteId;
  final int transportistaId;
  final String? codigoLote;
  final String? placaVehiculo;
  final String? nombreTransportista;
  final UbicacionModel? ubicacionActual;
  final String estadoViaje;
  final String estadoConexion;
  final DateTime? ultimaSincronizacion;
  final List<PuntoControlModel> puntosControl;
  final MetricasViajeModel? metricas;
  final GeofencingStatusModel? geofencingStatus;

  TrackingModel({
    this.id,
    required this.asignacionCamionId,
    required this.loteId,
    required this.transportistaId,
    this.codigoLote,
    this.placaVehiculo,
    this.nombreTransportista,
    this.ubicacionActual,
    required this.estadoViaje,
    this.estadoConexion = 'online',
    this.ultimaSincronizacion,
    this.puntosControl = const [],
    this.metricas,
    this.geofencingStatus,
  });

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    return TrackingModel(
      id: json['id'],
      asignacionCamionId: json['asignacionCamionId'],
      loteId: json['loteId'],
      transportistaId: json['transportistaId'],
      codigoLote: json['codigoLote'],
      placaVehiculo: json['placaVehiculo'],
      nombreTransportista: json['nombreTransportista'],
      ubicacionActual: json['ubicacionActual'] != null
          ? UbicacionModel.fromJson(json['ubicacionActual'])
          : null,
      estadoViaje: json['estadoViaje'] ?? 'Desconocido',
      estadoConexion: json['estadoConexion'] ?? 'online',
      ultimaSincronizacion: json['ultimaSincronizacion'] != null
          ? DateTime.parse(json['ultimaSincronizacion'])
          : null,
      puntosControl:
          (json['puntosControl'] as List<dynamic>?)
              ?.map((p) => PuntoControlModel.fromJson(p))
              .toList() ??
          [],
      metricas: json['metricas'] != null
          ? MetricasViajeModel.fromJson(json['metricas'])
          : null,
      geofencingStatus: json['geofencingStatus'] != null
          ? GeofencingStatusModel.fromJson(json['geofencingStatus'])
          : null,
    );
  }
}

/// Modelo para ubicación
class UbicacionModel {
  final double lat;
  final double lng;
  final DateTime? timestamp;
  final double? precision;
  final double? velocidad;
  final double? rumbo;
  final double? altitud;

  UbicacionModel({
    required this.lat,
    required this.lng,
    this.timestamp,
    this.precision,
    this.velocidad,
    this.rumbo,
    this.altitud,
  });

  factory UbicacionModel.fromJson(Map<String, dynamic> json) {
    return UbicacionModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      precision: (json['precision'] as num?)?.toDouble(),
      velocidad: (json['velocidad'] as num?)?.toDouble(),
      rumbo: (json['rumbo'] as num?)?.toDouble(),
      altitud: (json['altitud'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'timestamp': timestamp?.toIso8601String(),
    'precision': precision,
    'velocidad': velocidad,
    'rumbo': rumbo,
    'altitud': altitud,
  };
}

/// Modelo para punto de control
class PuntoControlModel {
  final String tipo;
  final String nombre;
  final double lat;
  final double lng;
  final int radio;
  final int orden;
  final bool requerido;
  final DateTime? llegada;
  final DateTime? salida;
  final String estado;
  final double? distanciaActual;

  PuntoControlModel({
    required this.tipo,
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.radio,
    required this.orden,
    this.requerido = true,
    this.llegada,
    this.salida,
    this.estado = 'pendiente',
    this.distanciaActual,
  });

  factory PuntoControlModel.fromJson(Map<String, dynamic> json) {
    return PuntoControlModel(
      tipo: json['tipo'],
      nombre: json['nombre'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radio: json['radio'] ?? 100,
      orden: json['orden'] ?? 0,
      requerido: json['requerido'] ?? true,
      llegada: json['llegada'] != null ? DateTime.parse(json['llegada']) : null,
      salida: json['salida'] != null ? DateTime.parse(json['salida']) : null,
      estado: json['estado'] ?? 'pendiente',
      distanciaActual: (json['distanciaActual'] as num?)?.toDouble(),
    );
  }

  bool get estaCompletado => estado == 'completado';
  bool get estaEnPunto => estado == 'en_punto';
  bool get estaPendiente => estado == 'pendiente';
}

/// Modelo para métricas del viaje
class MetricasViajeModel {
  final double distanciaRecorrida;
  final int tiempoEnMovimiento;
  final int tiempoDetenido;
  final double velocidadPromedio;
  final double velocidadMaxima;
  final DateTime? inicioViaje;
  final DateTime? finViaje;
  final String? tiempoTranscurrido;

  MetricasViajeModel({
    this.distanciaRecorrida = 0,
    this.tiempoEnMovimiento = 0,
    this.tiempoDetenido = 0,
    this.velocidadPromedio = 0,
    this.velocidadMaxima = 0,
    this.inicioViaje,
    this.finViaje,
    this.tiempoTranscurrido,
  });

  factory MetricasViajeModel.fromJson(Map<String, dynamic> json) {
    return MetricasViajeModel(
      distanciaRecorrida: (json['distanciaRecorrida'] as num?)?.toDouble() ?? 0,
      tiempoEnMovimiento: json['tiempoEnMovimiento'] ?? 0,
      tiempoDetenido: json['tiempoDetenido'] ?? 0,
      velocidadPromedio: (json['velocidadPromedio'] as num?)?.toDouble() ?? 0,
      velocidadMaxima: (json['velocidadMaxima'] as num?)?.toDouble() ?? 0,
      inicioViaje: json['inicioViaje'] != null
          ? DateTime.parse(json['inicioViaje'])
          : null,
      finViaje: json['finViaje'] != null
          ? DateTime.parse(json['finViaje'])
          : null,
      tiempoTranscurrido: json['tiempoTranscurrido'],
    );
  }

  int get tiempoTotal => tiempoEnMovimiento + tiempoDetenido;
}

/// Modelo para estado de geofencing
class GeofencingStatusModel {
  final bool dentroDeZona;
  final String? zonaNombre;
  final String? zonaTipo;
  final double? distanciaAZona;
  final bool puedeRegistrarLlegada;
  final bool puedeRegistrarSalida;
  final String? proximoPuntoControl;
  final double? distanciaProximoPunto;

  GeofencingStatusModel({
    this.dentroDeZona = false,
    this.zonaNombre,
    this.zonaTipo,
    this.distanciaAZona,
    this.puedeRegistrarLlegada = false,
    this.puedeRegistrarSalida = false,
    this.proximoPuntoControl,
    this.distanciaProximoPunto,
  });

  factory GeofencingStatusModel.fromJson(Map<String, dynamic> json) {
    return GeofencingStatusModel(
      dentroDeZona: json['dentroDeZona'] ?? false,
      zonaNombre: json['zonaNombre'],
      zonaTipo: json['zonaTipo'],
      distanciaAZona: (json['distanciaAZona'] as num?)?.toDouble(),
      puedeRegistrarLlegada: json['puedeRegistrarLlegada'] ?? false,
      puedeRegistrarSalida: json['puedeRegistrarSalida'] ?? false,
      proximoPuntoControl: json['proximoPuntoControl'],
      distanciaProximoPunto: (json['distanciaProximoPunto'] as num?)
          ?.toDouble(),
    );
  }

  bool get requiereAccion => puedeRegistrarLlegada || puedeRegistrarSalida;
}

/// Modelo para respuesta de actualización de ubicación
class ActualizacionUbicacionResponse {
  final bool success;
  final String? mensaje;
  final UbicacionModel? ubicacionRegistrada;
  final GeofencingStatusModel? geofencingStatus;
  final String? nuevoEstadoViaje;
  final bool requiereAccion;
  final String? accionRequerida;

  ActualizacionUbicacionResponse({
    required this.success,
    this.mensaje,
    this.ubicacionRegistrada,
    this.geofencingStatus,
    this.nuevoEstadoViaje,
    this.requiereAccion = false,
    this.accionRequerida,
  });

  factory ActualizacionUbicacionResponse.fromJson(Map<String, dynamic> json) {
    return ActualizacionUbicacionResponse(
      success: json['success'] ?? false,
      mensaje: json['mensaje'],
      ubicacionRegistrada: json['ubicacionRegistrada'] != null
          ? UbicacionModel.fromJson(json['ubicacionRegistrada'])
          : null,
      geofencingStatus: json['geofencingStatus'] != null
          ? GeofencingStatusModel.fromJson(json['geofencingStatus'])
          : null,
      nuevoEstadoViaje: json['nuevoEstadoViaje'],
      requiereAccion: json['requiereAccion'] ?? false,
      accionRequerida: json['accionRequerida'],
    );
  }
}

/// Modelo para ubicaciones offline
class UbicacionOfflineModel {
  final double lat;
  final double lng;
  final DateTime timestamp;
  final double? precision;
  final double? velocidad;
  final double? rumbo;
  final double? altitud;
  bool sincronizado;

  UbicacionOfflineModel({
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.precision,
    this.velocidad,
    this.rumbo,
    this.altitud,
    this.sincronizado = false,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'timestamp': timestamp.toIso8601String(),
    'precision': precision,
    'velocidad': velocidad,
    'rumbo': rumbo,
    'altitud': altitud,
  };

  factory UbicacionOfflineModel.fromJson(Map<String, dynamic> json) {
    return UbicacionOfflineModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      precision: (json['precision'] as num?)?.toDouble(),
      velocidad: (json['velocidad'] as num?)?.toDouble(),
      rumbo: (json['rumbo'] as num?)?.toDouble(),
      altitud: (json['altitud'] as num?)?.toDouble(),
      sincronizado: json['sincronizado'] ?? false,
    );
  }
}
