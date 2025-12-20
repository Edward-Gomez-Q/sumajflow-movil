// lib/config/routes/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/presentation/pages/login/login.dart';
import 'package:sumajflow_movil/presentation/pages/splash/splash.dart';
import 'package:sumajflow_movil/presentation/pages/home/home.dart';
import 'package:sumajflow_movil/presentation/pages/qr_scanner/qr_scanner.dart';
import 'package:sumajflow_movil/presentation/pages/verificacion_codigo/verificacion_codigo.dart';
import 'package:sumajflow_movil/presentation/pages/onboarding/onboarding.dart';
import 'package:sumajflow_movil/presentation/pages/success/success.dart';
import 'package:sumajflow_movil/presentation/pages/dashboard/dashboard.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final authService = AuthService.to;
      final isAuthenticated = authService.isAuthenticated;
      final currentLocation = state.uri.path;

      print('🔍 Redirect check:');
      print('   - Current location: $currentLocation');
      print('   - Is authenticated: $isAuthenticated');

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
        print('✅ Usuario autenticado, redirigiendo a dashboard');
        return RouteNames.dashboard;
      }

      // Si no está autenticado y trata de ir a una ruta privada, redirigir a home
      if (!isAuthenticated && !isPublicRoute && !isOnboardingRoute) {
        print('⚠️ Usuario no autenticado, redirigiendo a home');
        return RouteNames.home;
      }

      // En cualquier otro caso, permitir la navegación
      return null;
    },
    routes: [
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
        path: RouteNames.dashboard,
        builder: (context, state) => const Dashboard(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const Login(),
      ),
    ],
  );
}
