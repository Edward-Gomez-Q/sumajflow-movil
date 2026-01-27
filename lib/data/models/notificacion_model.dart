// lib/data/models/notificacion_model.dart

class NotificacionModel {
  final int id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final bool leido;
  final DateTime fechaCreacion;
  final String time;
  final Map<String, dynamic>? metadata;

  NotificacionModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leido,
    required this.fechaCreacion,
    required this.time,
    this.metadata,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      leido: json['leido'] as bool,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      time: json['time'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'titulo': titulo,
    'mensaje': mensaje,
    'leido': leido,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'time': time,
    'metadata': metadata,
  };

  NotificacionModel copyWith({
    int? id,
    String? tipo,
    String? titulo,
    String? mensaje,
    bool? leido,
    DateTime? fechaCreacion,
    String? time,
    Map<String, dynamic>? metadata,
  }) {
    return NotificacionModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      leido: leido ?? this.leido,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      time: time ?? this.time,
      metadata: metadata ?? this.metadata,
    );
  }
}
