// lib/presentation/pages/viaje/views/viaje_pesaje_view.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_pesaje_form.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_evidencia_uploader.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';

class ViajePesajeView extends StatelessWidget {
  final ViajeController controller;
  final bool esCooperativa;

  const ViajePesajeView({
    super.key,
    required this.controller,
    required this.esCooperativa,
  });

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
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF06B6D4,
                            ).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.scaleBalanced,
                          size: 40,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    esCooperativa
                        ? 'Pesaje Balanza Cooperativa'
                        : 'Pesaje Balanza Destino',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    esCooperativa
                        ? 'Primer pesaje del mineral'
                        : 'Pesaje final en destino',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ViajePesajeForm(
                    onPesoBrutoChanged: controller.actualizarPesoBruto,
                    onPesoTaraChanged: controller.actualizarPesoTara,
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final pesoNeto = controller.pesoNetoCalculado;
                    if (pesoNeto > 0) {
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(scale: value, child: child),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.weightHanging,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Peso Neto: ${pesoNeto.toStringAsFixed(2)} kg',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 20),
                  const ViajeAlertCard(
                    mensaje: 'Toma una foto del ticket de pesaje',
                    tipo: ViajeAlertType.info,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    return ViajeEvidenciaUploader(
                      evidencias: controller.evidenciasTemporales,
                      onAgregarEvidencia: controller.agregarEvidencia,
                      onEliminarEvidencia: controller.eliminarEvidencia,
                      obligatorio: true,
                      maxEvidencias: 3,
                      mostrarSubiendo: controller.subiendoEvidencia.value,
                    );
                  }),
                  const SizedBox(height: 20),
                  ViajeObservacionField(
                    label: 'Observaciones del Pesaje',
                    onChanged: controller.actualizarComentario,
                    hint: 'Notas sobre el pesaje...',
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
            colorPrimario: const Color(0xFF06B6D4),
          );
        }),
      ),
    );
  }
}
