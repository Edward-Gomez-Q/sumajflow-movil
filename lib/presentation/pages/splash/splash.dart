// lib/presentation/pages/splash/splash.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/presentation/pages/splash/widgets/animated_logo.dart';

/// Página de splash inicial
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authService = AuthService.to;

    if (authService.isAuthenticated) {
      print('✅ Usuario autenticado, navegando a dashboard');
      context.go(RouteNames.dashboard);
    } else {
      print('⚠️ Usuario no autenticado, navegando a home');
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(child: AnimatedLogo()),
    );
  }
}
