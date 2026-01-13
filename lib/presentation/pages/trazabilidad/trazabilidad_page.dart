// lib/presentation/pages/trazabilidad/trazabilidad_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:sumajflow_movil/presentation/getx/trazabilidad_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/dialogs/confirmar_salida_tracking_dialog.dart';
import 'package:sumajflow_movil/presentation/widgets/maps/mapa_trazabilidad_widget.dart';

class TrazabilidadPage extends StatelessWidget {
  final int asignacionId;
  final String controllerTag;
  final LoteDetalleViajeModel? loteDetalle;

  const TrazabilidadPage({
    super.key,
    required this.asignacionId,
    required this.controllerTag,
    this.loteDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      TrazabilidadController(
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
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          //   Sobrescribir el botón de atrás
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final confirmar = await _confirmarSalida(context, controller);
              if (confirmar && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text('Viaje en Curso'),
          actions: [
            //   Indicador de conexión
            Obx(() {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: controller.isOnline.value
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isOnline.value
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      size: 16,
                      color: controller.isOnline.value
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.isOnline.value ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: controller.isOnline.value
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }),

            //   Indicador de estado
            Obx(() {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getEstadoColor(controller.estadoViaje.value),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getEstadoTexto(controller.estadoViaje.value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isInitializing.value) {
            return _buildInitializingState(theme);
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return _buildErrorState(theme, controller);
          }

          //   Mostrar overlay si está pausado
          if (controller.isPaused.value) {
            return _buildPausedState(theme, controller);
          }

          return _buildMainView(theme, controller);
        }),
      ),
    );
  }

  /// Función para confirmar salida
  Future<bool> _confirmarSalida(
    BuildContext context,
    TrazabilidadController controller,
  ) async {
    // Si el tracking ya está pausado, permitir salir directamente
    if (controller.isPaused.value) {
      return true;
    }

    // Mostrar dialog de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConfirmarSalidaTrackingDialog(),
    );

    if (confirmar == true) {
      // Pausar el tracking antes de salir
      controller.pausarTracking();
      return true;
    }

    return false;
  }

  ///   Estado pausado con botón para reanudar
  Widget _buildPausedState(ThemeData theme, TrazabilidadController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange, Colors.orange.withValues(alpha: 0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.pause_circle_rounded,
                size: 60,
                color: Colors.white,
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
              onPressed: controller.reanudarTracking,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Reanudar seguimiento'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitializingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Iniciando viaje...',
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
    );
  }

  Widget _buildErrorState(ThemeData theme, TrazabilidadController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al iniciar viaje',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView(ThemeData theme, TrazabilidadController controller) {
    return Stack(
      children: [
        // Mapa a pantalla completa
        Positioned.fill(
          child: Obx(() {
            return MapaTrazabilidadWidget(
              currentPosition: controller.currentPosition.value,
              proximoWaypoint: controller.proximoWaypoint,
              estadoViaje: controller.estadoViaje.value,
            );
          }),
        ),

        // Panel de información inferior
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildInfoPanel(theme, controller),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(ThemeData theme, TrazabilidadController controller) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Próximo destino
              Obx(() {
                final waypoint = controller.proximoWaypoint;
                if (waypoint == null) {
                  return const SizedBox.shrink();
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _hexToColor(waypoint.color),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          waypoint.iconoEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próximo destino',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              waypoint.nombre,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Obx(() {
                            return Text(
                              controller.distanciaProximoWaypointTexto,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Información del viaje
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      theme,
                      icon: Icons.local_shipping_rounded,
                      label: 'Código',
                      value: controller.loteDetalle.value?.codigoLote ?? 'N/A',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      return _buildInfoCard(
                        theme,
                        icon: Icons.speed_rounded,
                        label: 'Velocidad',
                        value: controller.currentPosition.value != null
                            ? '${(controller.currentPosition.value!.speed * 3.6).toInt()} km/h'
                            : '0 km/h',
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'En camino a la mina':
      case 'En camino balanza cooperativa':
      case 'En camino balanza destino':
      case 'En camino almacén destino':
        return const Color(0xFF3B82F6); // Blue
      case 'Esperando carguío':
        return const Color(0xFF8B5CF6); // Purple
      case 'Descargando':
        return const Color(0xFFEC4899); // Pink
      case 'Completado':
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'En camino a la mina':
        return 'A la mina';
      case 'En camino balanza cooperativa':
        return 'A balanza coop';
      case 'En camino balanza destino':
        return 'A balanza destino';
      case 'En camino almacén destino':
        return 'A almacén';
      case 'Esperando carguío':
        return 'Esperando carga';
      case 'Descargando':
        return 'Descargando';
      case 'Completado':
        return 'Completado';
      default:
        return estado;
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
