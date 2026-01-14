// lib/data/models/accion_offline_model.dart

class AccionOfflineModel {
  final String id;
  final String tipo;
  final int asignacionId;
  final Map<String, dynamic> datos;
  final DateTime timestamp;
  final bool sincronizado;
  final int intentos;

  AccionOfflineModel({
    String? id,
    required this.tipo,
    required this.asignacionId,
    required this.datos,
    required this.timestamp,
    this.sincronizado = false,
    this.intentos = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'asignacionId': asignacionId,
    'datos': datos,
    'timestamp': timestamp.toIso8601String(),
    'sincronizado': sincronizado,
    'intentos': intentos,
  };

  factory AccionOfflineModel.fromJson(Map<String, dynamic> json) =>
      AccionOfflineModel(
        id: json['id'],
        tipo: json['tipo'],
        asignacionId: json['asignacionId'],
        datos: Map<String, dynamic>.from(json['datos']),
        timestamp: DateTime.parse(json['timestamp']),
        sincronizado: json['sincronizado'] ?? false,
        intentos: json['intentos'] ?? 0,
      );

  AccionOfflineModel copyWith({
    String? id,
    String? tipo,
    int? asignacionId,
    Map<String, dynamic>? datos,
    DateTime? timestamp,
    bool? sincronizado,
    int? intentos,
  }) {
    return AccionOfflineModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      asignacionId: asignacionId ?? this.asignacionId,
      datos: datos ?? this.datos,
      timestamp: timestamp ?? this.timestamp,
      sincronizado: sincronizado ?? this.sincronizado,
      intentos: intentos ?? this.intentos,
    );
  }
}
