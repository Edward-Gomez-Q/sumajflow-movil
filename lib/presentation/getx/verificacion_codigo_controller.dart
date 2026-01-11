// lib/presentation/getx/verificacion_codigo_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/data/repositories/onboarding_repository.dart';

class VerificacionCodigoController extends GetxController {
  final onboardingRepository = OnboardingRepository();
  final codigoController = TextEditingController();

  var token = ''.obs;
  var codigo = ''.obs;
  var numeroCelular = ''.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var intentosRestantes = 3.obs;
  var puedeReenviar = false.obs;
  var tiempoRestante = 60.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _iniciarTemporizador();
  }

  @override
  void onClose() {
    _timer?.cancel();
    codigoController.dispose();
    super.onClose();
  }

  void _iniciarTemporizador() {
    tiempoRestante.value = 60;
    puedeReenviar.value = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (tiempoRestante.value > 0) {
        tiempoRestante.value--;
      } else {
        puedeReenviar.value = true;
        timer.cancel();
      }
    });
  }

  /// Verificar código de WhatsApp
  /// IMPORTANTE: Ahora recibe el BuildContext como parámetro
  Future<void> verificarCodigo(BuildContext context) async {
    if (codigo.value.length != 6) {
      errorMessage.value = 'El código debe tener 6 dígitos';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final resultado = await onboardingRepository.verificarCodigo(
        token.value,
        codigo.value,
      );

      debugPrint('$resultado'); // Para debug

      if (resultado['verificado'] == true) {
        if (context.mounted) {
          context.go('${RouteNames.onboarding}/${token.value}');
        }
      } else {
        // Código incorrecto
        intentosRestantes.value--;
        errorMessage.value = resultado['mensaje'] ?? 'Código incorrecto';
        codigoController.clear();
        codigo.value = '';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Reenviar código
  Future<void> reenviarCodigo(BuildContext context) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final resultado = await onboardingRepository.reenviarCodigo(token.value);

      if (resultado['codigoEnviado'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Código reenviado. Revisa tu WhatsApp')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        _iniciarTemporizador();
      } else {
        errorMessage.value = 'Error al reenviar código';
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
