// lib/presentation/widgets/viaje/viaje_bottom_panel.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';

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
    final colorEstado = estado.color;

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
                  if (destino != null) ...[
                    _buildDestinoCard(theme, colorEstado),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      if (codigoLote != null)
                        Expanded(
                          child: _buildInfoChip(
                            theme,
                            icon: FontAwesomeIcons.truck,
                            label: 'Código',
                            value: "00$codigoLote",
                          ),
                        ),
                      if (codigoLote != null) const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          theme,
                          icon: FontAwesomeIcons.gaugeHigh,
                          label: 'Velocidad',
                          value: velocidad != null
                              ? '${velocidad!.toInt()} km/h'
                              : '0 km/h',
                        ),
                      ),
                    ],
                  ),
                  if (contenidoExtra != null) ...[
                    const SizedBox(height: 16),
                    contenidoExtra!,
                  ],
                  const SizedBox(height: 20),
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorEstado.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorEstado.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hexToColor(destino!.color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: _getDestinoIcon(destino!.iconoEmoji)),
            ),
            const SizedBox(width: 14),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FaIcon(
                  FontAwesomeIcons.locationArrow,
                  color: colorEstado,
                  size: 18,
                ),
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
          FaIcon(icon, size: 18, color: theme.colorScheme.primary),
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

  Widget _getDestinoIcon(String iconoEmoji) {
    // Mapeo de emojis a Font Awesome icons
    final iconMap = {
      '⛏️': FontAwesomeIcons.mountain,
      '🏭': FontAwesomeIcons.industry,
      '⚖️': FontAwesomeIcons.scaleBalanced,
      '🏢': FontAwesomeIcons.building,
    };

    final icon = iconMap[iconoEmoji] ?? FontAwesomeIcons.locationDot;

    return FaIcon(icon, size: 24, color: Colors.white);
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
