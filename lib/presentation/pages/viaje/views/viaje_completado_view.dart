// lib/presentation/pages/viaje/views/viaje_completado_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';

class ViajeCompletadoView extends StatelessWidget {
  final ViajeController controller;

  const ViajeCompletadoView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de éxito
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              '¡Viaje Completado!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Has completado exitosamente el transporte de mineral.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Información del viaje completado
            Obx(() {
              final lote = controller.loteDetalle.value;
              if (lote == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.tag_rounded,
                      label: 'Código Lote',
                      value: lote.codigoLote,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.terrain_rounded,
                      label: 'Origen',
                      value: lote.minaNombre,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.flag_rounded,
                      label: 'Destino',
                      value: lote.destinoTipo,
                      theme: theme,
                    ),
                  ],
                ),
              );
            }),

            const Spacer(),

            // Botón para volver
            ViajeActionButton(
              texto: 'Volver al Inicio',
              icono: Icons.home_rounded,
              habilitado: true,
              colorPrimario: const Color(0xFF10B981),
              onPressed: () {
                /*// Obtener el tag del controller antes de eliminarlo
                final tag = Get.find<ViajeController>(
                  tag: 'viaje_${controller.asignacionId}',
                );*/

                // Eliminar el controller
                Get.delete<ViajeController>(
                  tag: 'viaje_${controller.asignacionId}',
                );

                // Volver atrás
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
