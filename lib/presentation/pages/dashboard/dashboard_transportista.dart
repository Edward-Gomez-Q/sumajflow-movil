// lib/presentation/pages/dashboard/dashboard_transportista.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/services/offline_storage_service.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/presentation/getx/lotes_controller.dart';

class DashboardTransportista extends StatelessWidget {
  const DashboardTransportista({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LotesController());
    final theme = Theme.of(context);
    final authService = AuthService.to;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis Lotes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Obx(
              () => Text(
                authService.correo ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // Indicador de datos pendientes
          Obx(() {
            final pendientes =
                OfflineStorageService.to.pendingLocationsCount.value;
            if (pendientes > 0) {
              return Badge(
                label: Text('$pendientes'),
                child: IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  onPressed: () => _mostrarPendientes(context),
                  tooltip: 'Datos pendientes de sincronizar',
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmarCerrarSesion(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refrescarLotes,
        child: Column(
          children: [
            // Filtros
            _buildFiltros(controller, theme),

            // Estadísticas rápidas
            _buildEstadisticas(controller, theme),

            // Lista de lotes
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.isNotEmpty) {
                  return _buildErrorView(controller, theme);
                }

                if (controller.lotes.isEmpty) {
                  return _buildEmptyView(controller, theme);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.lotes.length,
                  itemBuilder: (context, index) {
                    final lote = controller.lotes[index];
                    return LoteCard(
                      lote: lote,
                      onTap: () => _navegarADetalle(context, lote),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(LotesController controller, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        () => Row(
          children: [
            FiltroChip(
              label: 'Activos',
              isSelected: controller.filtroActual.value == 'activos',
              count: controller.cantidadActivos,
              onTap: () => controller.cambiarFiltro('activos'),
            ),
            const SizedBox(width: 8),
            FiltroChip(
              label: 'Completados',
              isSelected: controller.filtroActual.value == 'completados',
              count: controller.cantidadCompletados,
              onTap: () => controller.cambiarFiltro('completados'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas(LotesController controller, ThemeData theme) {
    return Obx(() {
      final pendientes = controller.lotesPendientes.length;
      final enCurso = controller.lotesEnCurso.length;

      if (pendientes == 0 && enCurso == 0) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (pendientes > 0) ...[
              _StatItem(
                icon: Icons.pending_actions,
                label: 'Pendientes',
                value: '$pendientes',
              ),
              const SizedBox(width: 24),
            ],
            if (enCurso > 0)
              _StatItem(
                icon: Icons.local_shipping,
                label: 'En curso',
                value: '$enCurso',
              ),
          ],
        ),
      );
    });
  }

  Widget _buildErrorView(LotesController controller, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Error al cargar lotes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(controller.errorMessage.value, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.cargarLotes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(LotesController controller, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              controller.filtroActual.value == 'activos'
                  ? 'No tienes lotes activos'
                  : 'No tienes lotes completados',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Los lotes asignados aparecerán aquí'),
          ],
        ),
      ),
    );
  }

  void _navegarADetalle(BuildContext context, LoteAsignadoModel lote) {
    context.push('/lote/${lote.asignacionId}');
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.to.clearAuthData();
              if (context.mounted) context.go('/home');
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _mostrarPendientes(BuildContext context) {
    final pendientes = OfflineStorageService.to.pendingLocationsCount.value;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Datos pendientes'),
        content: Text(
          'Tienes $pendientes ubicaciones pendientes de sincronizar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FiltroChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const FiltroChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoteCard extends StatelessWidget {
  final LoteAsignadoModel lote;
  final VoidCallback onTap;

  const LoteCard({super.key, required this.lote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lote.codigoLote,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  EstadoChip(estado: lote.estado),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Destino: ${lote.tipoOperacion == 'procesamiento_planta' ? 'Ingenio' : 'Comercializadora'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.terrain,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lote.minaNombre,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: lote.mineralTags
                    .map((tag) => MineralTag(tag: tag))
                    .toList(),
              ),
              if (lote.estaPendienteIniciar) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Comenzar Viaje'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (estado) {
      case 'asignado':
      case 'Esperando iniciar':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'Viaje terminado':
        color = Colors.green;
        label = 'Completado';
        break;
      default:
        color = Colors.blue;
        label = estado;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class MineralTag extends StatelessWidget {
  final String tag;
  const MineralTag({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (tag.toLowerCase()) {
      case 'ag':
        color = Colors.grey;
        break;
      case 'pb':
        color = Colors.blueGrey;
        break;
      case 'zn':
        color = Colors.teal;
        break;
      default:
        color = Colors.purple;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
