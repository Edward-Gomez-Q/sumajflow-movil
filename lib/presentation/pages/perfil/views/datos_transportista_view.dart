// lib/presentation/pages/perfil/views/datos_transportista_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/presentation/getx/perfil_controller.dart';
import 'package:sumajflow_movil/data/models/perfil_models.dart';

class DatosTransportistaView extends StatefulWidget {
  const DatosTransportistaView({super.key});

  @override
  State<DatosTransportistaView> createState() => _DatosTransportistaViewState();
}

class _DatosTransportistaViewState extends State<DatosTransportistaView> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<PerfilController>();

  late TextEditingController _colorController;
  late TextEditingController _categoriaLicenciaController;
  late TextEditingController _fechaVencimientoController;

  DateTime? _fechaVencimientoSeleccionada;
  bool _guardando = false;

  final List<String> _categoriasLicencia = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _colorController = TextEditingController();
    _categoriaLicenciaController = TextEditingController();
    _fechaVencimientoController = TextEditingController();

    // ✅ Cargar datos del transportista al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  /// ✅ Cargar datos del transportista desde el endpoint específico
  Future<void> _cargarDatos() async {
    await controller.cargarDatosTransportista();

    if (mounted && controller.transportistaDetalle.value != null) {
      _initControllers();
    }
  }

  void _initControllers() {
    final transportista = controller.transportistaDetalle.value;
    if (transportista == null) return;

    _colorController.text = transportista.colorVehiculo ?? '';
    _categoriaLicenciaController.text = transportista.categoriaLicencia ?? '';
    _fechaVencimientoController.text =
        transportista.fechaVencimientoLicencia ?? '';

    if (transportista.fechaVencimientoLicencia != null &&
        transportista.fechaVencimientoLicencia!.isNotEmpty) {
      try {
        _fechaVencimientoSeleccionada = DateTime.parse(
          transportista.fechaVencimientoLicencia!,
        );
      } catch (e) {
        debugPrint('Error parsing fecha: $e');
      }
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _categoriaLicenciaController.dispose();
    _fechaVencimientoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Datos del Vehículo'), elevation: 0),
      body: Obx(() {
        // ✅ Mostrar loading mientras carga
        if (controller.isLoadingTransportista.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final transportista = controller.transportistaDetalle.value;

        // ✅ Mostrar error si no hay datos
        if (transportista == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('No se encontraron datos del transportista'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cargarDatos,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              _buildInfoCard(theme),
              const SizedBox(height: 32),

              // ========== DATOS BLOQUEADOS ==========
              _buildSectionTitle(theme, 'Información del Vehículo'),
              const SizedBox(height: 16),

              _buildLockedField(
                theme: theme,
                label: 'Placa del Vehículo',
                value: transportista.placaVehiculo ?? 'N/A',
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 16),

              _buildLockedField(
                theme: theme,
                label: 'Marca',
                value: transportista.marcaVehiculo ?? 'N/A',
                icon: Icons.directions_car,
              ),
              const SizedBox(height: 16),

              _buildLockedField(
                theme: theme,
                label: 'Modelo',
                value: transportista.modeloVehiculo ?? 'N/A',
                icon: Icons.build,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildLockedField(
                      theme: theme,
                      label: 'Peso Tara',
                      value: transportista.pesoTara != null
                          ? '${transportista.pesoTara} Kg'
                          : 'N/A',
                      icon: Icons.scale,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLockedField(
                      theme: theme,
                      label: 'Capacidad',
                      value: transportista.capacidadCarga != null
                          ? '${transportista.capacidadCarga} Kg'
                          : 'N/A',
                      icon: Icons.inventory_2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ========== CAMPOS EDITABLES ==========
              _buildSectionTitle(theme, 'Información Editable'),
              const SizedBox(height: 16),

              _buildModernTextField(
                controller: _colorController,
                label: 'Color del Vehículo',
                icon: Icons.palette,
                hint: 'Ej: Blanco, Rojo',
              ),
              const SizedBox(height: 20),

              _buildModernDropdown(
                value:
                    _categoriasLicencia.contains(
                      _categoriaLicenciaController.text,
                    )
                    ? _categoriaLicenciaController.text
                    : null,
                label: 'Categoría de Licencia',
                icon: Icons.card_membership,
                hint: 'Selecciona categoría',
                items: _categoriasLicencia,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _categoriaLicenciaController.text = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              _buildDatePicker(theme),
              const SizedBox(height: 40),

              _buildModernSaveButton(theme),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.local_shipping,
            color: theme.colorScheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datos del Vehículo',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Información de tu vehículo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(Icons.lock, color: theme.colorScheme.surface, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Los datos de placa, marca, modelo, peso tara y capacidad no pueden modificarse por temas de trazabilidad',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedField({
    required ThemeData theme,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                color: theme.colorScheme.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text('Categoría $item'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Fecha de Vencimiento de Licencia',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  _fechaVencimientoSeleccionada ??
                  DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              helpText: 'Selecciona fecha de vencimiento',
              cancelText: 'Cancelar',
              confirmText: 'Confirmar',
            );

            if (picked != null && mounted) {
              setState(() {
                _fechaVencimientoSeleccionada = picked;
                _fechaVencimientoController.text =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fechaVencimientoSeleccionada == null
                        ? 'Selecciona fecha de vencimiento'
                        : _formatearFechaDisplay(
                            _fechaVencimientoSeleccionada!,
                          ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: _fechaVencimientoSeleccionada == null
                          ? FontWeight.normal
                          : FontWeight.w500,
                      color: _fechaVencimientoSeleccionada == null
                          ? theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.5,
                            )
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSaveButton(ThemeData theme) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _guardando ? null : _guardarCambios,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _guardando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Guardar Cambios',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _formatearFechaDisplay(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final transportistaActual = controller.transportistaDetalle.value;
    if (transportistaActual == null) return;

    setState(() => _guardando = true);

    final transportista = TransportistaPerfilModel(
      id: transportistaActual.id,
      ci: transportistaActual.ci,
      placaVehiculo: transportistaActual.placaVehiculo,
      marcaVehiculo: transportistaActual.marcaVehiculo,
      modeloVehiculo: transportistaActual.modeloVehiculo,
      pesoTara: transportistaActual.pesoTara,
      capacidadCarga: transportistaActual.capacidadCarga,
      estado: transportistaActual.estado,
      // ✅ Campos editables
      colorVehiculo: _colorController.text.isNotEmpty
          ? _colorController.text
          : null,
      categoriaLicencia: _categoriaLicenciaController.text.isNotEmpty
          ? _categoriaLicenciaController.text
          : null,
      fechaVencimientoLicencia: _fechaVencimientoController.text.isNotEmpty
          ? _fechaVencimientoController.text
          : null,
    );

    final success = await controller.actualizarDatosTransportista(
      transportista,
    );

    setState(() => _guardando = false);

    if (success && mounted) {
      context.pop();
    }
  }
}
