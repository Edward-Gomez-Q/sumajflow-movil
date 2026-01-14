// lib/data/models/lote_models.dart

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
  final String? destinoNombre; //   Agregado
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
    this.destinoNombre, //   Agregado
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
      destinoNombre: json['destinoNombre'], //   Agregado
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

  bool get estaActivo =>
      estado != 'Completado' && estado != 'Cancelado por rechazo';

  bool get estaPendienteIniciar => estado == 'Esperando iniciar';

  bool get estaEnCurso => estaActivo && !estaPendienteIniciar;

  bool get estaCompletado => estado == 'Completado';

  String get estadoDisplay {
    switch (estado) {
      case 'Esperando iniciar':
        return 'Pendiente';
      case 'Completado':
        return 'Completado';
      case 'En camino a la mina':
      case 'En camino balanza cooperativa':
      case 'En camino balanza destino':
      case 'En camino almacén destino':
        return 'En Tránsito';
      case 'Esperando carguío':
        return 'Esperando Carga';
      case 'Descargando':
        return 'Descargando';
      default:
        return estado;
    }
  }
}

// ... resto de los modelos (WaypointModel, LoteDetalleViajeModel) se mantienen igual
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
