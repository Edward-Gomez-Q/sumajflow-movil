// lib/presentation/pages/viaje/views/viaje_llegada_mina_view.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_evidencia_uploader.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';

class ViajeLlegadaMinaView extends StatelessWidget {
  final ViajeController controller;

  const ViajeLlegadaMinaView({super.key, required this.controller});

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
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.mountain,
                          size: 48,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Confirmar Llegada a Mina',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildChecklistCard(theme),
                  const SizedBox(height: 20),
                  const ViajeAlertCard(
                    mensaje: 'Puedes tomar una foto de referencia (opcional)',
                    tipo: ViajeAlertType.info,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    return ViajeEvidenciaUploader(
                      evidencias: controller.evidenciasTemporales,
                      onAgregarEvidencia: controller.agregarEvidencia,
                      onEliminarEvidencia: controller.eliminarEvidencia,
                      obligatorio: false,
                      maxEvidencias: 3,
                      mostrarSubiendo: controller.subiendoEvidencia.value,
                    );
                  }),
                  const SizedBox(height: 20),
                  ViajeObservacionField(
                    label: 'Observaciones de la Llegada',
                    onChanged: controller.actualizarComentario,
                    hint: 'Notas sobre el estado de la mina...',
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.listCheck,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Verificación de Mina',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              return CheckboxListTile(
                value: controller.palaOperativa.value,
                onChanged: (value) =>
                    controller.actualizarPalaOperativa(value ?? true),
                title: const Text('Pala operativa'),
                subtitle: const Text(
                  'La maquinaria está funcionando correctamente',
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            const Divider(height: 8),
            Obx(() {
              return CheckboxListTile(
                value: controller.mineralVisible.value,
                onChanged: (value) =>
                    controller.actualizarMineralVisible(value ?? true),
                title: const Text('Mineral visible'),
                subtitle: const Text('El mineral está disponible para carga'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          ],
        ),
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
            colorPrimario: const Color(0xFF8B5CF6),
          );
        }),
      ),
    );
  }
}
