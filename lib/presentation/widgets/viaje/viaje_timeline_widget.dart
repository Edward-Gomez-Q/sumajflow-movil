// lib/presentation/widgets/viaje/viaje_timeline_widget.dart

import 'package:flutter/material.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/data/models/observacion_models.dart';

/// Widget que muestra el timeline de eventos del viaje
class ViajeTimelineWidget extends StatelessWidget {
  final List<EventoViaje> eventos;
  final bool compacto;
  final VoidCallback? onVerEvidencias;

  const ViajeTimelineWidget({
    super.key,
    required this.eventos,
    this.compacto = false,
    this.onVerEvidencias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (eventos.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Historial del viaje',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${eventos.length} eventos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Timeline
        ...eventos.asMap().entries.map((entry) {
          final index = entry.key;
          final evento = entry.value;
          final esUltimo = index == eventos.length - 1;

          return _buildTimelineItem(
            theme,
            evento: evento,
            esUltimo: esUltimo,
            index: index,
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme, {
    required EventoViaje evento,
    required bool esUltimo,
    required int index,
  }) {
    final color = _getColorEvento(evento.tipo);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea vertical y punto
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Punto del evento
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Línea
                if (!esUltimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.5),
                            color.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Contenido del evento
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: esUltimo ? 0 : 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del evento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          evento.tipo.titulo,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        evento.horaFormateada,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Comentario si existe
                  if (evento.tieneComentario) ...[
                    const SizedBox(height: 8),
                    Text(
                      evento.comentario!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],

                  // Datos de pesaje si existen
                  if (evento.datosPesaje != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildPesoMini(
                            theme,
                            label: 'Bruto',
                            valor: evento.datosPesaje!.pesoBruto,
                          ),
                          _buildPesoMini(
                            theme,
                            label: 'Tara',
                            valor: evento.datosPesaje!.pesoTara,
                          ),
                          _buildPesoMini(
                            theme,
                            label: 'Neto',
                            valor: evento.datosPesaje!.pesoNeto,
                            destacado: true,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Evidencias si existen
                  if (evento.tieneEvidencias && !compacto) ...[
                    const SizedBox(height: 10),
                    _buildEvidenciasPreview(theme, evento.evidencias),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesoMini(
    ThemeData theme, {
    required String label,
    required double valor,
    bool destacado = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${valor.toStringAsFixed(0)} kg',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: destacado ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenciasPreview(ThemeData theme, List<String> evidencias) {
    return Row(
      children: [
        Icon(
          Icons.photo_library_rounded,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '${evidencias.length} foto${evidencias.length > 1 ? 's' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (onVerEvidencias != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onVerEvidencias,
            child: Text(
              'Ver',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_rounded,
            size: 40,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin eventos registrados',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Los eventos aparecerán aquí conforme avance el viaje',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColorEvento(TipoEvento tipo) {
    switch (tipo) {
      case TipoEvento.inicioViaje:
        return const Color(0xFF3B82F6); // Blue
      case TipoEvento.llegadaMina:
        return const Color(0xFF8B5CF6); // Purple
      case TipoEvento.inicioCarguio:
        return const Color(0xFFF97316); // Orange
      case TipoEvento.finCarguio:
        return const Color(0xFF10B981); // Green
      case TipoEvento.salidaMina:
        return const Color(0xFF3B82F6); // Blue
      case TipoEvento.llegadaBalanzaCoop:
      case TipoEvento.llegadaBalanzaDestino:
        return const Color(0xFF06B6D4); // Cyan
      case TipoEvento.pesajeBalanzaCoop:
      case TipoEvento.pesajeBalanzaDestino:
        return const Color(0xFF06B6D4); // Cyan
      case TipoEvento.llegadaAlmacen:
        return const Color(0xFFEC4899); // Pink
      case TipoEvento.finDescarga:
        return const Color(0xFF10B981); // Green
    }
  }
}
