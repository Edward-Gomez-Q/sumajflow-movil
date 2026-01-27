//lib/presentation/pages/lotes/lotes_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/presentation/getx/dashboard_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/cards/lote_card.dart';

class LotesPage extends StatefulWidget {
  const LotesPage({super.key});

  @override
  State<LotesPage> createState() => _LotesPageState();
}

class _LotesPageState extends State<LotesPage> {
  final _searchController = TextEditingController();
  late final DashboardController _controller;

  final List<String> _filters = [
    'Todos',
    'Pendiente',
    'En Tránsito',
    'Completado',
  ];

  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();

    // Inicializar controller
    if (Get.isRegistered<DashboardController>()) {
      _controller = Get.find<DashboardController>();
    } else {
      _controller = Get.put(DashboardController());
    }

    // CORRECCIÓN: Asegurar que se cargan todos los lotes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.todosLosLotes.isEmpty) {
        _controller.cargarTodosLosLotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lotes')),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por código o destino',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchController.clear());
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filtros
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                      _controller.cambiarFiltro(_mapearFiltroUI(filter));
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Lista de lotes
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Obtener lotes según el filtro seleccionado
              var lotes = _obtenerLotesFiltrados();

              // Aplicar filtro de búsqueda local
              if (_searchController.text.isNotEmpty) {
                final query = _searchController.text.toLowerCase();
                lotes = lotes.where((lote) {
                  return lote.codigoLote.toLowerCase().contains(query) ||
                      (lote.destinoNombre?.toLowerCase().contains(query) ??
                          false) ||
                      lote.minaNombre.toLowerCase().contains(query);
                }).toList();
              }

              if (lotes.isEmpty) {
                return _buildEmptyState(theme);
              }

              return RefreshIndicator(
                onRefresh: _controller.refrescar,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lotes.length,
                  itemBuilder: (context, index) {
                    final lote = lotes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LoteCard(
                        loteCode: lote.loteId.toString(),
                        destino: lote.destinoNombre ?? lote.minaNombre,
                        estado: lote.estadoDisplay,
                        fecha: _formatearFecha(lote.fechaAsignacion),
                        onTap: () {
                          context.push(
                            '${RouteNames.loteDetalle}/${lote.asignacionId}',
                          );
                        },
                      ),
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

  // NUEVO: Mapear filtro UI a filtro del controller
  String _mapearFiltroUI(String filtroUI) {
    switch (filtroUI) {
      case 'Pendiente':
      case 'En Tránsito':
        return 'activos';
      case 'Completado':
        return 'completados';
      default: // 'Todos'
        return 'todos';
    }
  }

  // NUEVO: Obtener lotes filtrados según la selección
  List<dynamic> _obtenerLotesFiltrados() {
    switch (_selectedFilter) {
      case 'Pendiente':
        return _controller.lotesActivos
            .where((lote) => lote.estaPendienteIniciar)
            .toList();
      case 'En Tránsito':
        return _controller.lotesActivos
            .where((lote) => lote.estaEnCurso)
            .toList();
      case 'Completado':
        return _controller.lotesCompletados;
      default: // 'Todos'
        return _controller.todosLosLotes;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron lotes',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros filtros',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
