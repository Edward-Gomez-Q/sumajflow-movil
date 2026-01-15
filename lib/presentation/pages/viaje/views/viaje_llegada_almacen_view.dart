// lib/presentation/pages/viaje/views/viaje_llegada_almacen_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';

class ViajeLlegadaAlmacenView extends StatelessWidget {
  final ViajeController controller;

  const ViajeLlegadaAlmacenView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ViajeEstadoHeader(
                    estado: controller.estadoActual.value,
                    subtitulo: controller.descripcionEstadoActual,
                  ),
                  const SizedBox(height: 32),

                  // Icono de almacén
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Text('🏭', style: TextStyle(fontSize: 56)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Confirmar Llegada a Almacén',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Has llegado al punto de descarga',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Información del destino
                  Obx(() {
                    final lote = controller.loteDetalle.value;
                    if (lote == null) return const SizedBox.shrink();

                    return ViajeInfoCard(
                      titulo: 'Información del Destino',
                      iconoTitulo: Icons.location_on_rounded,
                      items: [
                        ViajeInfoItem(
                          label: 'Destino',
                          valor: lote.destinoNombre,
                          icono: Icons.warehouse_rounded,
                        ),
                        ViajeInfoItem(
                          label: 'Tipo',
                          valor: lote.destinoTipo,
                          icono: Icons.category_rounded,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),

                  // Checkbox de confirmación
                  _buildChecklistCard(theme),
                  const SizedBox(height: 20),

                  // Observaciones
                  ViajeObservacionField(
                    label: 'Observaciones de la Llegada',
                    onChanged: controller.actualizarComentario,
                    hint: 'Notas sobre la llegada al almacén...',
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomButton(theme),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(ThemeData theme) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Confirmación de Llegada',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkbox: Confirmación de llegada
          Obx(() {
            return CheckboxListTile(
              value: controller.confirmacionLlegada.value,
              onChanged: (value) =>
                  controller.actualizarConfirmacionLlegada(value ?? true),
              title: const Text('Confirmo que he llegado al almacén'),
              subtitle: const Text('Estoy listo para iniciar la descarga'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        child: Obx(() {
          return ViajeActionButton(
            texto: controller.textoBotonPrincipal,
            icono: controller.iconoBotonPrincipal,
            habilitado: controller.botonPrincipalHabilitado.value,
            cargando: controller.isLoading.value,
            onPressed: controller.ejecutarAccionPrincipal,
            colorPrimario: const Color(0xFF10B981),
          );
        }),
      ),
    );
  }
}
