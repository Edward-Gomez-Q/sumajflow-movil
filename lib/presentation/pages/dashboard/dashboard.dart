//lib/presentation/pages/dashboard/dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/presentation/getx/dashboard_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/cards/lote_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SumajFlow')),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.refrescar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(theme),
                  const SizedBox(height: 24),
                  _buildLoteActivo(theme, controller, context),
                  const SizedBox(height: 24),
                  _buildEstadisticas(theme, controller, context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Buenos días';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 19) {
      greeting = 'Buenas tardes';
      greetingIcon = Icons.wb_twilight_outlined;
    } else {
      greeting = 'Buenas noches';
      greetingIcon = Icons.nightlight_outlined;
    }

    return Row(
      children: [
        Icon(greetingIcon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Text(
          greeting,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoteActivo(
    ThemeData theme,
    DashboardController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final loteActivo = controller.loteActivo;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lote Activo',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (loteActivo != null)
                TextButton.icon(
                  onPressed: () {
                    context.push(
                      '${RouteNames.loteDetalle}/${loteActivo.asignacionId}',
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Ver detalles'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loteActivo == null)
            _buildEmptyLoteState(theme)
          else
            LoteCard(
              loteCode: loteActivo.loteId.toString(),
              destino: loteActivo.destinoNombre ?? loteActivo.minaNombre,
              estado: loteActivo.estadoDisplay,
              fecha: _formatearFecha(loteActivo.fechaAsignacion),
              onTap: () {
                context.push(
                  '${RouteNames.loteDetalle}/${loteActivo.asignacionId}',
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildEmptyLoteState(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin lote activo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu próximo lote asignado aparecerá aquí',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas(
    ThemeData theme,
    DashboardController controller,
    BuildContext context,
  ) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  context.go(RouteNames.lotes);
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Historial'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cards en vertical - diseño limpio
          _buildStatCard(
            theme,
            icon: Icons.check_circle_outline,
            title: 'Lotes Completados',
            value: controller.totalCompletados.value.toString(),
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            theme,
            icon: Icons.local_shipping_outlined,
            title: 'Lotes en Tránsito',
            value: controller.totalEnTransito.value.toString(),
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            theme,
            icon: Icons.route_outlined,
            title: 'Distancia Total Recorrida',
            value: '${controller.totalDistanciaKm.value.toStringAsFixed(1)} km',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            theme,
            icon: Icons.schedule_outlined,
            title: 'Tiempo Total de Viaje',
            value: '${controller.totalHorasViaje.value.toStringAsFixed(1)} hrs',
            color: Colors.purple,
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }
}
