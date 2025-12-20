import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controlador del tema de la aplicación
class ThemeController extends GetxController {
  Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}