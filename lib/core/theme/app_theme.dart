import 'package:flutter/material.dart';
import 'package:sumajflow_movil/core/theme/icon_styles.dart';
import 'package:sumajflow_movil/core/theme/text_styles.dart';
import 'colors.dart';

/// Tema principal de la aplicación
class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,

    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.lightError,
      onError: Colors.white,
    ),

    useMaterial3: true,

    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLargeLight,
      displayMedium: AppTextStyles.displayMediumLight,
      displaySmall: AppTextStyles.displaySmallLight,
      headlineLarge: AppTextStyles.headlineLargeLight,
      headlineMedium: AppTextStyles.headlineMediumLight,
      headlineSmall: AppTextStyles.headlineSmallLight,
      titleLarge: AppTextStyles.titleLargeLight,
      titleMedium: AppTextStyles.titleMediumLight,
      titleSmall: AppTextStyles.titleSmallLight,
      bodyLarge: AppTextStyles.bodyLargeLight,
      bodyMedium: AppTextStyles.bodyMediumLight,
      bodySmall: AppTextStyles.bodySmallLight,
      labelLarge: AppTextStyles.labelLargeLight,
      labelMedium: AppTextStyles.labelMediumLight,
      labelSmall: AppTextStyles.labelSmallLight,
    ),

    iconTheme: const IconThemeData(
      color: AppIconStyles.lightPrimary,
      size: AppIconStyles.small,
    ),

    cardColor: AppColors.lightCardBackground,

    // Configuraciones adicionales para animaciones y transiciones
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    // AppBar theme mejorado
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Card theme mejorado - CORRECCIÓN AQUÍ
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.lightCardBackground,
    ),

    // ElevatedButton theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary,
      surface: AppColors.darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.darkError,
      onError: Colors.white,
    ),

    useMaterial3: true,

    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLargeDark,
      displayMedium: AppTextStyles.displayMediumDark,
      displaySmall: AppTextStyles.displaySmallDark,
      headlineLarge: AppTextStyles.headlineLargeDark,
      headlineMedium: AppTextStyles.headlineMediumDark,
      headlineSmall: AppTextStyles.headlineSmallDark,
      titleLarge: AppTextStyles.titleLargeDark,
      titleMedium: AppTextStyles.titleMediumDark,
      titleSmall: AppTextStyles.titleSmallDark,
      bodyLarge: AppTextStyles.bodyLargeDark,
      bodyMedium: AppTextStyles.bodyMediumDark,
      bodySmall: AppTextStyles.bodySmallDark,
      labelLarge: AppTextStyles.labelLargeDark,
      labelMedium: AppTextStyles.labelMediumDark,
      labelSmall: AppTextStyles.labelSmallDark,
    ),

    iconTheme: const IconThemeData(
      color: AppIconStyles.darkPrimary,
      size: AppIconStyles.small,
    ),

    cardColor: AppColors.darkCardBackground,

    // Configuraciones adicionales para animaciones y transiciones
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),

    // AppBar theme mejorado
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
    ),

    // Card theme mejorado - CORRECCIÓN AQUÍ
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.darkCardBackground,
    ),

    // ElevatedButton theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),
  );
}
