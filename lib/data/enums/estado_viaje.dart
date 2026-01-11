// lib/data/enums/estado_viaje.dart

/// Estados posibles de un viaje/asignación de camión
enum EstadoViaje {
  esperandoIniciar('Esperando iniciar'),
  enCaminoMina('En camino a la mina'),
  esperandoCarguio('Esperando carguío'),
  cargandoMineral('Cargando mineral'),
  carguioCompletado('Carguío completado'),
  enCaminoBalanzaCoop('En camino balanza cooperativa'),
  pesajeBalanzaCoop('Pesaje balanza cooperativa'),
  enCaminoBalanzaDestino('En camino balanza destino'),
  pesajeBalanzaDestino('Pesaje balanza destino'),
  rutaCompletada('Ruta completada'),
  descargando('Descargando'),
  completado('Completado'),
  cancelado('Cancelado por rechazo');

  final String valor;
  const EstadoViaje(this.valor);

  /// Obtiene el estado desde un string del backend
  static EstadoViaje fromString(String valor) {
    return EstadoViaje.values.firstWhere(
      (e) => e.valor.toLowerCase() == valor.toLowerCase(),
      orElse: () => EstadoViaje.esperandoIniciar,
    );
  }

  /// Verifica si es un estado de "en camino"
  bool get esEnCamino => [
    EstadoViaje.enCaminoMina,
    EstadoViaje.enCaminoBalanzaCoop,
    EstadoViaje.enCaminoBalanzaDestino,
  ].contains(this);

  /// Verifica si es un estado de pesaje
  bool get esPesaje => [
    EstadoViaje.pesajeBalanzaCoop,
    EstadoViaje.pesajeBalanzaDestino,
  ].contains(this);

  /// Verifica si el viaje está activo (no completado ni cancelado)
  bool get estaActivo =>
      ![EstadoViaje.completado, EstadoViaje.cancelado].contains(this);

  /// Obtiene el color asociado al estado (hex)
  String get colorHex {
    switch (this) {
      case EstadoViaje.esperandoIniciar:
        return '#F59E0B'; // Amber
      case EstadoViaje.enCaminoMina:
      case EstadoViaje.enCaminoBalanzaCoop:
      case EstadoViaje.enCaminoBalanzaDestino:
        return '#3B82F6'; // Blue
      case EstadoViaje.esperandoCarguio:
        return '#8B5CF6'; // Purple
      case EstadoViaje.cargandoMineral:
        return '#F97316'; // Orange
      case EstadoViaje.carguioCompletado:
        return '#10B981'; // Green
      case EstadoViaje.pesajeBalanzaCoop:
      case EstadoViaje.pesajeBalanzaDestino:
        return '#06B6D4'; // Cyan
      case EstadoViaje.rutaCompletada:
        return '#8B5CF6'; // Purple
      case EstadoViaje.descargando:
        return '#EC4899'; // Pink
      case EstadoViaje.completado:
        return '#10B981'; // Green
      case EstadoViaje.cancelado:
        return '#EF4444'; // Red
    }
  }

  /// Obtiene el emoji/icono asociado
  String get emoji {
    switch (this) {
      case EstadoViaje.esperandoIniciar:
        return '🚀';
      case EstadoViaje.enCaminoMina:
        return '🚛';
      case EstadoViaje.esperandoCarguio:
        return '⏳';
      case EstadoViaje.cargandoMineral:
        return '⛏️';
      case EstadoViaje.carguioCompletado:
        return '✅';
      case EstadoViaje.enCaminoBalanzaCoop:
      case EstadoViaje.enCaminoBalanzaDestino:
        return '🚛';
      case EstadoViaje.pesajeBalanzaCoop:
      case EstadoViaje.pesajeBalanzaDestino:
        return '⚖️';
      case EstadoViaje.rutaCompletada:
        return '🎯';
      case EstadoViaje.descargando:
        return '📦';
      case EstadoViaje.completado:
        return '🏆';
      case EstadoViaje.cancelado:
        return '❌';
    }
  }

  /// Obtiene el texto corto para mostrar en chips/badges
  String get textoCorto {
    switch (this) {
      case EstadoViaje.esperandoIniciar:
        return 'Pendiente';
      case EstadoViaje.enCaminoMina:
        return 'A la mina';
      case EstadoViaje.esperandoCarguio:
        return 'En turno';
      case EstadoViaje.cargandoMineral:
        return 'Cargando';
      case EstadoViaje.carguioCompletado:
        return 'Cargado';
      case EstadoViaje.enCaminoBalanzaCoop:
        return 'A balanza coop';
      case EstadoViaje.pesajeBalanzaCoop:
        return 'Pesaje coop';
      case EstadoViaje.enCaminoBalanzaDestino:
        return 'A balanza dest';
      case EstadoViaje.pesajeBalanzaDestino:
        return 'Pesaje dest';
      case EstadoViaje.rutaCompletada:
        return 'En destino';
      case EstadoViaje.descargando:
        return 'Descargando';
      case EstadoViaje.completado:
        return 'Completado';
      case EstadoViaje.cancelado:
        return 'Cancelado';
    }
  }

