// lib/presentation/pages/perfil/views/datos_personales_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/presentation/getx/perfil_controller.dart';
import 'package:sumajflow_movil/data/models/perfil_models.dart';

class DatosPersonalesView extends StatefulWidget {
  const DatosPersonalesView({super.key});

  @override
  State<DatosPersonalesView> createState() => _DatosPersonalesViewState();
}

class _DatosPersonalesViewState extends State<DatosPersonalesView> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<PerfilController>();

  late TextEditingController _nombresController;
  late TextEditingController _primerApellidoController;
  late TextEditingController _segundoApellidoController;
  late TextEditingController _ciController;
  late TextEditingController _fechaNacimientoController;
  late TextEditingController _numeroCelularController;
  late TextEditingController _departamentoController;
  late TextEditingController _provinciaController;
  late TextEditingController _municipioController;
  late TextEditingController _direccionController;

  String? _generoSeleccionado;
  DateTime? _fechaNacimientoSeleccionada;
  bool _guardando = false;

  final List<String> _generos = [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decir',
  ];

  final List<String> _departamentos = [
    'La Paz',
    'Cochabamba',
    'Santa Cruz',
    'Potosí',
    'Oruro',
    'Tarija',
    'Chuquisaca',
    'Beni',
    'Pando',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final persona = controller.perfil.value?.persona;

    _nombresController = TextEditingController(text: persona?.nombres ?? '');
    _primerApellidoController = TextEditingController(
      text: persona?.primerApellido ?? '',
    );
    _segundoApellidoController = TextEditingController(
      text: persona?.segundoApellido ?? '',
    );
    _ciController = TextEditingController(text: persona?.ci ?? '');
    _fechaNacimientoController = TextEditingController(
      text: persona?.fechaNacimiento ?? '',
    );
    _numeroCelularController = TextEditingController(
      text: persona?.numeroCelular ?? '',
    );
    _departamentoController = TextEditingController(
      text: persona?.departamento ?? '',
    );
    _provinciaController = TextEditingController(
      text: persona?.provincia ?? '',
    );
    _municipioController = TextEditingController(
      text: persona?.municipio ?? '',
    );
    _direccionController = TextEditingController(
      text: persona?.direccion ?? '',
    );

    _generoSeleccionado = persona?.genero;

    if (persona?.fechaNacimiento != null &&
        persona!.fechaNacimiento!.isNotEmpty) {
      _fechaNacimientoSeleccionada = DateTime.parse(persona.fechaNacimiento!);
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _primerApellidoController.dispose();
    _segundoApellidoController.dispose();
    _ciController.dispose();
    _fechaNacimientoController.dispose();
    _numeroCelularController.dispose();
    _departamentoController.dispose();
    _provinciaController.dispose();
    _municipioController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Información Personal'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header con icono
            _buildHeader(theme),
            const SizedBox(height: 24),

            // Info Card
            _buildInfoCard(theme),
            const SizedBox(height: 32),

            // Nombres
            _buildModernTextField(
              controller: _nombresController,
              label: 'Nombre(s)',
              icon: Icons.person_outline,
              hint: 'Ingresa tus nombres',
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Apellido Paterno
            _buildModernTextField(
              controller: _primerApellidoController,
              label: 'Apellido Paterno',
              icon: Icons.person_outline,
              hint: 'Apellido paterno',
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El apellido paterno es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Apellido Materno
            _buildModernTextField(
              controller: _segundoApellidoController,
              label: 'Apellido Materno',
              icon: Icons.person_outline,
              hint: 'Apellido materno (opcional)',
            ),
            const SizedBox(height: 20),

            // CI (Bloqueado)
            _buildLockedField(
              theme: theme,
              label: 'Carnet de Identidad',
              value: _ciController.text,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 20),

            // Fecha de Nacimiento
            _buildDatePicker(theme),
            const SizedBox(height: 20),

            // Número de Celular (Bloqueado)
            _buildLockedField(
              theme: theme,
              label: 'Número de Celular',
              value: _numeroCelularController.text,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 20),

            // Género
            _buildModernDropdown(
              value: _generoSeleccionado,
              label: 'Género',
              icon: Icons.wc_outlined,
              hint: 'Selecciona tu género',
              items: _generos,
              onChanged: (value) {
                setState(() => _generoSeleccionado = value);
              },
            ),
            const SizedBox(height: 32),

            // Sección de Dirección
            _buildSectionDivider(theme, 'Dirección'),
            const SizedBox(height: 20),

            // Departamento
            _buildModernDropdown(
              value: _departamentos.contains(_departamentoController.text)
                  ? _departamentoController.text
                  : null,
              label: 'Departamento',
              icon: Icons.location_city_outlined,
              hint: 'Selecciona tu departamento',
              items: _departamentos,
              onChanged: (value) {
                if (value != null) {
                  _departamentoController.text = value;
                }
              },
            ),
            const SizedBox(height: 20),

            // Provincia
            _buildModernTextField(
              controller: _provinciaController,
              label: 'Provincia',
              icon: Icons.map_outlined,
              hint: 'Provincia',
            ),
            const SizedBox(height: 20),

            // Municipio
            _buildModernTextField(
              controller: _municipioController,
              label: 'Municipio',
              icon: Icons.location_on_outlined,
              hint: 'Municipio',
            ),
            const SizedBox(height: 20),

            // Dirección
            _buildModernTextField(
              controller: _direccionController,
              label: 'Dirección Completa',
              icon: Icons.home_outlined,
              hint: 'Calle, número, zona...',
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            // Botón de guardar
            _buildModernSaveButton(theme),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
          child: Icon(Icons.person, color: theme.colorScheme.primary, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información Personal',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mantén tus datos actualizados',
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
            theme.colorScheme.primaryContainer.withValues(alpha: 0.99),
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
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              Icons.info_outline,
              color: theme.colorScheme.surface,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Por seguridad, el CI y número de celular no pueden modificarse',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
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
                  value.isEmpty ? 'No disponible' : value,
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

  Widget _buildDatePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                'Fecha de Nacimiento',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  _fechaNacimientoSeleccionada ??
                  DateTime.now().subtract(const Duration(days: 365 * 25)),
              firstDate: DateTime(1940),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              helpText: 'Selecciona tu fecha de nacimiento',
              cancelText: 'Cancelar',
              confirmText: 'Confirmar',
            );

            if (picked != null && mounted) {
              setState(() {
                _fechaNacimientoSeleccionada = picked;
                _fechaNacimientoController.text =
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
                  Icons.calendar_today_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fechaNacimientoSeleccionada == null
                        ? 'Selecciona tu fecha de nacimiento'
                        : _formatearFechaDisplay(_fechaNacimientoSeleccionada!),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: _fechaNacimientoSeleccionada == null
                          ? FontWeight.normal
                          : FontWeight.w500,
                      color: _fechaNacimientoSeleccionada == null
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
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Debes ser mayor de 18 años',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
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
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSectionDivider(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: theme.colorScheme.primary,
            size: 20,
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

    setState(() => _guardando = true);

    final persona = PersonaPerfilModel(
      id: controller.perfil.value!.persona.id,
      nombres: _nombresController.text,
      primerApellido: _primerApellidoController.text,
      segundoApellido: _segundoApellidoController.text,
      ci: _ciController.text,
      fechaNacimiento: _fechaNacimientoController.text,
      numeroCelular: _numeroCelularController.text,
      genero: _generoSeleccionado,
      nacionalidad:
          controller.perfil.value!.persona.nacionalidad ?? 'Boliviana',
      departamento: _departamentoController.text,
      provincia: _provinciaController.text,
      municipio: _municipioController.text,
      direccion: _direccionController.text,
    );

    final success = await controller.actualizarDatosPersonales(persona);

    setState(() => _guardando = false);

    if (success && mounted) {
      context.pop();
    }
  }
}
