// lib/presentation/pages/onboarding/onboarding.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/presentation/getx/onboarding_controller.dart';
import 'package:sumajflow_movil/presentation/pages/onboarding/widgets/step_indicator.dart';
import 'package:sumajflow_movil/presentation/widgets/custom_button.dart';

/// Página principal del onboarding
class Onboarding extends StatefulWidget {
  final String token;

  const Onboarding({super.key, required this.token});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  late OnboardingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OnboardingController());
    controller.token.value = widget.token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.cargarDatosInvitacion();
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Registro de Transportista'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoadingData.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Cargando tus datos...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(
                  () => StepIndicator(
                    currentStep: controller.currentStep.value,
                    totalSteps: 5,
                  ),
                ),
              ),

              Expanded(
                child: Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStepContent(
                      controller,
                      controller.currentStep.value,
                      theme,
                      context,
                    ),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Obx(
                  () => _buildNavigationButtons(controller, theme, context),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(
    OnboardingController controller,
    int step,
    ThemeData theme,
    BuildContext context,
  ) {
    Widget content;
    switch (step) {
      case 0:
        content = _buildStep1(controller, theme, context);
        break;
      case 1:
        content = _buildStep2(controller, theme);
        break;
      case 2:
        content = _buildStep3(controller, theme);
        break;
      case 3:
        content = _buildStep4(controller, theme, context);
        break;
      case 4:
        content = _buildStep5(controller, theme);
        break;
      default:
        content = const SizedBox();
    }

    return KeyedSubtree(key: ValueKey(step), child: content);
  }

  // ==================== PASO 1: Información Personal ====================
  Widget _buildStep1(
    OnboardingController controller,
    ThemeData theme,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            icon: Icons.person_outline,
            title: 'Información Personal',
            subtitle: 'Verifica y completa tus datos',
          ),
          const SizedBox(height: 32),

          Obx(
            () => _buildReadOnlyField(
              theme: theme,
              label: 'Nombre Completo',
              value: controller.nombreInvitacion.value,
              icon: Icons.person,
              isLoading: controller.nombreInvitacion.value.isEmpty,
            ),
          ),
          const SizedBox(height: 20),

          Obx(
            () => _buildReadOnlyField(
              theme: theme,
              label: 'Teléfono',
              value: controller.telefonoInvitacion.value,
              icon: Icons.phone,
              isLoading: controller.telefonoInvitacion.value.isEmpty,
            ),
          ),
          const SizedBox(height: 20),

          _buildEditableField(
            theme: theme,
            label: 'Carnet de Identidad',
            controller: controller.ciController,
            icon: Icons.badge,
            hint: '12345678',
            keyboardType: TextInputType.number,
            helperText: 'Ingresa tu número de CI sin espacios',
          ),

          const SizedBox(height: 20),

          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha de Nacimiento',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    print('🔍 Abriendo DatePicker...');

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(
                        const Duration(days: 365 * 25),
                      ),
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now().subtract(
                        const Duration(days: 365 * 18),
                      ),
                      helpText: 'Selecciona tu fecha de nacimiento',
                      cancelText: 'Cancelar',
                      confirmText: 'Confirmar',
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Theme.of(context).colorScheme.primary,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                            dialogBackgroundColor: Colors.white,
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null && mounted) {
                      print('  Fecha seleccionada: $picked');
                      controller.fechaNacimientoSeleccionada.value = picked;

                      final formattedDate =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

                      controller.fechaNacimientoController.text = formattedDate;
                      controller.validatePaso1();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                            controller.fechaNacimientoSeleccionada.value == null
                                ? 'Selecciona tu fecha de nacimiento'
                                : _formatearFechaDisplay(
                                    controller
                                        .fechaNacimientoSeleccionada
                                        .value!,
                                  ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  controller
                                          .fechaNacimientoSeleccionada
                                          .value ==
                                      null
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                              color:
                                  controller
                                          .fechaNacimientoSeleccionada
                                          .value ==
                                      null
                                  ? theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.5)
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
                Text(
                  'Debes ser mayor de 18 años',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildInfoBox(
            theme: theme,
            icon: Icons.info_outline,
            text:
                'Tu nombre y teléfono fueron verificados previamente y no pueden ser modificados.',
          ),
        ],
      ),
    );
  }

  // ==================== PASO 2: Credenciales ====================
  Widget _buildStep2(OnboardingController controller, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            icon: Icons.vpn_key_outlined,
            title: 'Credenciales de Acceso',
            subtitle: 'Crea tu cuenta para acceder a la aplicación',
          ),
          const SizedBox(height: 32),

          _buildEditableField(
            theme: theme,
            label: 'Correo Electrónico',
            controller: controller.correoController,
            icon: Icons.email_outlined,
            hint: 'ejemplo@correo.com',
            keyboardType: TextInputType.emailAddress,
            helperText: 'Usarás este correo para iniciar sesión',
          ),
          const SizedBox(height: 20),

          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contraseña',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.contrasenaController,
                  obscureText: controller.obscurePassword.value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Mínimo 8 caracteres',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.5,
                      ),
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                    helperText: 'Mínimo 8 caracteres',
                    helperStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
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
            ),
          ),
          const SizedBox(height: 20),

          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmar Contraseña',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.confirmarContrasenaController,
                  obscureText: controller.obscureConfirmPassword.value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Repite tu contraseña',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.5,
                      ),
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureConfirmPassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                    helperText:
                        controller.contrasenaController.text.isNotEmpty &&
                            controller
                                .confirmarContrasenaController
                                .text
                                .isNotEmpty
                        ? (controller.contrasenaController.text ==
                                  controller.confirmarContrasenaController.text
                              ? '✓ Las contraseñas coinciden'
                              : '✗ Las contraseñas no coinciden')
                        : 'Repite tu contraseña',
                    helperStyle: theme.textTheme.bodySmall?.copyWith(
                      color:
                          controller.contrasenaController.text.isNotEmpty &&
                              controller
                                  .confirmarContrasenaController
                                  .text
                                  .isNotEmpty
                          ? (controller.contrasenaController.text ==
                                    controller
                                        .confirmarContrasenaController
                                        .text
                                ? Colors.green
                                : Colors.red)
                          : theme.textTheme.bodySmall?.color,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
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
            ),
          ),
          const SizedBox(height: 24),

          _buildInfoBox(
            theme: theme,
            icon: Icons.security,
            text:
                'Tu contraseña debe tener al menos 8 caracteres. Guárdala en un lugar seguro.',
          ),
        ],
      ),
    );
  }

  // ==================== PASO 3: Información del Vehículo (ACTUALIZADO) ====================
  Widget _buildStep3(OnboardingController controller, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            icon: Icons.local_shipping,
            title: 'Información del Vehículo',
            subtitle: 'Ingresa los datos de tu vehículo',
          ),
          const SizedBox(height: 32),

          _buildEditableField(
            theme: theme,
            label: 'Placa del Vehículo',
            controller: controller.placaController,
            icon: Icons.confirmation_number_outlined,
            hint: 'ABC-1234',
            textCapitalization: TextCapitalization.characters,
            helperText: 'Formato: ABC-1234 o 1234ABC',
          ),
          const SizedBox(height: 20),

          _buildEditableField(
            theme: theme,
            label: 'Marca',
            controller: controller.marcaController,
            icon: Icons.directions_car_outlined,
            hint: 'Toyota, Volvo, Mercedes',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          _buildEditableField(
            theme: theme,
            label: 'Modelo',
            controller: controller.modeloController,
            icon: Icons.car_rental_outlined,
            hint: 'Hilux, FH16, Actros',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          _buildEditableField(
            theme: theme,
            label: 'Color del Vehículo',
            controller: controller.colorController,
            icon: Icons.palette_outlined,
            hint: 'Blanco, Rojo, Azul',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          _buildEditableField(
            theme: theme,
            label: 'Peso Tara',
            controller: controller.pesoTaraController,
            icon: Icons.scale,
            hint: '5.5',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            suffixText: 'toneladas',
            helperText: 'Peso del vehículo sin carga',
          ),
          const SizedBox(height: 20),

          _buildEditableField(
            theme: theme,
            label: 'Capacidad de Carga',
            controller: controller.capacidadCargaController,
            icon: Icons.inventory_2_outlined,
            hint: '20.0',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            suffixText: 'toneladas',
            helperText: 'Capacidad máxima de carga del vehículo',
          ),
        ],
      ),
    );
  }

  // ==================== PASO 4: Licencia (ACTUALIZADO) ====================
  Widget _buildStep4(
    OnboardingController controller,
    ThemeData theme,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            icon: Icons.description_outlined,
            title: 'Licencia de Conducir',
            subtitle: 'Datos de tu licencia y documento',
          ),
          const SizedBox(height: 32),

          // Categoría de Licencia
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categoría de Licencia',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: controller.categoriaLicenciaSeleccionada.value.isEmpty
                      ? null
                      : controller.categoriaLicenciaSeleccionada.value,
                  decoration: InputDecoration(
                    hintText: 'Selecciona la categoría',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: ['A', 'B', 'C', 'D', 'E'].map((categoria) {
                    return DropdownMenuItem(
                      value: categoria,
                      child: Text('Categoría $categoria'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.categoriaLicenciaSeleccionada.value = value;
                      controller.validatePaso4();
                    }
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Según tu tipo de vehículo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Fecha de Vencimiento
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha de Vencimiento de Licencia',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 10),
                      ),
                      helpText: 'Selecciona fecha de vencimiento',
                      cancelText: 'Cancelar',
                      confirmText: 'Confirmar',
                    );

                    if (picked != null && context.mounted) {
                      controller.fechaVencimientoLicencia.value = picked;
                      final formattedDate =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      controller.fechaVencimientoController.text =
                          formattedDate;
                      controller.validatePaso4();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                          Icons.event_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.fechaVencimientoLicencia.value == null
                                ? 'Selecciona fecha de vencimiento'
                                : _formatearFechaDisplay(
                                    controller.fechaVencimientoLicencia.value!,
                                  ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  controller.fechaVencimientoLicencia.value ==
                                      null
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                              color:
                                  controller.fechaVencimientoLicencia.value ==
                                      null
                                  ? theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.5)
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
            ),
          ),
          const SizedBox(height: 20),

          // Foto de Licencia
          Obx(
            () => _buildDocumentCard(
              theme: theme,
              title: 'Licencia de Conducir',
              subtitle: 'Foto clara de ambos lados',
              icon: Icons.credit_card,
              file: controller.licenciaFoto.value,
              onTap: () => controller.pickImage('licencia', context),
              isUploading: controller.licenciaUploading.value,
            ),
          ),
          const SizedBox(height: 24),

          _buildInfoBox(
            theme: theme,
            icon: Icons.camera_alt,
            text:
                'Asegúrate de que la foto sea clara y legible. Evita reflejos y sombras.',
          ),

          Obx(() {
            if (controller.licenciaUploading.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildInfoBox(
                  theme: theme,
                  icon: Icons.cloud_upload,
                  text: 'Subiendo documento... Por favor espera.',
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  // ==================== PASO 5: Resumen (ACTUALIZADO) ====================
  Widget _buildStep5(OnboardingController controller, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            icon: Icons.check_circle_outline,
            title: 'Confirma tus Datos',
            subtitle: 'Revisa que toda la información sea correcta',
          ),
          const SizedBox(height: 32),

          _buildSummarySection(
            theme: theme,
            title: 'Información Personal',
            icon: Icons.person,
            items: [
              ('Nombre', controller.nombreInvitacion.value),
              ('Teléfono', controller.telefonoInvitacion.value),
              ('CI', controller.ciController.text),
              (
                'Fecha de Nacimiento',
                controller.fechaNacimientoSeleccionada.value != null
                    ? _formatearFechaDisplay(
                        controller.fechaNacimientoSeleccionada.value!,
                      )
                    : 'No seleccionada',
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSummarySection(
            theme: theme,
            title: 'Información del Vehículo',
            icon: Icons.local_shipping,
            items: [
              ('Placa', controller.placaController.text),
              ('Marca', controller.marcaController.text),
              ('Modelo', controller.modeloController.text),
              ('Color', controller.colorController.text),
              ('Peso Tara', '${controller.pesoTaraController.text} ton'),
              (
                'Capacidad Carga',
                '${controller.capacidadCargaController.text} ton',
              ),
            ],
          ),
          const SizedBox(height: 16),

          Obx(
            () => _buildSummarySection(
              theme: theme,
              title: 'Licencia de Conducir',
              icon: Icons.credit_card,
              items: [
                (
                  'Categoría',
                  'Categoría ${controller.categoriaLicenciaSeleccionada.value}',
                ),
                (
                  'Vencimiento',
                  controller.fechaVencimientoLicencia.value != null
                      ? _formatearFechaDisplay(
                          controller.fechaVencimientoLicencia.value!,
                        )
                      : 'No seleccionada',
                ),
                (
                  'Documento',
                  controller.licenciaFoto.value != null
                      ? '✓ Cargado'
                      : '✗ Faltante',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WIDGETS REUTILIZABLES ====================

  Widget _buildStepHeader({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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

  Widget _buildReadOnlyField({
    required ThemeData theme,
    required String label,
    required String value,
    required IconData icon,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
                child: isLoading
                    ? Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Cargando...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      )
                    : Text(
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

  Widget _buildEditableField({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? suffixText,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: theme.colorScheme.primary),
            suffixText: suffixText,
            helperText: helperText,
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.error),
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

  Widget _buildDocumentCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required dynamic file,
    required VoidCallback onTap,
    bool isUploading = false,
  }) {
    final hasFile = file != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFile
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: hasFile ? 2 : 1,
            ),
            boxShadow: hasFile
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasFile
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: hasFile
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUploading ? 'Subiendo documento...' : subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isUploading
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isUploading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : hasFile
                      ? Icon(
                          Icons.check_circle,
                          key: const ValueKey('check'),
                          color: theme.colorScheme.primary,
                          size: 28,
                        )
                      : Icon(
                          Icons.camera_alt,
                          key: const ValueKey('camera'),
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<(String, String)> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      item.$2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required ThemeData theme,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
    OnboardingController controller,
    ThemeData theme,
    BuildContext context,
  ) {
    final isLastStep = controller.currentStep.value == 4;
    final canGoNext = controller.canGoNext();

    return Row(
      children: [
        if (controller.currentStep.value > 0)
          Expanded(
            child: CustomButton(
              text: 'Atrás',
              isOutlined: true,
              onPressed: controller.previousStep,
            ),
          ),
        if (controller.currentStep.value > 0) const SizedBox(width: 16),

        Expanded(
          flex: controller.currentStep.value == 0 ? 1 : 1,
          child: CustomButton(
            text: isLastStep ? 'Finalizar' : 'Siguiente',
            icon: isLastStep ? Icons.check_circle : Icons.arrow_forward,
            isLoading: controller.isLoading.value,
            onPressed: canGoNext
                ? () async {
                    if (isLastStep) {
                      final success = await controller.submitOnboarding();
                      if (!context.mounted) return;
                      if (success) {
                        print('Onboarding completado con éxito.');
                        context.push(RouteNames.success);
                      }
                    } else {
                      controller.nextStep();
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  String _formatearFechaDisplay(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
