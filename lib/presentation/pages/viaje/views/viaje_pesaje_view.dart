// lib/presentation/pages/viaje/views/viaje_pesaje_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_pesaje_form.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_evidencia_uploader.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';

class ViajePesajeView extends StatelessWidget {
  final ViajeController controller;

  const ViajePesajeView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esCoop =
        controller.estadoActual.value == EstadoViaje.pesajeBalanzaCoop;

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

                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Text('⚖️', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    esCoop
                        ? 'Pesaje Balanza Cooperativa'
                        : 'Pesaje Balanza Destino',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ViajePesajeForm(
                    onPesoBrutoChanged: controller.actualizarPesoBruto,
                    onPesoTaraChanged: controller.actualizarPesoTara,
                  ),
                  const SizedBox(height: 20),

                  ViajeAlertCard(
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
