import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/services/websocket_service.dart';
import 'package:sumajflow_movil/presentation/getx/theme_controller.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.to;
    final themeController = ThemeController.to;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Información del usuario
          _buildUserInfo(context, authService),
          const SizedBox(height: 24),

          // Configuración de tema
          _buildThemeSection(context, themeController),
          const SizedBox(height: 16),

          // Sección de cuenta
          _buildAccountSection(context),
          const SizedBox(height: 16),

          // Sección de ayuda
          _buildHelpSection(context),
          const SizedBox(height: 24),

          // Botón de cerrar sesión
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, AuthService authService) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authService.correo ?? 'Transportista',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${authService.transportistaId ?? "N/A"}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navegar a información personal
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Cambiar Contraseña'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navegar a cambiar contraseña
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notificaciones'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navegar a configuración de notificaciones
          },
        ),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return _SectionCard(
      title: 'Ayuda y Soporte',
      children: [
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Centro de Ayuda'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navegar a centro de ayuda
          },
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Términos y Condiciones'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navegar a términos y condiciones
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Política de Privacidad'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navegar a política de privacidad
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Acerca de'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAboutDialog(context);
          },
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
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Desconectar WebSocket
      WebSocketService.to.disconnect();

      // Limpiar datos de autenticación
      await AuthService.to.clearAuthData();

      // Cerrar loading
      if (context.mounted) Navigator.pop(context);

      // Navegar a home
      if (context.mounted) context.go(RouteNames.home);
    } catch (e) {
      // Cerrar loading si hay error
      if (context.mounted) Navigator.pop(context);

      // Mostrar error
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
      applicationName: 'Sumajflow Móvil',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.local_shipping, size: 48),
      children: [
        const Text('Aplicación móvil para transportistas'),
        const SizedBox(height: 8),
        const Text('Desarrollado por Sumajflow Team'),
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
