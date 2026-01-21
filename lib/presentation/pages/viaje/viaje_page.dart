// lib/presentation/pages/viaje/viaje_page.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/data/enums/estado_viaje.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/pages/viaje/widgets/viaje_state_handler.dart';
import 'package:sumajflow_movil/presentation/widgets/dialogs/confirmar_salida_tracking_dialog.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_estado_header.dart';

class ViajePage extends StatelessWidget {
  final int asignacionId;
  final String controllerTag;
  final LoteDetalleViajeModel? loteDetalle;

  const ViajePage({
    super.key,
    required this.asignacionId,
    required this.controllerTag,
    this.loteDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ViajeController(
        asignacionId: asignacionId,
        loteDetalleInicial: loteDetalle,
      ),
      tag: controllerTag,
    );

    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirmar = await _confirmarSalida(context, controller);
        if (confirmar && context.mounted) {
          Get.delete<ViajeController>(tag: controllerTag);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context, theme, controller),
        body: Obx(() {
          if (controller.isInitializing.value) {
            return _buildInitializingState(theme);
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return _buildErrorState(theme, controller);
          }

          if (controller.isPaused) {
            return _buildPausedState(theme, controller);
          }

          return ViajeStateHandler(controller: controller);
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    ViajeController controller,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
        onPressed: () async {
          final confirmar = await _confirmarSalida(context, controller);
          if (confirmar && context.mounted) {
            Get.delete<ViajeController>(tag: controllerTag);
            Navigator.of(context).pop();
          }
        },
      ),
      title: const Text('Viaje en Curso'),
      centerTitle: true,
      actions: [
        Obx(() {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: controller.isOnline
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  controller.isOnline
                      ? FontAwesomeIcons.cloud
                      : FontAwesomeIcons.cloudArrowDown,
                  size: 12,
                  color: controller.isOnline ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: controller.isOnline ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          );
        }),
        Obx(() {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ViajeEstadoHeader(
              estado: controller.estadoActual.value,
              compacto: true,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInitializingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
                  'Preparando viaje...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verificando ubicación y estado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ViajeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 36,
                    color: theme.colorScheme.error.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al iniciar viaje',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Get.delete<ViajeController>(tag: controllerTag);
                    Get.back();
                  },
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
                  label: const Text('Volver'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: controller.refrescar,
                  icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedState(ThemeData theme, ViajeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.circlePause,
                    size: 56,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tracking pausado',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'El seguimiento de tu ubicación está detenido temporalmente',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => controller.trackingController.reanudarTracking(),
              icon: const FaIcon(FontAwesomeIcons.play, size: 16),
              label: const Text('Reanudar seguimiento'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmarSalida(
    BuildContext context,
    ViajeController controller,
  ) async {
    if (controller.isPaused ||
        controller.estadoActual.value == EstadoViaje.completado) {
      return true;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConfirmarSalidaTrackingDialog(),
    );

    if (confirmar == true) {
      controller.trackingController.pausarTracking();
      return true;
    }

    return false;
  }
}
