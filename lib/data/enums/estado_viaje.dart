// lib/data/enums/estado_viaje.dart

import 'package:flutter/material.dart';

/// Estados del viaje sincronizados con el backend
/// Representa el flujo completo de 8 pasos del transporte
enum EstadoViaje {
  // PASO 1: Estado inicial
  esperandoIniciar('Esperando iniciar', 0.0),

  // PASO 2: En ruta hacia la mina
  enCaminoMina('En camino a la mina', 0.125),

  // PASO 3: Llegó a la mina, esperando carguío
  esperandoCarguio('Esperando carguío', 0.25),

  // PASO 4: En ruta a balanza cooperativa
  enCaminoBalanzaCoop('En camino balanza cooperativa', 0.375),

  // PASO 5: En ruta a balanza destino
  enCaminoBalanzaDestino('En camino balanza destino', 0.5),

  // PASO 6: En ruta a almacén destino
  enCaminoAlmacenDestino('En camino almacén destino', 0.625),

  // PASO 7: Descargando en almacén
  descargando('Descargando', 0.75),

  // PASO 8: Viaje completado
  completado('Completado', 1.0);

  final String valor;
  final double progreso;

  const EstadoViaje(this.valor, this.progreso);

  /// Convierte string del backend a enum
  static EstadoViaje fromString(String estado) {
    switch (estado) {
      case 'Esperando iniciar':
        return EstadoViaje.esperandoIniciar;
      case 'En camino a la mina':
        return EstadoViaje.enCaminoMina;
      case 'Esperando carguío':
        return EstadoViaje.esperandoCarguio;
      case 'En camino balanza cooperativa':
        return EstadoViaje.enCaminoBalanzaCoop;
      case 'En camino balanza destino':
        return EstadoViaje.enCaminoBalanzaDestino;
      case 'En camino almacén destino':
        return EstadoViaje.enCaminoAlmacenDestino;
      case 'Descargando':
        return EstadoViaje.descargando;
      case 'Completado':
        return EstadoViaje.completado;
      default:
        throw Exception('Estado no reconocido: $estado');
    }
  }

  /// Nombre para mostrar en UI
  String get displayName {
    switch (this) {
      case EstadoViaje.esperandoIniciar:
        return 'Listo para iniciar';
      case EstadoViaje.enCaminoMina:
        return 'En camino a mina';
      case EstadoViaje.esperandoCarguio:
        return 'Esperando carguío';
      case EstadoViaje.enCaminoBalanzaCoop:
        return 'Hacia balanza cooperativa';
      case EstadoViaje.enCaminoBalanzaDestino:
        return 'Hacia balanza destino';
      case EstadoViaje.enCaminoAlmacenDestino:
        return 'Hacia almacén';
      case EstadoViaje.descargando:
        return 'Descargando';
      case EstadoViaje.completado:
        return 'Completado';
    }
  }

  /// Emoji representativo
  String get emoji {
    switch (this) {
      case EstadoViaje.esperandoIniciar:
        return '🚦';
      case EstadoViaje.enCaminoMina:
        return '🚛';
      case EstadoViaje.esperandoCarguio:
        return '⏳';
      case EstadoViaje.enCaminoBalanzaCoop:
        return '🚚';
      case EstadoViaje.enCaminoBalanzaDestino:
        return '🚚';
      case EstadoViaje.enCaminoAlmacenDestino:
        return '🚚';
      case EstadoViaje.descargando:
        return '📦';
      case EstadoViaje.completado:
        return '✅';
    }
  }

  /// Color principal del estado
  Color get color {
    switch (this) {
      case EstadoViaje.esperandoIniciar:
        return const Color(0xFF3B82F6); // Azul
      case EstadoViaje.enCaminoMina:
        return const Color(0xFF8B5CF6); // Morado
      case EstadoViaje.esperandoCarguio:
        return const Color(0xFFF59E0B); // Amarillo
      case EstadoViaje.enCaminoBalanzaCoop:
        return const Color(0xFF06B6D4); // Cyan
      case EstadoViaje.enCaminoBalanzaDestino:
        return const Color(0xFF06B6D4); // Cyan
      case EstadoViaje.enCaminoAlmacenDestino:
        return const Color(0xFF10B981); // Verde
      case EstadoViaje.descargando:
        return const Color(0xFFEC4899); // Rosa
      case EstadoViaje.completado:
        return const Color(0xFF10B981); // Verde
    }
  }

  /// Indica si el estado es de movimiento/en camino
  bool get esEstadoEnCamino {
    return this == EstadoViaje.enCaminoMina ||
        this == EstadoViaje.enCaminoBalanzaCoop ||
        this == EstadoViaje.enCaminoBalanzaDestino ||
        this == EstadoViaje.enCaminoAlmacenDestino;
  }

  /// Indica si requiere estar dentro del geofence para continuar
  bool get requiereGeofence {
    return esEstadoEnCamino;
  }

  /// Indica si el viaje está activo
  bool get viajeActivo {
    return this != EstadoViaje.esperandoIniciar &&
        this != EstadoViaje.completado;
  }

  /// Indica si el estado requiere evidencias fotográficas
  bool get requiereEvidencia {
    return this == EstadoViaje.esperandoCarguio ||
        this == EstadoViaje.descargando;
  }

  /// Indica si el estado requiere datos de pesaje
  bool get requierePesaje {
    return this == EstadoViaje.enCaminoBalanzaCoop ||
        this == EstadoViaje.enCaminoBalanzaDestino;
  }
}
