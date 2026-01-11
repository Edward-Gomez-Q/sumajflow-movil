// lib/presentation/pages/qr_scanner/qr_scanner.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sumajflow_movil/presentation/getx/qr_scanner_controller.dart';

/// Página para escanear código QR de invitación
class QrScannerPage extends StatelessWidget {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QrScannerController());
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Código QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Escáner
          MobileScanner(
            controller: controller.mobileScannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  controller.procesarQR(barcode.rawValue!, context);
                  break;
                }
              }
            },
          ),

          // Overlay con marco
          _buildScannerOverlay(theme),

          // Instrucciones
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Escanea el código QR',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coloca el código QR dentro del marco para escanearlo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Botón manual
                  TextButton.icon(
                    onPressed: () => _mostrarInputManual(context, controller),
                    icon: const Icon(Icons.keyboard, color: Colors.white),
                    label: Text(
                      '¿No puedes escanear? Ingresa código manualmente',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          Obx(
            () => controller.isProcessing.value
                ? Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Validando código QR...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5)),
      child: Center(
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 3),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Esquinas animadas
              ..._buildCornerDecorations(theme),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerDecorations(ThemeData theme) {
    const size = 24.0;
    final color = theme.colorScheme.primary;

    return [
      // Esquina superior izquierda
      Positioned(
        top: -3,
        left: -3,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)),
          ),
        ),
      ),
      // Esquina superior derecha
      Positioned(
        top: -3,
        right: -3,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
            ),
          ),
        ),
      ),
      // Esquina inferior izquierda
      Positioned(
        bottom: -3,
        left: -3,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
            ),
          ),
        ),
      ),
      // Esquina inferior derecha
      Positioned(
        bottom: -3,
        right: -3,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
      ),
    ];
  }

  void _mostrarInputManual(
    BuildContext context,
    QrScannerController controller,
  ) {
    final tokenController = TextEditingController();
    var theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ingresar Código Manualmente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Token de Invitación',
                hintText: 'Ej: abc123def456...',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                controller.procesarToken(tokenController.text, context);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
