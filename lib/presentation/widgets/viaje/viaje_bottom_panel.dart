// lib/presentation/widgets/viaje/viaje_bottom_panel.dart

import 'package:flutter/material.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';

/// Panel inferior deslizable con información del viaje
class ViajeBottomPanel extends StatelessWidget {
  final EstadoViaje estado;
  final WaypointModel? destino;
  final String distancia;
  final String? codigoLote;
  final double? velocidad;
  final Widget? contenidoExtra;
  final Widget botonAccion;

  const ViajeBottomPanel({
    super.key,
    required this.estado,
    this.destino,
    required this.distancia,
    this.codigoLote,
    this.velocidad,
    this.contenidoExtra,
    required this.botonAccion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorEstado = _hexToColor(estado.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastre
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Destino actual
                  if (destino != null) ...[
                    _buildDestinoCard(theme, colorEstado),
                    const SizedBox(height: 16),
                  ],

                  // Info rápida
                  Row(
                    children: [
                      if (codigoLote != null)
                        Expanded(
                          child: _buildInfoChip(
                            theme,
                            icon: Icons.local_shipping_rounded,
                            label: 'Código',
                            value: codigoLote!,
                          ),
                        ),
                      if (codigoLote != null) const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          theme,
                          icon: Icons.speed_rounded,
                          label: 'Velocidad',
                          value: velocidad != null
                              ? '${velocidad!.toInt()} km/h'
                              : '0 km/h',
                        ),
                      ),
                    ],
                  ),

                  // Contenido extra (formularios, etc)
                  if (contenidoExtra != null) ...[
                    const SizedBox(height: 16),
                    contenidoExtra!,
                  ],

                  const SizedBox(height: 20),

                  // Botón de acción
                  botonAccion,

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinoCard(ThemeData theme, Color colorEstado) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorEstado.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorEstado.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Icono del destino
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _hexToColor(destino!.color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                destino!.iconoEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info del destino
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximo destino',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destino!.nombre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Distancia
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.navigation_rounded, color: colorEstado, size: 20),
              const SizedBox(height: 4),
              Text(
                distancia,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorEstado,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
