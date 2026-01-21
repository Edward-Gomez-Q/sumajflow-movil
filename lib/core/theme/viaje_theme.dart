// lib/presentation/pages/viaje/theme/viaje_theme.dart

import 'package:flutter/material.dart';

class ViajeTheme {
  // Colores por estado
  static const Color iniciar = Color(0xFF3B82F6);
  static const Color enCamino = Color(0xFF8B5CF6);
  static const Color cargando = Color(0xFFF97316);
  static const Color pesaje = Color(0xFF06B6D4);
  static const Color almacen = Color(0xFF10B981);
  static const Color descargando = Color(0xFFEC4899);
  static const Color completado = Color(0xFF10B981);

  // Gradientes
  static LinearGradient gradientPrimary(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color, color.withValues(alpha: 0.7)],
  );

  static LinearGradient gradientCard(Color color) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
  );

  // Sombras
  static List<BoxShadow> shadowPrimary(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowBottom = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];

  // Animaciones
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Curve animationCurve = Curves.easeOutCubic;
}
