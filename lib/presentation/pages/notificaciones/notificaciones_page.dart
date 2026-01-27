// lib/presentation/pages/notificaciones/notificaciones_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/notificaciones_controller.dart';

class NotificacionesPage extends StatelessWidget {
  const NotificacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificacionesController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        elevation: 0,
        actions: [
          // Botón de marcar todas como leídas
          Obx(() {
            return controller.hayNoLeidas
                ? IconButton(
                    icon: const Icon(Icons.done_all),
                    tooltip: 'Marcar todas como leídas',
                    onPressed: () =>
                        _showMarcarTodasDialog(context, controller),
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          // Filtros (nuevo estilo consistente con lotes)
          _buildFiltros(theme, controller),
          const SizedBox(height: 16),

          // Lista de notificaciones
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final notificaciones = controller.notificacionesVisibles;

              if (notificaciones.isEmpty) {
                return _buildEmptyState(theme, controller);
              }

              return RefreshIndicator(
                onRefresh: controller.refrescar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notificaciones.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notificacion = notificaciones[index];
                    return _NotificationCard(
                      notificacion: notificacion,
                      onTap: () async {
                        if (!notificacion.leido) {
                          await controller.marcarComoLeida(notificacion.id);
                        }
                      },
                      onDelete: () {
                        _showDeleteDialog(context, controller, notificacion);
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(ThemeData theme, NotificacionesController controller) {
    final filters = ['Todas', 'No leídas'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];

          // Cada FilterChip tiene su propio Obx
          return Obx(() {
            final isSelected =
                (filter == 'Todas' &&
                    controller.filtroActual.value == 'todas') ||
                (filter == 'No leídas' &&
                    controller.filtroActual.value == 'noLeidas');

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  final filtroValue = filter == 'Todas' ? 'todas' : 'noLeidas';
                  controller.cambiarFiltro(filtroValue);
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    NotificacionesController controller,
  ) {
    final isFiltered = controller.filtroActual.value == 'noLeidas';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.check_circle_outline : Icons.notifications_none,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? '¡Todo al día!' : 'No hay notificaciones',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isFiltered
                  ? 'No tienes notificaciones sin leer'
                  : 'Te avisaremos cuando haya actualizaciones',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showMarcarTodasDialog(
    BuildContext context,
    NotificacionesController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar todas como leídas'),
        content: const Text(
          '¿Estás seguro de que deseas marcar todas las notificaciones como leídas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.marcarTodasComoLeidas();
            },
            child: const Text('Marcar todas'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    NotificacionesController controller,
    notificacion,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta notificación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.eliminarNotificacion(notificacion.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// Widget para cada tarjeta de notificación
class _NotificationCard extends StatelessWidget {
  final notificacion;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notificacion,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getIconForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'info':
        return Icons.info_outline;
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String tipo, ThemeData theme) {
    switch (tipo.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return theme.colorScheme.error;
      case 'update':
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notificacion.leido;
    final iconColor = _getColorForType(notificacion.tipo, theme);

    return Dismissible(
      key: Key('notificacion_${notificacion.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar notificación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta notificación?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: Card(
        elevation: isRead ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isRead
              ? BorderSide.none
              : BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isRead
                  ? null
                  : theme.colorScheme.primary.withValues(alpha: 0.03),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícono
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(notificacion.tipo),
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notificacion.titulo,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Mensaje
                      Text(
                        notificacion.mensaje,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Tiempo
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notificacion.time,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
