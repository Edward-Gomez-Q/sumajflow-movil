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

import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message?.contains('flutter_map') ?? false) return;
      debugPrintThrottled(message, wrapWidth: wrapWidth);
    };
  }

  try {
    debugPrint('🚀 Inicializando servicios...');

    await Get.putAsync(() => AuthService().init());
    debugPrint('  AuthService inicializado');

    await Get.putAsync(() => OfflineStorageService().init());
    debugPrint('  OfflineStorageService inicializado');

    await Get.putAsync(() => LocationService().init());
    debugPrint('  LocationService inicializado');

    await Get.putAsync(() => WebSocketService().init());
    debugPrint('  WebSocketService inicializado');

    await _initFMTC();
    debugPrint('✅ FMTC listo');

    Get.put(ThemeController());
    debugPrint('  ThemeController inicializado');

    debugPrint('✅ Todos los servicios inicializados correctamente');
  } catch (e, st) {
    debugPrint('❌ Error inicializando servicios: $e');
    debugPrint('$st');
  }

  runApp(const MainApp());
}

Future<void> _initFMTC() async {
  try {
    await FMTCObjectBoxBackend().initialise();
    debugPrint('  FMTC ObjectBox backend inicializado');

    const storeName = 'sumajflowMapStore';
    final storeDirectory = FMTCStore(storeName);

    final exists = await storeDirectory.manage.ready;

    if (!exists) {
      await storeDirectory.manage.create();
      debugPrint('  FMTC store creado: $storeName');
    } else {
      debugPrint('  FMTC store ya existe: $storeName');
    }
  } catch (e, st) {
    debugPrint('❌ FMTC falló, se continúa SIN cache de tiles: $e');
    debugPrint('$st');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController());
    }
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
