// lib/config/routes/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/presentation/pages/splash/splash.dart';
import 'package:sumajflow_movil/presentation/pages/home/home.dart';
import 'package:sumajflow_movil/presentation/pages/qr_scanner/qr_scanner.dart';
import 'package:sumajflow_movil/presentation/pages/verificacion_codigo/verificacion_codigo.dart';
import 'package:sumajflow_movil/presentation/pages/onboarding/onboarding.dart';
import 'package:sumajflow_movil/presentation/pages/success/success.dart'; // ✅ NUEVO
import 'package:sumajflow_movil/presentation/pages/dashboard/dashboard.dart'; // ✅ NUEVO
import 'package:sumajflow_movil/config/routes/route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
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
    ],
  );
}
