// lib/presentation/pages/viaje/cargando_mineral_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_evidencia_uploader.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';

/// Página que muestra el progreso de la carga del mineral
class CargandoMineralPage extends StatelessWidget {
  final ViajeController controller;

  const CargandoMineralPage({super.key, required this.controller});

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

                  // Animación de carga
                  Center(child: _buildLoadingAnimation(theme)),

                  const SizedBox(height: 24),

                  // Mensaje principal
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Carga en Progreso',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toma una foto del camión cargado antes de continuar.',
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

                  // Alerta de evidencia requerida
                  ViajeAlertCard(
                    mensaje:
                        'Se requiere al menos una foto como evidencia de la carga',
                    tipo: ViajeAlertType.warning,
                  ),

                  const SizedBox(height: 20),

                  // Uploader de evidencias
                  Obx(() {
                    return ViajeEvidenciaUploader(
                      evidencias: controller.evidenciasTemporales,
                      onAgregarEvidencia: controller.agregarEvidencia,
                      onEliminarEvidencia: controller.eliminarEvidencia,
                      obligatorio: true,
                      maxEvidencias: 5,
                      mostrarSubiendo: controller.subiendoEvidencia.value,
                    );
                  }),

                  const SizedBox(height: 24),

                  // Información de la carga
                  Obx(() {
                    final lote = controller.loteDetalle.value;
                    if (lote == null) return const SizedBox.shrink();

                    return ViajeInfoCard(
                      titulo: 'Detalles de Carga',
                      iconoTitulo: Icons.inventory_2_rounded,
                      colorAccento: const Color(0xFFF97316),
                      items: [
                        ViajeInfoItem(
                          label: 'Tipo de Mineral',
                          valor: _formatTipoMineral(lote.tipoMineral),
                          icono: Icons.diamond_rounded,
                        ),
                        ViajeInfoItem(
                          label: 'Próximo Destino',
                          valor: 'Balanza Cooperativa',
                          icono: Icons.scale_rounded,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  // Campo de observaciones
                  ViajeObservacionField(
                    label: 'Observaciones de la Carga',
                    hint:
                        'Estado del mineral, humedad, cantidad aproximada, etc.',
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

  Widget _buildLoadingAnimation(ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Círculo exterior animado
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 3),
          builder: (context, value, child) {
            return Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  startAngle: 0,
                  endAngle: 6.28 * value,
                  colors: [
                    const Color(0xFFF97316).withValues(alpha: 0.1),
                    const Color(0xFFF97316).withValues(alpha: 0.3),
                    const Color(0xFFF97316).withValues(alpha: 0.1),
                  ],
                ),
              ),
            );
          },
        ),
        // Icono central
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF97316).withValues(alpha: 0.15),
            border: Border.all(
              color: const Color(0xFFF97316).withValues(alpha: 0.4),
              width: 3,
            ),
          ),
          child: const Center(
            child: Text('⛏️', style: TextStyle(fontSize: 44)),
          ),
        ),
      ],
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
          final tieneEvidencia = controller.evidenciasTemporales.isNotEmpty;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!tieneEvidencia)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Toma una foto para continuar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ViajeActionButton(
                texto: controller.textoBotonPrincipal,
                icono: controller.iconoBotonPrincipal,
                habilitado: controller.botonPrincipalHabilitado.value,
                cargando: controller.isLoading.value,
                onPressed: controller.ejecutarAccionPrincipal,
                colorPrimario: const Color(0xFFF97316),
              ),
            ],
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
