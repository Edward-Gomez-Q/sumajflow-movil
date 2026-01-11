// lib/presentation/widgets/viaje/viaje_info_card.dart

import 'package:flutter/material.dart';

/// Tarjeta de información reutilizable
class ViajeInfoCard extends StatelessWidget {
  final String titulo;
  final List<ViajeInfoItem> items;
  final IconData? iconoTitulo;
  final Color? colorAccento;
  final Widget? accionExtra;

  const ViajeInfoCard({
    super.key,
    required this.titulo,
    required this.items,
    this.iconoTitulo,
    this.colorAccento,
    this.accionExtra,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorAccento ?? theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (iconoTitulo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(iconoTitulo, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    titulo,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (accionExtra != null) accionExtra!,
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final esUltimo = index == items.length - 1;

                return Column(
                  children: [
                    _buildInfoRow(theme, item),
                    if (!esUltimo)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, ViajeInfoItem item) {
    return Row(
      children: [
        if (item.icono != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icono, size: 16, color: theme.colorScheme.primary),
          ),
        if (item.icono != null) const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.valor,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (item.badge != null) ...[const SizedBox(width: 8), item.badge!],
      ],
    );
  }
}

/// Item de información para ViajeInfoCard
class ViajeInfoItem {
  final String label;
  final String valor;
  final IconData? icono;
  final Widget? badge;

  const ViajeInfoItem({
    required this.label,
    required this.valor,
    this.icono,
    this.badge,
  });
}

/// Card compacta para mostrar un stat
class ViajeStatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color? color;
  final String? subtitulo;

  const ViajeStatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    this.color,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.1),
            cardColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, size: 18, color: cardColor),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cardColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card de alerta/advertencia
class ViajeAlertCard extends StatelessWidget {
  final String mensaje;
  final ViajeAlertType tipo;
  final VoidCallback? onClose;
  final VoidCallback? onAction;
  final String? textoAccion;

  const ViajeAlertCard({
    super.key,
    required this.mensaje,
    this.tipo = ViajeAlertType.info,
    this.onClose,
    this.onAction,
    this.textoAccion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(theme);
    final icon = _getIcon();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onAction != null && textoAccion != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                textoAccion!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          if (onClose != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close_rounded, size: 18, color: color),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor(ThemeData theme) {
    switch (tipo) {
      case ViajeAlertType.info:
        return const Color(0xFF3B82F6);
      case ViajeAlertType.success:
        return const Color(0xFF10B981);
      case ViajeAlertType.warning:
        return const Color(0xFFF59E0B);
      case ViajeAlertType.error:
        return theme.colorScheme.error;
    }
  }

  IconData _getIcon() {
    switch (tipo) {
      case ViajeAlertType.info:
        return Icons.info_outline_rounded;
      case ViajeAlertType.success:
        return Icons.check_circle_outline_rounded;
      case ViajeAlertType.warning:
        return Icons.warning_amber_rounded;
      case ViajeAlertType.error:
        return Icons.error_outline_rounded;
    }
  }
}

enum ViajeAlertType { info, success, warning, error }
