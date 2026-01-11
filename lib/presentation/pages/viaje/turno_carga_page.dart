// lib/presentation/pages/viaje/turno_carga_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';

/// Página que muestra el estado de espera para el carguío
class TurnoCargaPage extends StatelessWidget {
  final ViajeController controller;

  const TurnoCargaPage({super.key, required this.controller});

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de estado
                  Obx(() {
                    return ViajeEstadoHeader(
                      estado: controller.estadoActual.value,
                      subtitulo: controller.descripcionEstadoActual,
                    );
                  }),

                  const SizedBox(height: 24),

                  // Icono de espera animado
                  Center(child: _buildWaitingAnimation(theme)),

                  const SizedBox(height: 32),

                  // Mensaje principal
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Esperando Turno de Carga',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estás en la mina. Espera tu turno para iniciar la carga del mineral.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Información de la mina
                  Obx(() {
                    final lote = controller.loteDetalle.value;
                    if (lote == null) return const SizedBox.shrink();

                    return ViajeInfoCard(
                      titulo: 'Información de Carga',
                      iconoTitulo: Icons.info_outline_rounded,
                      items: [
                        ViajeInfoItem(
                          label: 'Mina',
                          valor: lote.minaNombre,
                          icono: Icons.terrain_rounded,
                        ),
                        ViajeInfoItem(
                          label: 'Tipo de Mineral',
                          valor: _formatTipoMineral(lote.tipoMineral),
                          icono: Icons.diamond_rounded,
                        ),
                        ViajeInfoItem(
                          label: 'Número de Camión',
                          valor:
                              '#${lote.numeroCamion} de ${lote.totalCamiones}',
                          icono: Icons.local_shipping_rounded,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  // Campo de observaciones
                  ViajeObservacionField(
                    label: 'Observaciones',
                    hint: 'Notas sobre el estado de la mina, acceso, etc.',
                    onChanged: controller.actualizarComentario,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 100), // Espacio para el botón
                ],
              ),
            ),
          ),

          // Botón de acción
          _buildBottomButton(theme),
        ],
      ),
    );
  }

  Widget _buildWaitingAnimation(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                const Color(0xFF8B5CF6).withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: const Center(
                child: Text('⏳', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
        );
      },
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
            colorPrimario: const Color(0xFF8B5CF6),
          );
        }),
      ),
    );
  }

  String _formatTipoMineral(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'bruto':
        return 'Mineral Bruto';
      case 'concentrado':
        return 'Concentrado';
      default:
        return tipo;
    }
  }
}
