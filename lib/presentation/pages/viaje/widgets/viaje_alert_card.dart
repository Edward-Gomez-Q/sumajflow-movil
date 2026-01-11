// lib/presentation/widgets/viaje/viaje_alert_card.dart

import 'package:flutter/material.dart';

enum ViajeAlertType { info, success, warning, error }

class ViajeAlertCard extends StatelessWidget {
  final String mensaje;
  final ViajeAlertType tipo;
  final IconData? iconoCustom;

  const ViajeAlertCard({
    super.key,
    required this.mensaje,
    required this.tipo,
    this.iconoCustom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfigForType(tipo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: config.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: config.iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconoCustom ?? config.icon,
              color: config.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Mensaje
          Expanded(
            child: Text(
              mensaje,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: config.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _AlertConfig _getConfigForType(ViajeAlertType tipo) {
    switch (tipo) {
      case ViajeAlertType.info:
        return _AlertConfig(
          icon: Icons.info_outline_rounded,
          backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
          iconBackgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          iconColor: const Color(0xFF3B82F6),
          textColor: const Color(0xFF1E40AF),
          shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        );

      case ViajeAlertType.success:
        return _AlertConfig(
          icon: Icons.check_circle_outline_rounded,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
          iconBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
          iconColor: const Color(0xFF10B981),
          textColor: const Color(0xFF065F46),
          shadowColor: const Color(0xFF10B981).withValues(alpha: 0.1),
        );

      case ViajeAlertType.warning:
        return _AlertConfig(
          icon: Icons.warning_amber_rounded,
          backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          iconBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          iconColor: const Color(0xFFF59E0B),
          textColor: const Color(0xFF92400E),
          shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        );

      case ViajeAlertType.error:
        return _AlertConfig(
          icon: Icons.error_outline_rounded,
          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
          iconBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
          iconColor: const Color(0xFFEF4444),
          textColor: const Color(0xFF991B1B),
          shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
        );
    }
  }
}

class _AlertConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color shadowColor;

  _AlertConfig({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.shadowColor,
  });
}
