// lib/presentation/pages/success/success.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/presentation/widgets/custom_button.dart';

class Success extends StatelessWidget {
  const Success({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono de éxito
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, size: 100, color: Colors.green),
              ),
              const SizedBox(height: 32),

              // Título
              Text(
                '¡Registro Exitoso!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Descripción
              Text(
                'Tu cuenta ha sido creada exitosamente.\n'
                'Ya puedes comenzar a usar la aplicación.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Botón para continuar
              CustomButton(
                text: 'Ir al Dashboard',
                icon: Icons.arrow_forward,
                onPressed: () {
                  // Redirigir al dashboard (por ahora al home)
                  context.go('/dashboard');
                },
              ),
              const SizedBox(height: 16),

              // Botón alternativo
              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: Text(
                  'Ir a Iniciar Sesión',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