  /// Obtiene el siguiente estado esperado
  EstadoViaje? get siguienteEstado {
    switch (this) {
      case EstadoViaje.esperandoIniciar:
        return EstadoViaje.enCaminoMina;
      case EstadoViaje.enCaminoMina:
        return EstadoViaje.esperandoCarguio;
      case EstadoViaje.esperandoCarguio:
        return EstadoViaje.cargandoMineral;
      case EstadoViaje.cargandoMineral:
        return EstadoViaje.carguioCompletado;
      case EstadoViaje.carguioCompletado:
        return EstadoViaje.enCaminoBalanzaCoop;
      case EstadoViaje.enCaminoBalanzaCoop:
        return EstadoViaje.pesajeBalanzaCoop;
      case EstadoViaje.pesajeBalanzaCoop:
        return EstadoViaje.enCaminoBalanzaDestino;
      case EstadoViaje.enCaminoBalanzaDestino:
        return EstadoViaje.pesajeBalanzaDestino;
      case EstadoViaje.pesajeBalanzaDestino:
        return EstadoViaje.rutaCompletada;
      case EstadoViaje.rutaCompletada:
        return EstadoViaje.descargando;
      case EstadoViaje.descargando:
        return EstadoViaje.completado;
      case EstadoViaje.completado:
      case EstadoViaje.cancelado:
        return null;
    }
  }

  /// Obtiene el progreso del viaje (0.0 a 1.0)
  double get progreso {
    switch (this) {
      case EstadoViaje.esperandoIniciar:
        return 0.0;
      case EstadoViaje.enCaminoMina:
        return 0.08;
      case EstadoViaje.esperandoCarguio:
        return 0.17;
      case EstadoViaje.cargandoMineral:
        return 0.25;
      case EstadoViaje.carguioCompletado:
        return 0.33;
      case EstadoViaje.enCaminoBalanzaCoop:
        return 0.42;
      case EstadoViaje.pesajeBalanzaCoop:
        return 0.50;
      case EstadoViaje.enCaminoBalanzaDestino:
        return 0.58;
      case EstadoViaje.pesajeBalanzaDestino:
        return 0.67;
      case EstadoViaje.rutaCompletada:
        return 0.75;
      case EstadoViaje.descargando:
        return 0.92;
      case EstadoViaje.completado:
        return 1.0;
      case EstadoViaje.cancelado:
        return 0.0;
    }
  }
}

/// Tipos de eventos que se pueden registrar
enum TipoEvento {
  inicioViaje('inicio_viaje'),
  llegadaMina('llegada_mina'),
  inicioCarguio('inicio_carguio'),
  finCarguio('fin_carguio'),
  salidaMina('salida_mina'),
  llegadaBalanzaCoop('llegada_balanza_coop'),
  pesajeBalanzaCoop('pesaje_balanza_coop'),
  llegadaBalanzaDestino('llegada_balanza_destino'),
  pesajeBalanzaDestino('pesaje_balanza_destino'),
  llegadaAlmacen('llegada_almacen'),
  finDescarga('fin_descarga');

  final String valor;
  const TipoEvento(this.valor);

  static TipoEvento fromString(String valor) {
    return TipoEvento.values.firstWhere(
      (e) => e.valor == valor,
      orElse: () => TipoEvento.inicioViaje,
    );
  }

  /// Indica si este evento requiere evidencia fotográfica obligatoria
  bool get requiereEvidencia => [
    TipoEvento.finCarguio,
    TipoEvento.pesajeBalanzaCoop,
    TipoEvento.pesajeBalanzaDestino,
    TipoEvento.finDescarga,
  ].contains(this);

  /// Obtiene el título legible del evento
  String get titulo {
    switch (this) {
      case TipoEvento.inicioViaje:
        return 'Inicio de viaje';
      case TipoEvento.llegadaMina:
        return 'Llegada a mina';
      case TipoEvento.inicioCarguio:
        return 'Inicio de carguío';
      case TipoEvento.finCarguio:
        return 'Fin de carguío';
      case TipoEvento.salidaMina:
        return 'Salida de mina';
      case TipoEvento.llegadaBalanzaCoop:
        return 'Llegada a balanza cooperativa';
      case TipoEvento.pesajeBalanzaCoop:
        return 'Pesaje en balanza cooperativa';
      case TipoEvento.llegadaBalanzaDestino:
        return 'Llegada a balanza destino';
      case TipoEvento.pesajeBalanzaDestino:
        return 'Pesaje en balanza destino';
      case TipoEvento.llegadaAlmacen:
        return 'Llegada a almacén';
      case TipoEvento.finDescarga:
        return 'Fin de descarga';
    }
  }
}
