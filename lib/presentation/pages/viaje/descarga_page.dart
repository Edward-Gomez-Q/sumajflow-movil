// lib/presentation/pages/viaje/descarga_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_evidencia_uploader.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';

/// Página para la descarga del mineral
class DescargaPage extends StatelessWidget {
  final ViajeController controller;

  const DescargaPage({super.key, required this.controller});

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

                  // Icono de descarga
                  Center(child: _buildUnloadingAnimation(theme)),

                  const SizedBox(height: 24),

                  // Mensaje principal
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Descarga en Progreso',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Descarga el mineral en el punto de destino. Toma una foto al finalizar.',
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

                  // Alerta
                  ViajeAlertCard(
                    mensaje:
                        '¡Casi terminas! Toma una foto como evidencia de la descarga',
                    tipo: ViajeAlertType.info,
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

                  // Información del destino
                  Obx(() {
                    final lote = controller.loteDetalle.value;
                    if (lote == null) return const SizedBox.shrink();

                    return ViajeInfoCard(
                      titulo: 'Punto de Descarga',
                      iconoTitulo: Icons.warehouse_rounded,
                      colorAccento: const Color(0xFFEC4899),
                      items: [
                        ViajeInfoItem(
                          label: 'Destino',
                          valor: lote.destinoTipo,
                          icono: Icons.business_rounded,
                        ),
                        if (lote.puntoAlmacenDestino != null)
                          ViajeInfoItem(
                            label: 'Almacén',
                            valor: lote.puntoAlmacenDestino!.nombre,
                            icono: Icons.location_on_rounded,
                          ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),
                  /*
                  // Resumen de pesajes
                  Obx(() {
                    final observ = controller.observaciones.value;
                    if (observ == null) return const SizedBox.shrink();

                    final pesajes = observ.pesajes;
                    if (pesajes.isEmpty) return const SizedBox.shrink();

                    return ViajeInfoCard(
                      titulo: 'Resumen de Pesajes',
                      iconoTitulo: Icons.scale_rounded,
                      items: pesajes.map((p) {
                        return ViajeInfoItem(
                          label: p.tipo.titulo,
                          valor: p.datosPesaje != null
                              ? '${p.datosPesaje!.pesoNeto.toStringAsFixed(0)} kg neto'
                              : 'Sin datos',
                          icono: Icons.speed_rounded,
                        );
                      }).toList(),
                    );
                  }),
*/
                  const SizedBox(height: 20),

                  // Campo de observaciones
                  ViajeObservacionField(
                    label: 'Observaciones de la Descarga',
                    hint:
                        'Estado del mineral, condiciones del punto de descarga, etc.',
                    onChanged: controller.actualizarComentario,
                    maxLines: 3,
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

  Widget _buildUnloadingAnimation(ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Círculo de fondo animado
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(seconds: 1),
          builder: (context, value, child) {
            return Container(
              width: 140 * value,
              height: 140 * value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.1),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('📦', style: TextStyle(fontSize: 44)),
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
                        'Toma una foto para finalizar',
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
                colorPrimario: const Color(0xFFEC4899),
              ),
            ],
          );
        }),
      ),
    );
  }
}
