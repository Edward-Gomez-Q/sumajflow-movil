// lib/presentation/pages/viaje/widgets/viaje_state_handler.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_iniciar_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_en_camino_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_llegada_mina_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_esperando_carguio_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_pesaje_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_llegada_almacen_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_descarga_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_completado_view.dart';

/// Widget que decide qué vista mostrar según el estado del viaje
/// Sincronizado con el flujo de 8 pasos del backend
class ViajeStateHandler extends StatelessWidget {
  final ViajeController controller;

  const ViajeStateHandler({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final estado = controller.estadoActual.value;
      debugPrint('🎭 Estado actual del viaje: $estado (${estado.valor})');

      switch (estado) {
        // PASO 1: Esperando iniciar
        case EstadoViaje.esperandoIniciar:
          return ViajeIniciarView(controller: controller);

        // PASO 2: En camino a la mina - Mapa con geofencing
        case EstadoViaje.enCaminoMina:
          // Si está dentro del geofence, mostrar vista de confirmación
          if (controller.estaDentroDelGeofence) {
            return ViajeLlegadaMinaView(controller: controller);
          }
          return ViajeEnCaminoView(controller: controller);

        // PASO 3: Esperando carguío - Confirmar carguío con evidencias
        case EstadoViaje.esperandoCarguio:
          return ViajeEsperandoCarguioView(controller: controller);

        // PASO 4: En camino balanza cooperativa - Mapa con geofencing
        case EstadoViaje.enCaminoBalanzaCoop:
          // Si está dentro del geofence, mostrar vista de pesaje
          if (controller.estaDentroDelGeofence) {
            return ViajePesajeView(controller: controller, esCooperativa: true);
          }
          return ViajeEnCaminoView(controller: controller);

        // PASO 5: En camino balanza destino - Mapa con geofencing
        case EstadoViaje.enCaminoBalanzaDestino:
          // Si está dentro del geofence, mostrar vista de pesaje
          if (controller.estaDentroDelGeofence) {
            return ViajePesajeView(
              controller: controller,
              esCooperativa: false,
            );
          }
          return ViajeEnCaminoView(controller: controller);

        // PASO 6: En camino almacén destino - Mapa con geofencing
        case EstadoViaje.enCaminoAlmacenDestino:
          // Si está dentro del geofence, mostrar vista de llegada a almacén
          if (controller.estaDentroDelGeofence) {
            return ViajeLlegadaAlmacenView(controller: controller);
          }
          return ViajeEnCaminoView(controller: controller);

        // PASO 7: Descargando - Confirmar descarga con evidencias
        case EstadoViaje.descargando:
          return ViajeDescargaView(controller: controller);

        // PASO 8: Completado - Vista de éxito
        case EstadoViaje.completado:
          return ViajeCompletadoView(controller: controller);
      }
    });
  }
}
