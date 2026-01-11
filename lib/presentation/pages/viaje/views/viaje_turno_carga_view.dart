// lib/presentation/pages/viaje/views/viaje_turno_carga_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_observacion_field.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';

class ViajeTurnoCargaView extends StatelessWidget {
  final ViajeController controller;

  const ViajeTurnoCargaView({super.key, required this.controller});

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

                  // Icono de espera
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    ),
                    child: const Center(
                      child: Text('⏳', style: TextStyle(fontSize: 56)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Esperando Turno de Carga',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Espera tu turno para iniciar la carga del mineral.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  ViajeObservacionField(
                    label: 'Observaciones',
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
