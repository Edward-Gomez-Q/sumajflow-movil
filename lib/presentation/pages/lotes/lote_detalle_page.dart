// lib/presentation/pages/lotes/lote_detalle_page.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/core/theme/colors.dart';
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
    debugPrint('🗑️ Eliminando LoteDetalleController - Tag: $controllerTag');
    Get.delete<LoteDetalleController>(tag: controllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Configurar navegación
    controller.configurarNavegacion(() {
      context.push('${RouteNames.trazabilidad}/${widget.asignacionId}');
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.route,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Detalle de Viaje'),
          ],
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
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
                      _buildHeader(theme, lote, controller),
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
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.truckFast,
                size: 14,
                color: AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Cargando información del viaje...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    LoteDetalleViajeModel lote,
    LoteDetalleController controller,
  ) {
    final colorEstado = _hexToColor(controller.colorEstado);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: ID y Estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.lightBorder, width: 1),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.hashtag,
                      size: 11,
                      color: AppColors.lightTextPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lote.codigoLote.split('-').last,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
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
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      _getIconoByEstado(controller.estadoDescriptivo),
                      size: 10,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.estadoDescriptivo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Barra de progreso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.chartLine,
                    size: 12,
                    color: AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Progreso del viaje',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '${(controller.progresoViaje * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorEstado,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Barra de progreso simple y limpia
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: controller.progresoViaje,
              child: Container(
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
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
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.mapLocationDot,
                size: 36,
                color: AppColors.lightTextTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                'Mapa no disponible',
                style: TextStyle(
                  color: AppColors.lightTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'La ruta se mostrará cuando esté completa',
                style: TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: MapFourWaypoints(waypoints: lote.waypoints, height: 320),
    );
  }

  Widget _buildInfoViaje(ThemeData theme, LoteDetalleViajeModel lote) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Información del Viaje',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoRow(
            theme,
            icon: FontAwesomeIcons.route,
            label: 'Distancia',
            value: lote.distanciaDisplay,
          ),

          const Divider(height: 24),

          _buildInfoRow(
            theme,
            icon: FontAwesomeIcons.clock,
            label: 'Tiempo Estimado',
            value: lote.tiempoEstimadoDisplay,
          ),

          const Divider(height: 24),

          _buildInfoRow(
            theme,
            icon: FontAwesomeIcons.gem,
            label: 'Tipo Mineral',
            value: _formatTipoMineral(lote.tipoMineral),
          ),

          const Divider(height: 24),

          _buildInfoRow(
            theme,
            icon: FontAwesomeIcons.flagCheckered,
            label: 'Destino',
            value: lote.destinoTipo,
          ),

          if (lote.mineralTags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lote.mineralTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.tag,
                        size: 10,
                        color: AppColors.lightTextPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: FaIcon(icon, size: 14, color: AppColors.lightTextPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.mapLocationDot,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Ruta del Viaje',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...waypoints.asMap().entries.map((entry) {
            final index = entry.key;
            final waypoint = entry.value;
            final isActive = controller.pasoActual >= waypoint.orden;
            final color = _hexToColor(waypoint.color);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < waypoints.length - 1 ? 12 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador circular
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isActive ? color : AppColors.lightBorder,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isActive
                              ? const FaIcon(
                                  FontAwesomeIcons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : Text(
                                  waypoint.orden.toString(),
                                  style: const TextStyle(
                                    color: AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      if (waypoint.orden < waypoints.length)
                        Container(
                          width: 2,
                          height: 40,
                          color: isActive
                              ? color.withValues(alpha: 0.3)
                              : AppColors.lightBorder,
                        ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Información del waypoint
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withValues(alpha: 0.05)
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? color.withValues(alpha: 0.3)
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                            _getIconoByWaypoint(waypoint.iconoEmoji),
                            size: 16,
                            color: isActive
                                ? color
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  waypoint.tituloDescriptivo,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? AppColors.lightTextPrimary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  waypoint.nombre,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.lightTextSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoSocio(ThemeData theme, LoteDetalleViajeModel lote) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.userTie,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Información del Socio',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSimpleInfoRow(
            theme,
            icon: FontAwesomeIcons.user,
            label: 'Nombre',
            value: lote.socioNombre ?? 'No disponible',
          ),

          const SizedBox(height: 12),

          _buildSimpleInfoRow(
            theme,
            icon: FontAwesomeIcons.phone,
            label: 'Teléfono',
            value: lote.socioTelefono ?? 'No disponible',
          ),

          const SizedBox(height: 12),

          _buildSimpleInfoRow(
            theme,
            icon: FontAwesomeIcons.mountain,
            label: 'Mina',
            value: lote.minaNombre,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCamion(ThemeData theme, LoteDetalleViajeModel lote) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.truck,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Información del Camión',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSimpleInfoRow(
            theme,
            icon: FontAwesomeIcons.truckFast,
            label: 'Número de Camión',
            value: '#${lote.numeroCamion}',
          ),

          const SizedBox(height: 12),

          _buildSimpleInfoRow(
            theme,
            icon: FontAwesomeIcons.boxesStacked,
            label: 'Total de Camiones',
            value: '${lote.totalCamiones} camiones',
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: FaIcon(icon, size: 14, color: AppColors.lightTextPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightTextPrimary,
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
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.lightBorder, width: 1)),
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: () =>
              controller.onPresionarBotonPrincipal(Get.context ?? context),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          icon: const FaIcon(FontAwesomeIcons.arrowRight, size: 16),
          label: Text(
            controller.textoBotonPrincipal,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
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
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.lightBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 32,
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No se pudo cargar el viaje',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta nuevamente más tarde',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: controller.refrescar,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _formatTipoMineral(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'bruto':
        return 'Bruto';
      case 'concentrado':
        return 'Concentrado';
      default:
        return tipo;
    }
  }

  IconData _getIconoByEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'iniciado':
        return FontAwesomeIcons.play;
      case 'en camino':
        return FontAwesomeIcons.truckFast;
      case 'llegada mina':
        return FontAwesomeIcons.mountain;
      case 'esperando carguío':
        return FontAwesomeIcons.hourglassHalf;
      case 'cargando':
        return FontAwesomeIcons.truckRampBox;
      case 'pesaje':
        return FontAwesomeIcons.scaleBalanced;
      case 'llegada almacén':
        return FontAwesomeIcons.warehouse;
      case 'descarga':
        return FontAwesomeIcons.boxOpen;
      case 'completado':
        return FontAwesomeIcons.circleCheck;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  IconData _getIconoByWaypoint(String emoji) {
    switch (emoji) {
      case '🏁':
        return FontAwesomeIcons.flagCheckered;
      case '🚛':
        return FontAwesomeIcons.truck;
      case '⛏️':
        return FontAwesomeIcons.mountain;
      case '⏳':
        return FontAwesomeIcons.hourglassHalf;
      case '📦':
        return FontAwesomeIcons.box;
      case '⚖️':
        return FontAwesomeIcons.scaleBalanced;
      case '🏭':
        return FontAwesomeIcons.warehouse;
      case '📍':
        return FontAwesomeIcons.locationDot;
      case '✅':
        return FontAwesomeIcons.circleCheck;
      case '🎯':
        return FontAwesomeIcons.bullseye;
      default:
        return FontAwesomeIcons.mapPin;
    }
  }
}
