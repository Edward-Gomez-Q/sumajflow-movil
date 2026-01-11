// lib/presentation/pages/viaje/en_camino_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/maps/mapa_trazabilidad_widget.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_bottom_panel.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';

/// Página que muestra el mapa y la navegación hacia el destino
class EnCaminoPage extends StatelessWidget {
  final ViajeController controller;

  const EnCaminoPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Mapa a pantalla completa
        /*Positioned.fill(
          child: Obx(() {
            return MapaTrazabilidadWidget(
              currentPosition: controller.currentPosition.value,
              proximoWaypoint: controller.loteDetalle.value != null
                  ? _obtenerWaypointDestino()
                  : null,
              estadoViaje: controller.estadoActual.value.valor,
            );
          }),
        ),*/

        // Indicador de geofencing (si está cerca)
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

        // Panel inferior
        /*Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomPanel(theme),
        ),*/
      ],
    );
  }

  /*Widget _buildBottomPanel(ThemeData theme) {
    return Obx(() {
      final destino = _obtenerWaypointDestino();
      final estado = controller.estadoActual.value;

      // Contenido extra según el estado
      Widget? contenidoExtra;

      // Si está dentro del geofence, mostrar campo de observaciones
      if (controller.estaDentroDelGeofence) {
        contenidoExtra = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ViajeObservacionField(
              onChanged: controller.actualizarComentario,
              hint: 'Agregar observaciones de llegada (opcional)',
              maxLines: 2,
            ),
          ],
        );
      }

      return ViajeBottomPanel(
        estado: estado,
        destino: destino,
        distancia: controller.distanciaFormateada,
        codigoLote: controller.loteDetalle.value?.codigoLote,
        velocidad: controller.currentPosition.value?.speed != null
            ? controller.currentPosition.value!.speed * 3.6
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
  }*/

  /// Obtiene el waypoint de destino según el estado actual
  dynamic _obtenerWaypointDestino() {
    final lote = controller.loteDetalle.value;
    if (lote == null) return null;

    switch (controller.estadoActual.value) {
      case EstadoViaje.enCaminoMina:
        return lote.puntoOrigen;
      case EstadoViaje.enCaminoBalanzaCoop:
        return lote.puntoBalanzaCoop;
      case EstadoViaje.enCaminoBalanzaDestino:
        return lote.puntoBalanzaDestino;
      case EstadoViaje.rutaCompletada:
        return lote.puntoAlmacenDestino;
      default:
        return null;
    }
  }
}
