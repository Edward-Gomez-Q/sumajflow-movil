// lib/presentation/pages/viaje/views/viaje_en_camino_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/maps/mapa_trazabilidad_widget.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_bottom_panel.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';

// TEMPORAL PARA DEBUG
class ViajeEnCaminoView extends StatelessWidget {
  final ViajeController controller;

  const ViajeEnCaminoView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mapa ocupa el espacio disponible
        Expanded(
          child: Obx(() {
            final position =
                controller.trackingController.currentPosition.value;
            final waypoint = controller.proximoWaypoint;

            debugPrint(
              '🗺️ Mapa - Pos: ${position?.latitude}, Way: ${waypoint?.latitud}',
            );

            return Stack(
              children: [
                MapaTrazabilidadWidget(
                  currentPosition: position,
                  proximoWaypoint: waypoint,
                  estadoViaje: controller.estadoActual.value.valor,
                ),

                Obx(() {
                  if (controller.estaDentroDelGeofence) {
                    return Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: ViajeAlertCard(
                        mensaje: '¡Has llegado a tu destino!',
                        tipo: ViajeAlertType.success,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            );
          }),
        ),

        // Panel inferior
        _buildPanelInferior(context),
      ],
    );
  }

  Widget _buildPanelInferior(BuildContext context) {
    return Obx(() {
      Widget? contenidoExtra;

      if (controller.estaDentroDelGeofence) {
        contenidoExtra = ViajeObservacionField(
          onChanged: controller.actualizarComentario,
          hint: 'Observaciones (opcional)',
          maxLines: 2,
        );
      }

      return ViajeBottomPanel(
        estado: controller.estadoActual.value,
        destino: controller.proximoWaypoint,
        distancia: controller.distanciaFormateada,
        codigoLote: controller.loteDetalle.value?.codigoLote,
        velocidad:
            controller.trackingController.currentPosition.value?.speed != null
            ? controller.trackingController.currentPosition.value!.speed * 3.6
            : null,
        contenidoExtra: contenidoExtra,
        botonAccion: ViajeActionButton(
          texto: controller.textoBotonPrincipal,
          icono: controller.iconoBotonPrincipal,
          habilitado: controller.botonPrincipalHabilitado.value,
          cargando: controller.isLoading.value,
          onPressed: controller.ejecutarAccionPrincipal,
        ),
      );
    });
  }
}
