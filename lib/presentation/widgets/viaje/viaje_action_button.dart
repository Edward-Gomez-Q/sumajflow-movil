// lib/presentation/widgets/viaje/viaje_action_button.dart

import 'package:flutter/material.dart';

/// Botón de acción principal del viaje con estados y animaciones
class ViajeActionButton extends StatelessWidget {
  final String texto;
  final IconData icono;
  final bool habilitado;
  final bool cargando;
  final VoidCallback? onPressed;
  final Color? colorPrimario;
  final bool esSecundario;

  const ViajeActionButton({
    super.key,
    required this.texto,
    required this.icono,
    this.habilitado = true,
    this.cargando = false,
    this.onPressed,
    this.colorPrimario,
    this.esSecundario = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorPrimario ?? theme.colorScheme.primary;

    if (esSecundario) {
      return _buildSecundario(theme, color);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: habilitado && !cargando
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: habilitado ? color : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: habilitado && !cargando ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cargando) ...[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        habilitado
                            ? Colors.white
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    icono,
                    color: habilitado
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 24,
                  ),
                ],
                const SizedBox(width: 12),
                Text(
                  cargando ? 'Procesando...' : texto,
                  style: TextStyle(
                    color: habilitado
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecundario(ThemeData theme, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: habilitado
              ? color.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: habilitado && !cargando ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cargando) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ] else ...[
                  Icon(
                    icono,
                    color: habilitado
                        ? color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ],
                const SizedBox(width: 10),
                Text(
                  cargando ? 'Procesando...' : texto,
                  style: TextStyle(
                    color: habilitado
                        ? color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón flotante de acción con estilo elevado
class ViajeFloatingActionButton extends StatelessWidget {
  final String texto;
  final IconData icono;
  final bool habilitado;
  final bool cargando;
  final VoidCallback? onPressed;
  final Color? color;

  const ViajeFloatingActionButton({
    super.key,
    required this.texto,
    required this.icono,
    this.habilitado = true,
    this.cargando = false,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ViajeActionButton(
          texto: texto,
          icono: icono,
          habilitado: habilitado,
          cargando: cargando,
          onPressed: onPressed,
          colorPrimario: buttonColor,
        ),
      ),
    );
  }
}
