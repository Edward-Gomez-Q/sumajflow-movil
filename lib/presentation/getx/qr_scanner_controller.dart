// lib/presentation/getx/qr_scanner_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/data/repositories/onboarding_repository.dart';

class QrScannerController extends GetxController {
  final mobileScannerController = MobileScannerController();
  final onboardingRepository = OnboardingRepository();

  var isProcessing = false.obs;

  @override
  void onClose() {
    mobileScannerController.dispose();
    super.onClose();
  }

  /// Procesar QR escaneado
  void procesarQR(String qrData, BuildContext context) async {
    //Mostrar el qrData en consola
    debugPrint('QR Data: $qrData');
    if (isProcessing.value) return;

    try {
      isProcessing.value = true;

      // Parsear JSON del QR
      final data = jsonDecode(qrData);

      if (data['tipo'] != 'invitacion_transportista') {
        _mostrarError(context, 'Código QR inválido');
        return;
      }

      final token = data['token'] as String;
      await procesarToken(token, context);
    } catch (e) {
      _mostrarError(context, 'Error al procesar QR: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Procesar token (desde QR o manual)
  Future<void> procesarToken(String token, BuildContext context) async {
    if (token.isEmpty) {
      _mostrarError(context, 'Token vacío');
      return;
    }

    isProcessing.value = true;

    try {
      // Llamar al endpoint de iniciar onboarding
      final resultado = await onboardingRepository.iniciarOnboarding(token);

      if (resultado['codigoEnviado'] == true) {
        // Navegar a verificación de código
        if (context.mounted) {
          context.go('${RouteNames.verificacionCodigo}/$token');
        }
      } else {
        _mostrarError(
          context,
          resultado['mensaje'] ?? 'Error al iniciar onboarding',
        );
      }
    } catch (e) {
      _mostrarError(context, 'Error: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }
}
