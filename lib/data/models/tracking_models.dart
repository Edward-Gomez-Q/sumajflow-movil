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

/// Modelo para lote asignado (resumen para lista)
class LoteAsignadoModel {
  final int asignacionId;
  final int loteId;
  final String codigoLote;
  final String minaNombre;
  final String tipoOperacion;
  final String tipoMineral;
  final String estado;
  final int numeroCamion;
  final DateTime? fechaAsignacion;
  final List<String> mineralTags;

  LoteAsignadoModel({
    required this.asignacionId,
    required this.loteId,
    required this.codigoLote,
    required this.minaNombre,
    required this.tipoOperacion,
    required this.tipoMineral,
    required this.estado,
    required this.numeroCamion,
    this.fechaAsignacion,
    this.mineralTags = const [],
  });

  factory LoteAsignadoModel.fromJson(Map<String, dynamic> json) {
    return LoteAsignadoModel(
      asignacionId: json['asignacionId'],
      loteId: json['loteId'],
      codigoLote: json['codigoLote'],
      minaNombre: json['minaNombre'],
      tipoOperacion: json['tipoOperacion'],
      tipoMineral: json['tipoMineral'],
      estado: json['estado'],
      numeroCamion: json['numeroCamion'],
      fechaAsignacion: json['fechaAsignacion'] != null
          ? DateTime.parse(json['fechaAsignacion'])
          : null,
      mineralTags:
          (json['mineralTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool get estaActivo => estado != 'Viaje terminado' && estado != 'Cancelado';

  bool get estaPendienteIniciar =>
      estado == 'Esperando iniciar' || estado == 'asignado';

  bool get estaEnCurso => estaActivo && !estaPendienteIniciar;

  bool get estaCompletado => estado == 'Viaje terminado';

  String get estadoDisplay {
    switch (estado) {
      case 'asignado':
      case 'Esperando iniciar':
        return 'Pendiente';
      case 'Viaje terminado':
        return 'Completado';
      default:
        return estado;
    }
  }
}

/// Modelo para detalle de lote para viaje
class LoteDetalleViajeModel {
  final int asignacionId;
  final int loteId;
  final String codigoLote;
  final String? socioNombre;
  final String? socioTelefono;
  final String minaNombre;
  final double minaLat;
  final double minaLng;
  final String tipoOperacion;
  final String tipoMineral;
  final List<String> mineralTags;
  final String destinoNombre;
  final String destinoTipo;
  final double? distanciaEstimadaKm;
  final double? tiempoEstimadoHoras;
  final bool rutaCalculadaConExito;
  final String metodoCalculo;

  // Waypoints de la ruta
  final WaypointModel? puntoOrigen;
  final WaypointModel? puntoBalanzaCoop;
  final WaypointModel? puntoBalanzaDestino;
  final WaypointModel? puntoAlmacenDestino;

  final String estado;
  final int numeroCamion;
  final int totalCamiones;

  LoteDetalleViajeModel({
    required this.asignacionId,
    required this.loteId,
    required this.codigoLote,
    this.socioNombre,
    this.socioTelefono,
    required this.minaNombre,
    required this.minaLat,
    required this.minaLng,
    required this.tipoOperacion,
    required this.tipoMineral,
    this.mineralTags = const [],
    required this.destinoNombre,
    required this.destinoTipo,
    this.distanciaEstimadaKm,
    this.tiempoEstimadoHoras,
    this.rutaCalculadaConExito = false,
    this.metodoCalculo = 'linea_recta',
    this.puntoOrigen,
    this.puntoBalanzaCoop,
    this.puntoBalanzaDestino,
    this.puntoAlmacenDestino,
    required this.estado,
    required this.numeroCamion,
    required this.totalCamiones,
  });

  factory LoteDetalleViajeModel.fromJson(Map<String, dynamic> json) {
    return LoteDetalleViajeModel(
      asignacionId: json['asignacionId'],
      loteId: json['loteId'],
      codigoLote: json['codigoLote'],
      socioNombre: json['socioNombre'],
      socioTelefono: json['socioTelefono'],
      minaNombre: json['minaNombre'],
      minaLat: (json['minaLat'] as num).toDouble(),
      minaLng: (json['minaLng'] as num).toDouble(),
      tipoOperacion: json['tipoOperacion'],
      tipoMineral: json['tipoMineral'],
      mineralTags:
          (json['mineralTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      destinoNombre: json['destinoNombre'],
      destinoTipo: json['destinoTipo'],
      distanciaEstimadaKm: (json['distanciaEstimadaKm'] as num?)?.toDouble(),
      tiempoEstimadoHoras: (json['tiempoEstimadoHoras'] as num?)?.toDouble(),
      rutaCalculadaConExito: json['rutaCalculadaConExito'] ?? false,
      metodoCalculo: json['metodoCalculo'] ?? 'linea_recta',
      puntoOrigen: json['puntoOrigen'] != null
          ? WaypointModel.fromJson(json['puntoOrigen'])
          : null,
      puntoBalanzaCoop: json['puntoBalanzaCoop'] != null
          ? WaypointModel.fromJson(json['puntoBalanzaCoop'])
          : null,
      puntoBalanzaDestino: json['puntoBalanzaDestino'] != null
          ? WaypointModel.fromJson(json['puntoBalanzaDestino'])
          : null,
      puntoAlmacenDestino: json['puntoAlmacenDestino'] != null
          ? WaypointModel.fromJson(json['puntoAlmacenDestino'])
          : null,
      estado: json['estado'],
      numeroCamion: json['numeroCamion'],
      totalCamiones: json['totalCamiones'],
    );
  }

  String get tiempoEstimadoDisplay {
    if (tiempoEstimadoHoras == null) return 'N/A';
    final horas = tiempoEstimadoHoras!.floor();
    final minutos = ((tiempoEstimadoHoras! - horas) * 60).round();
    if (horas > 0) {
      return '$horas h ${minutos > 0 ? '$minutos min' : ''}';
    }
    return '$minutos min';
  }

  String get distanciaDisplay {
    if (distanciaEstimadaKm == null) return 'N/A';
    return '${distanciaEstimadaKm!.toStringAsFixed(1)} km';
  }

  /// Obtiene todos los waypoints en orden
  List<WaypointModel> get waypoints {
    return [
      if (puntoOrigen != null) puntoOrigen!,
      if (puntoBalanzaCoop != null) puntoBalanzaCoop!,
      if (puntoBalanzaDestino != null) puntoBalanzaDestino!,
      if (puntoAlmacenDestino != null) puntoAlmacenDestino!,
    ];
  }

  /// Verifica si tiene todos los waypoints necesarios
  bool get tieneRutaCompleta {
    return puntoOrigen != null &&
        puntoBalanzaCoop != null &&
        puntoBalanzaDestino != null &&
        puntoAlmacenDestino != null;
  }
}

/// Modelo para un waypoint/punto de la ruta
class WaypointModel {
  final String nombre;
  final String tipo; // "mina", "balanza_coop", "balanza_destino", "almacen"
  final double? latitud;
  final double? longitud;
  final String color; // Color hex para el marcador
  final int orden; // 1, 2, 3, 4

  WaypointModel({
    required this.nombre,
    required this.tipo,
    this.latitud,
    this.longitud,
    required this.color,
    required this.orden,
  });

  factory WaypointModel.fromJson(Map<String, dynamic> json) {
    return WaypointModel(
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      color: json['color'] ?? '#000000',
      orden: json['orden'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'tipo': tipo,
    'latitud': latitud,
    'longitud': longitud,
    'color': color,
    'orden': orden,
  };

  /// Verifica si tiene coordenadas válidas
  bool get tieneCoordenadas => latitud != null && longitud != null;

  /// Obtiene el icono según el tipo
  String get iconoEmoji {
    switch (tipo) {
      case 'mina':
        return '⛏️';
      case 'balanza_coop':
      case 'balanza_destino':
        return '⚖️';
      case 'almacen':
        return '🏭';
      default:
        return '📍';
    }
  }

  /// Obtiene el título descriptivo
  String get tituloDescriptivo {
    switch (tipo) {
      case 'mina':
        return '1. Punto de Partida';
      case 'balanza_coop':
        return '2. Balanza Cooperativa';
      case 'balanza_destino':
        return '3. Balanza Destino';
      case 'almacen':
        return '4. Almacén Final';
      default:
        return '$orden. $nombre';
    }
  }
}

/// Modelo para ubicación offline (para sincronización)
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
