// lib/presentation/pages/home/home.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/presentation/widgets/custom_button.dart';

/// Página de inicio con opciones de acceso
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo y título
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      size: 120,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SumajFlow',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistema de Gestión de Transportistas',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Opciones de acceso
              Column(
                children: [
                  // Crear cuenta con QR
                  CustomButton(
                    text: 'Crear Cuenta con QR',
                    icon: Icons.qr_code_scanner,
                    onPressed: () => context.push(RouteNames.qrScanner),
                  ),
                  const SizedBox(height: 16),

                  // Iniciar sesión
                  CustomButton(
                    text: 'Iniciar Sesión',
                    icon: Icons.login,
                    isOutlined: true,
                    onPressed: () => context.push(RouteNames.login),
                  ),
                  const SizedBox(height: 32),

                  // Información
                  _buildInfoCard(theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            '¿Primera vez aquí?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Solicita tu código QR a tu cooperativa para crear tu cuenta',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
