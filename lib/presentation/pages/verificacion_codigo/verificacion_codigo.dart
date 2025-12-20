// lib/presentation/pages/verificacion_codigo/verificacion_codigo.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sumajflow_movil/presentation/getx/verificacion_codigo_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/custom_button.dart';

/// Página de verificación de código WhatsApp
class VerificacionCodigo extends StatelessWidget {
  final String token;

  const VerificacionCodigo({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerificacionCodigoController());
    controller.token.value = token;

    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Verificación'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono
              Icon(
                Icons.message_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Título
              Text(
                'Verifica tu número',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Obx(
                () => Text(
                  'Ingresa el código de 6 dígitos que enviamos a:\n${controller.numeroCelular.value}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // PIN Input
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: controller.codigoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: theme.colorScheme.surface,
                  inactiveFillColor: theme.colorScheme.surface,
                  selectedFillColor: theme.colorScheme.surface,
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.onSurface.withOpacity(0.2),
                  selectedColor: theme.colorScheme.primary,
                ),
                enableActiveFill: true,
                onCompleted: (code) {
                  controller.verificarCodigo(context);
                },
                onChanged: (value) {
                  controller.codigo.value = value;
                },
              ),
              const SizedBox(height: 24),

              // Intentos restantes
              Obx(
                () => controller.intentosRestantes.value < 3
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Te quedan ${controller.intentosRestantes.value} intentos',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
              const SizedBox(height: 16),

              // Mensaje de error
              Obx(
                () => controller.errorMessage.value.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          controller.errorMessage.value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Botón verificar
              Obx(
                () => CustomButton(
                  text: 'Verificar Código',
                  icon: Icons.check_circle,
                  isLoading: controller.isLoading.value,
                  onPressed: controller.codigo.value.length == 6
                      ? () => controller.verificarCodigo(context)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Reenviar código
              Obx(() => _buildReenviarCodigo(controller, theme, context)),
              const SizedBox(height: 32),

              // Info adicional
              _buildInfoBox(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReenviarCodigo(
    VerificacionCodigoController controller,
    ThemeData theme,
    BuildContext context,
  ) {
    if (controller.puedeReenviar.value) {
      return TextButton.icon(
        onPressed: () => controller.reenviarCodigo(context),
        icon: const Icon(Icons.refresh),
        label: const Text('Reenviar código'),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 16, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text(
            'Podrás reenviar en ${controller.tiempoRestante.value}s',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }
  }

  Widget _buildInfoBox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿No recibiste el código?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Verifica que tu número sea correcto\n'
            '• Revisa tu aplicación de WhatsApp\n'
            '• Espera unos segundos y reintenta\n'
            '• El código expira en 10 minutos',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
