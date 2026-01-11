// lib/presentation/pages/viaje/views/viaje_iniciar_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';

class ViajeIniciarView extends StatelessWidget {
  final ViajeController controller;

  const ViajeIniciarView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono principal
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              '¡Todo listo para comenzar!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Text(
              'Presiona el botón para iniciar el viaje y comenzar el seguimiento GPS.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Info del lote
            Obx(() {
              final lote = controller.loteDetalle.value;
              if (lote == null) return const SizedBox.shrink();

              return ViajeInfoCard(
                titulo: 'Información del Viaje',
                iconoTitulo: Icons.info_outline_rounded,
                items: [
                  ViajeInfoItem(
                    label: 'Código',
                    valor: lote.codigoLote,
                    icono: Icons.tag_rounded,
                  ),
                  ViajeInfoItem(
                    label: 'Origen',
                    valor: lote.minaNombre,
                    icono: Icons.terrain_rounded,
                  ),
                  ViajeInfoItem(
                    label: 'Destino',
                    valor: lote.destinoTipo,
                    icono: Icons.flag_rounded,
                  ),
                ],
              );
            }),

            const Spacer(),

            // Botón de iniciar
            Obx(() {
              return ViajeActionButton(
                texto: controller.textoBotonPrincipal,
                icono: controller.iconoBotonPrincipal,
                habilitado: !controller.isLoading.value,
                cargando: controller.isLoading.value,
                onPressed: controller.ejecutarAccionPrincipal,
              );
            }),
          ],
        ),
      ),
    );
  }
}
