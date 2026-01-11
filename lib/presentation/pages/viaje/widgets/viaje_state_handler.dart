// lib/presentation/pages/viaje/widgets/viaje_state_handler.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_iniciar_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_en_camino_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_turno_carga_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_cargando_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_pesaje_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_descarga_view.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/views/viaje_completado_view.dart';

/// Widget que decide qué vista mostrar según el estado del viaje
class ViajeStateHandler extends StatelessWidget {
  final ViajeController controller;

  const ViajeStateHandler({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final estado = controller.estadoActual.value;
      //Mostrar el estado en consola
      debugPrint('Estado actual del viaje: $estado');

      switch (estado) {
        case EstadoViaje.esperandoIniciar:
          return ViajeIniciarView(controller: controller);

        case EstadoViaje.enCaminoMina:
        case EstadoViaje.enCaminoBalanzaCoop:
        case EstadoViaje.enCaminoBalanzaDestino:
        case EstadoViaje.rutaCompletada:
        case EstadoViaje.carguioCompletado:
          return ViajeEnCaminoView(controller: controller);

        case EstadoViaje.esperandoCarguio:
          return ViajeTurnoCargaView(controller: controller);

        case EstadoViaje.cargandoMineral:
          return ViajeCargandoView(controller: controller);

        case EstadoViaje.pesajeBalanzaCoop:
        case EstadoViaje.pesajeBalanzaDestino:
          return ViajePesajeView(controller: controller);

        case EstadoViaje.descargando:
          return ViajeDescargaView(controller: controller);

        case EstadoViaje.completado:
          return ViajeCompletadoView(controller: controller);

        default:
          return ViajeEnCaminoView(controller: controller);
      }
    });
  }
}
