import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/config/routes/app_router.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/services/location_service.dart';
import 'package:sumajflow_movil/core/services/offline_storage_service.dart';
import 'package:sumajflow_movil/core/services/websocket_service.dart';
import 'package:sumajflow_movil/core/theme/app_theme.dart';
import 'package:sumajflow_movil/presentation/getx/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suprimir warnings de flutter_map en producción
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message?.contains('flutter_map') ?? false) {
        return;
      }
      debugPrintThrottled(message, wrapWidth: wrapWidth);
    };
  }

  // Inicializar servicios esenciales primero
  try {
    debugPrint('🚀 Inicializando servicios...');

    // Servicio de autenticación (debe ser el primero)
    await Get.putAsync(() => AuthService().init());
    debugPrint('  AuthService inicializado');

    // Servicios de almacenamiento y ubicación
    await Get.putAsync(() => OfflineStorageService().init());
    debugPrint('  OfflineStorageService inicializado');

    await Get.putAsync(() => LocationService().init());
    debugPrint('  LocationService inicializado');

    // WebSocket service (se conecta solo si hay autenticación)
    await Get.putAsync(() => WebSocketService().init());
    debugPrint('  WebSocketService inicializado');

    // Inicializar ThemeController (OPCIONAL: moverlo aquí)
    Get.put(ThemeController());
    debugPrint('  ThemeController inicializado');

    debugPrint('  Todos los servicios inicializados correctamente');
  } catch (e) {
    debugPrint('❌ Error inicializando servicios: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener ThemeController (ya fue inicializado en main)
    final themeController = ThemeController.to;

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
