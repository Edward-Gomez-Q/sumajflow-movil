import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/data/models/lote_models.dart';
import 'package:sumajflow_movil/presentation/pages/dashboard/dashboard.dart';
import 'package:sumajflow_movil/presentation/pages/login/login.dart';
import 'package:sumajflow_movil/presentation/pages/lotes/lote_detalle_page.dart';
import 'package:sumajflow_movil/presentation/pages/splash/splash.dart';
import 'package:sumajflow_movil/presentation/pages/home/home.dart';
import 'package:sumajflow_movil/presentation/pages/qr_scanner/qr_scanner.dart';
import 'package:sumajflow_movil/presentation/pages/trazabilidad/trazabilidad_page.dart';
import 'package:sumajflow_movil/presentation/pages/verificacion_codigo/verificacion_codigo.dart';
import 'package:sumajflow_movil/presentation/pages/onboarding/onboarding.dart';
import 'package:sumajflow_movil/presentation/pages/success/success.dart';
import 'package:sumajflow_movil/presentation/pages/lotes/lotes_page.dart';
import 'package:sumajflow_movil/presentation/pages/notificaciones/notificaciones_page.dart';
import 'package:sumajflow_movil/presentation/pages/perfil/perfil_page.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/presentation/widgets/navigation/bottom_nav_bar.dart';

// Navegación de shell para páginas con bottom nav
class _ShellRouteNavigator extends StatelessWidget {
  final Widget child;

  const _ShellRouteNavigator({required this.child});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithBottomNav(
      navItems: const [
        BottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Inicio',
          route: RouteNames.dashboard,
        ),
        BottomNavItem(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          label: 'Lotes',
          route: RouteNames.lotes,
        ),
        BottomNavItem(
          icon: Icons.notifications_outlined,
          activeIcon: Icons.notifications,
          label: 'Alertas',
          route: RouteNames.notificaciones,
        ),
        BottomNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Perfil',
          route: RouteNames.profile,
        ),
      ],
      child: child,
    );
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final authService = AuthService.to;
      final isAuthenticated = authService.isAuthenticated;
      final currentLocation = state.uri.path;

      // Si está en splash, dejarlo pasar
      if (currentLocation == RouteNames.splash) {
        return null;
      }

      // Rutas públicas que no requieren autenticación
      final publicRoutes = [
        RouteNames.home,
        RouteNames.login,
        RouteNames.qrScanner,
      ];

      final isPublicRoute = publicRoutes.any(
        (route) =>
            currentLocation == route || currentLocation.startsWith(route),
      );

      // Rutas de onboarding que tampoco requieren autenticación
      final isOnboardingRoute =
          currentLocation.startsWith(RouteNames.verificacionCodigo) ||
          currentLocation.startsWith(RouteNames.onboarding);

      // Si está autenticado y trata de ir a una ruta pública, redirigir a dashboard
      if (isAuthenticated && (isPublicRoute || isOnboardingRoute)) {
        return RouteNames.dashboard;
      }

      // Si no está autenticado y trata de ir a una ruta privada, redirigir a home
      if (!isAuthenticated && !isPublicRoute && !isOnboardingRoute) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      // Rutas sin bottom navigation
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const Splash(),
      ),
      GoRoute(path: RouteNames.home, builder: (context, state) => const Home()),
      GoRoute(
        path: RouteNames.qrScanner,
        builder: (context, state) => const QrScannerPage(),
      ),
      GoRoute(
        path: '${RouteNames.verificacionCodigo}/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return VerificacionCodigo(token: token);
        },
      ),
      GoRoute(
        path: '${RouteNames.onboarding}/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return Onboarding(token: token);
        },
      ),
      GoRoute(
        path: RouteNames.success,
        builder: (context, state) => const Success(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const Login(),
      ),

      // Shell route con bottom navigation
      ShellRoute(
        builder: (context, state, child) => _ShellRouteNavigator(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const Dashboard(),
              state: state,
            ),
          ),
          GoRoute(
            path: RouteNames.lotes,
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const LotesPage(),
              state: state,
            ),
          ),
          GoRoute(
            path: RouteNames.notificaciones,
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const NotificacionesPage(),
              state: state,
            ),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const PerfilPage(),
              state: state,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '${RouteNames.loteDetalle}/:asignacionId',
        builder: (context, state) {
          final asignacionIdStr = state.pathParameters['asignacionId'] ?? '0';
          final asignacionId = int.tryParse(asignacionIdStr) ?? 0;
          return LoteDetallePage(asignacionId: asignacionId);
        },
      ),
      GoRoute(
        path: '${RouteNames.trazabilidad}/:asignacionId',
        builder: (context, state) {
          final asignacionIdStr = state.pathParameters['asignacionId'] ?? '0';
          final asignacionId = int.tryParse(asignacionIdStr) ?? 0;

          final controllerTag = 'trazabilidad_$asignacionId';

          return TrazabilidadPage(
            asignacionId: asignacionId,
            controllerTag: controllerTag,
            loteDetalle: null,
          );
        },
      ),
    ],
  );

  static Page _buildPageWithTransition({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
