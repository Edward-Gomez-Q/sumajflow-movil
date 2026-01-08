import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/config/routes/app_router.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/services/location_service.dart';
import 'package:sumajflow_movil/core/services/offline_storage_service.dart';
import 'package:sumajflow_movil/core/theme/app_theme.dart';
import 'package:sumajflow_movil/presentation/getx/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suprimir warnings de flutter_map en producción
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      // Solo suprimir warnings específicos de flutter_map
      if (message?.contains('flutter_map') ?? false) {
        return;
      }
      // Permitir otros debugPrint importantes
      debugPrintThrottled(message, wrapWidth: wrapWidth);
    };
  }

  // Inicializar servicios
  try {
    await Get.putAsync(() => AuthService().init());
    await Get.putAsync(() => OfflineStorageService().init());
    await Get.putAsync(() => LocationService().init());
  } catch (e) {
    debugPrint('Error inicializando servicios: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializar ThemeController
    final themeController = Get.put(ThemeController());

    return Obx(
      () => MaterialApp.router(
        title: "Sumajflow Móvil",
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode.value,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,

        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            if (kReleaseMode) {
              return Container(
                alignment: Alignment.center,
                child: const Text('Error', style: TextStyle(color: Colors.red)),
              );
            }
            return ErrorWidget(details.exception);
          };

          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
