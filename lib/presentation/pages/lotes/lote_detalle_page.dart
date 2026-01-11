// lib/presentation/pages/lotes/lote_detalle_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:sumajflow_movil/presentation/getx/lote_detalle_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/maps/map_four_waypoints.dart';

class LoteDetallePage extends StatefulWidget {
  final int asignacionId;

  const LoteDetallePage({super.key, required this.asignacionId});

  @override
  State<LoteDetallePage> createState() => _LoteDetallePageState();
}

class _LoteDetallePageState extends State<LoteDetallePage> {
  late final LoteDetalleController controller;
  late final String controllerTag;

  @override
  void initState() {
    super.initState();

    controllerTag = 'lote_detalle_${widget.asignacionId}';

    controller = Get.put(
      LoteDetalleController(widget.asignacionId),
      tag: controllerTag,
    );
  }

  @override
  void dispose() {
    print('🗑️ Eliminando LoteDetalleController - Tag: $controllerTag');
    Get.delete<LoteDetalleController>(tag: controllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    //   Configurar navegación
    controller.configurarNavegacion(() {
      context.push('${RouteNames.trazabilidad}/${widget.asignacionId}');
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de Viaje'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.refrescar,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState(theme);
        }

        final lote = controller.loteDetalle.value;
        if (lote == null) {
          return _buildErrorState(theme);
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refrescar,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactHeader(theme, lote, controller),
                      _buildMapa(lote),
                      _buildInfoViaje(theme, lote),
                      _buildWaypoints(theme, lote, controller),
                      _buildInfoSocio(theme, lote),
                      _buildInfoCamion(theme, lote),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (!controller.mostrarBotonPrincipal) {
          return const SizedBox.shrink();
        }

        return _buildBottomButton(theme, controller, context);
      }),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando información del viaje...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(
    ThemeData theme,
    LoteDetalleViajeModel lote,
    LoteDetalleController controller,
  ) {
    final colorEstado = _hexToColor(controller.colorEstado);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ID #${lote.codigoLote.split('-').last}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorEstado.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  controller.estadoDescriptivo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(controller.progresoViaje * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorEstado,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: controller.progresoViaje),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapa(LoteDetalleViajeModel lote) {
    if (!lote.tieneRutaCompleta) {
      return Container(
        height: 280,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Mapa no disponible',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MapFourWaypoints(waypoints: lote.waypoints, height: 320);
  }

  Widget _buildInfoViaje(ThemeData theme, LoteDetalleViajeModel lote) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del Viaje',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                _buildSimpleInfoRow(
                  theme,
                  label: 'Distancia',
                  value: lote.distanciaDisplay,
                ),
                Divider(
                  height: 24,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                _buildSimpleInfoRow(
                  theme,
                  label: 'Tiempo Estimado',
                  value: lote.tiempoEstimadoDisplay,
                ),
                Divider(
                  height: 24,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                _buildSimpleInfoRow(
                  theme,
                  label: 'Tipo Mineral',
                  value: _formatTipoMineral(lote.tipoMineral),
                ),
                Divider(
                  height: 24,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                _buildSimpleInfoRow(
                  theme,
                  label: 'Destino',
                  value: lote.destinoTipo,
                ),
              ],
            ),
          ),
          if (lote.mineralTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lote.mineralTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoRow(
    ThemeData theme, {
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildWaypoints(
    ThemeData theme,
    LoteDetalleViajeModel lote,
    LoteDetalleController controller,
  ) {
    final waypoints = lote.waypoints;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ruta del Viaje',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...waypoints.asMap().entries.map((entry) {
            final index = entry.key;
            final waypoint = entry.value;
            final isActive = controller.pasoActual >= waypoint.orden;
            final color = _hexToColor(waypoint.color);

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isActive
                                ? color
                                : theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              waypoint.orden.toString(),
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.4,
                                      ),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        if (waypoint.orden < waypoints.length)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 2,
                            height: 44,
                            color: isActive
                                ? color.withOpacity(0.4)
                                : theme.colorScheme.surfaceContainerHighest,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? color.withOpacity(0.2)
                                : theme.colorScheme.outline.withOpacity(0.1),
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? color.withOpacity(0.1)
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    waypoint.iconoEmoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    waypoint.tituloDescriptivo,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface
                                                .withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              waypoint.nombre,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoSocio(ThemeData theme, LoteDetalleViajeModel lote) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Socio',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              icon: Icons.person_outline_rounded,
              label: 'Nombre',
              value: lote.socioNombre ?? 'No disponible',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              icon: Icons.phone_rounded,
              label: 'Teléfono',
              value: lote.socioTelefono ?? 'No disponible',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              icon: Icons.place_rounded,
              label: 'Mina',
              value: lote.minaNombre,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCamion(ThemeData theme, LoteDetalleViajeModel lote) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Camión',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              icon: Icons.local_shipping_rounded,
              label: 'Número de Camión',
              value: '#${lote.numeroCamion}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              icon: Icons.inventory_rounded,
              label: 'Total de Camiones',
              value: '${lote.totalCamiones} camiones',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(
    ThemeData theme,
    LoteDetalleController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton(
          onPressed: () =>
              controller.onPresionarBotonPrincipal(Get.context ?? context),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            controller.textoBotonPrincipal,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: theme.colorScheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No se pudo cargar el viaje',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta nuevamente más tarde',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _formatTipoMineral(String tipo) {
    switch (tipo) {
      case 'bruto':
        return 'Bruto';
      case 'concentrado':
        return 'Concentrado';
      default:
        return tipo;
    }
  }
}
