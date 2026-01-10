//lib/presentation/pages/dashboard/dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/presentation/getx/dashboard_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/cards/info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/cards/lote_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializar el controller
    final controller = Get.put(DashboardController());
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          // Mostrar loading solo en la carga inicial
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
                  // Saludo personalizado
                  _buildGreeting(theme),
                  const SizedBox(height: 24),

                  // Cards de información
                  _buildInfoCards(controller),
                  const SizedBox(height: 24),

                  // Lotes activos
                  _buildActiveLotes(theme, controller, context),
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

    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 19) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AuthService.to.correo ?? 'Transportista',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards(DashboardController controller) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: InfoCard(
              icon: Icons.local_shipping_outlined,
              title: 'En Tránsito',
              value: controller.totalEnTransito.value.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InfoCard(
              icon: Icons.check_circle_outline,
              title: 'Completados',
              value: controller.totalCompletados.value.toString(),
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLotes(
    ThemeData theme,
    DashboardController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final lotesParaMostrar = controller.lotesParaDashboard;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lotes Activos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navegar a la pantalla de lotes
                  context.push('/lotes');
                },
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mostrar mensaje si no hay lotes
          if (lotesParaMostrar.isEmpty)
            _buildEmptyState(theme)
          else
            // Mostrar los lotes
            ...lotesParaMostrar.map(
              (lote) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LoteCard(
                  loteCode: lote.codigoLote,
                  destino: lote.destinoNombre ?? lote.minaNombre,
                  estado: lote.estadoDisplay,
                  fecha: _formatearFecha(lote.fechaAsignacion),
                  onTap: () {
                    // Navegar a detalle del lote
                    context.push('/lote/${lote.asignacionId}');
                  },
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes lotes activos',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los lotes asignados aparecerán aquí',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
