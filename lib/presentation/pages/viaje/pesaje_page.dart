// lib/presentation/pages/viaje/pesaje_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_evidencia_uploader.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_pesaje_form.dart';

/// Página para registrar el pesaje en balanza
class PesajePage extends StatelessWidget {
  final ViajeController controller;

  const PesajePage({super.key, required this.controller});

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

                  // Icono de balanza
                  Center(child: _buildScaleIcon(theme)),

                  const SizedBox(height: 24),

                  // Título
                  Center(
                    child: Column(
                      children: [
                        Obx(() {
                          final esCoop =
                              controller.estadoActual.value ==
                              EstadoViaje.pesajeBalanzaCoop;
                          return Text(
                            esCoop
                                ? 'Pesaje Balanza Cooperativa'
                                : 'Pesaje Balanza Destino',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          );
                        }),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa los datos del ticket de pesaje',
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

                  // Formulario de pesaje
                  Obx(() {
                    return ViajePesajeForm(
                      pesoBrutoInicial: controller.pesoBrutoTemp.value > 0
                          ? controller.pesoBrutoTemp.value
                          : null,
                      pesoTaraInicial: controller.pesoTaraTemp.value > 0
                          ? controller.pesoTaraTemp.value
                          : null,
                      onPesoBrutoChanged: controller.actualizarPesoBruto,
                      onPesoTaraChanged: controller.actualizarPesoTara,
                    );
                  }),

                  const SizedBox(height: 24),

                  // Alerta de foto requerida
                  ViajeAlertCard(
                    mensaje:
                        'Toma una foto del ticket de pesaje como evidencia',
                    tipo: ViajeAlertType.info,
                  ),

                  const SizedBox(height: 16),

                  // Uploader de evidencias
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

                  const SizedBox(height: 24),

                  // Información de la balanza
                  Obx(() {
                    final lote = controller.loteDetalle.value;
                    if (lote == null) return const SizedBox.shrink();

                    final esCoop =
                        controller.estadoActual.value ==
                        EstadoViaje.pesajeBalanzaCoop;
                    final balanza = esCoop
                        ? lote.puntoBalanzaCoop
                        : lote.puntoBalanzaDestino;

                    if (balanza == null) return const SizedBox.shrink();

                    return ViajeInfoCard(
                      titulo: 'Información de Balanza',
                      iconoTitulo: Icons.scale_rounded,
                      colorAccento: const Color(0xFF06B6D4),
                      items: [
                        ViajeInfoItem(
                          label: 'Nombre',
                          valor: balanza.nombre,
                          icono: Icons.location_on_rounded,
                        ),
                        ViajeInfoItem(
                          label: 'Tipo',
                          valor: esCoop ? 'Cooperativa' : 'Destino',
                          icono: Icons.category_rounded,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  // Campo de observaciones
                  ViajeObservacionField(
                    label: 'Observaciones del Pesaje',
                    hint: 'Notas adicionales, número de ticket, etc.',
                    onChanged: controller.actualizarComentario,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 100),
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

  Widget _buildScaleIcon(ThemeData theme) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(child: Text('⚖️', style: TextStyle(fontSize: 44))),
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
          final tienePesos =
              controller.pesoBrutoTemp.value > 0 &&
              controller.pesoTaraTemp.value > 0;

          String? mensajeError;
          if (!tienePesos) {
            mensajeError = 'Ingresa los pesos para continuar';
          } else if (!tieneEvidencia) {
            mensajeError = 'Toma una foto del ticket';
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Resumen del peso neto
              if (tienePesos)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.scale_rounded,
                        size: 18,
                        color: Color(0xFF06B6D4),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Peso Neto: ${controller.pesoNetoCalculado.toStringAsFixed(2)} kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF06B6D4),
                        ),
                      ),
                    ],
                  ),
                ),

              // Mensaje de error si aplica
              if (mensajeError != null &&
                  !controller.botonPrincipalHabilitado.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        mensajeError,
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
                colorPrimario: const Color(0xFF06B6D4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
