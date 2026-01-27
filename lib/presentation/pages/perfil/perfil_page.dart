// lib/presentation/pages/perfil/perfil_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/services/websocket_service.dart';
import 'package:sumajflow_movil/presentation/getx/perfil_controller.dart';
import 'package:sumajflow_movil/presentation/getx/theme_controller.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.to;
    final controller = Get.put(PerfilController());

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final perfil = controller.perfil.value;
        if (perfil == null) {
          return _buildErrorState(context);
        }

        return RefreshIndicator(
          onRefresh: controller.cargarPerfil,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildUserInfo(context, perfil),
              const SizedBox(height: 24),
              _buildThemeSection(context, themeController),
              const SizedBox(height: 16),
              _buildAccountSection(context),
              const SizedBox(height: 16),
              _buildAboutSection(context),
              const SizedBox(height: 24),
              _buildLogoutButton(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error al cargar el perfil'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.find<PerfilController>().cargarPerfil(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, perfil) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                perfil.iniciales,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perfil.nombreCompleto,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    perfil.usuario.correo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${perfil.transportista?.id ?? "N/A"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    ThemeController themeController,
  ) {
    return _SectionCard(
      title: 'Apariencia',
      children: [
        Obx(
          () => SwitchListTile(
            value: themeController.isDarkMode,
            onChanged: (value) => themeController.toggleTheme(),
            title: const Text('Modo Oscuro'),
            subtitle: const Text('Activa el tema oscuro'),
            secondary: Icon(
              themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return _SectionCard(
      title: 'Cuenta',
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Información Personal'),
          subtitle: const Text('Edita tus datos personales'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push("/profile/datos-personales");
          },
        ),
        ListTile(
          leading: const Icon(Icons.local_shipping_outlined),
          title: const Text('Información de Transportista'),
          subtitle: const Text('Edita datos del vehículo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push('/profile/datos-transportista');
          },
        ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('Cambiar Correo'),
          subtitle: const Text('Actualiza tu correo electrónico'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push('/profile/cambiar-correo');
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Cambiar Contraseña'),
          subtitle: const Text('Actualiza tu contraseña'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push('/profile/cambiar-contrasena');
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _SectionCard(
      title: 'Información',
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Acerca de'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: () => _showLogoutConfirmation(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Cerrar Sesión'),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout(context);
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      WebSocketService.to.disconnect();
      await AuthService.to.clearAuthData();

      if (context.mounted) Navigator.pop(context);
      if (context.mounted) context.go(RouteNames.home);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SumajFlow Móvil',
      applicationVersion: '1.0.0 (Prototipo)',
      applicationIcon: const Icon(Icons.local_shipping, size: 48),
      children: [
        const Text('Aplicación móvil para transportistas'),
        const SizedBox(height: 16),
        const Text('Desarrollado por:'),
        const SizedBox(height: 8),
        const Text(
          'Edward Gomez',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Este es un sistema prototipo desarrollado como parte del proyecto de trazabilidad minera.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}
