import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
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
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedLogo(),
      ),
    );
  }
}