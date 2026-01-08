// lib/presentation/widgets/gps_simulator_fab.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/data/models/tracking_models.dart';
import 'package:sumajflow_movil/presentation/getx/tracking_controller.dart';

/// Botón flotante para simular ubicación GPS durante desarrollo/testing
class GpsSimulatorFab extends StatelessWidget {
  final TrackingController controller;
  final List<PuntoControlModel> puntosControl;

  const GpsSimulatorFab({
    super.key,
    required this.controller,
    required this.puntosControl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Si el modo simulación está activo, mostrar el FAB expandido
      if (controller.modoSimulacion.value) {
        return _buildExpandedFab(context);
      }

      // FAB para activar modo simulación
      return FloatingActionButton(
        onPressed: () => _mostrarMenuSimulacion(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.gps_fixed, color: Colors.white),
        tooltip: 'Simulador GPS',
      );
    });
  }

  Widget _buildExpandedFab(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón para teletransportarse a un punto de control
        if (puntosControl.isNotEmpty)
          FloatingActionButton.small(
            heroTag: 'teleport',
            onPressed: () => _mostrarPuntosParaTeletransporte(context),
            backgroundColor: Colors.purple,
            child: const Icon(Icons.my_location, color: Colors.white),
            tooltip: 'Ir a punto de control',
          ),
        const SizedBox(height: 8),

        // Botón para ingresar coordenadas manualmente
        FloatingActionButton.small(
          heroTag: 'manual',
          onPressed: () => _mostrarInputCoordenadas(context),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.edit_location, color: Colors.white),
          tooltip: 'Ingresar coordenadas',
        ),
        const SizedBox(height: 8),

        // Botón principal (desactivar simulación)
        FloatingActionButton(
          heroTag: 'main',
          onPressed: controller.toggleModoSimulacion,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.close, color: Colors.white),
          tooltip: 'Desactivar simulación',
        ),
      ],
    );
  }

  void _mostrarMenuSimulacion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎮 Simulador GPS',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Activa el modo simulación para probar el sistema sin moverte físicamente.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: const Text('Activar simulación'),
              subtitle: const Text('Podrás simular ubicaciones manualmente'),
              onTap: () {
                Navigator.pop(context);
                controller.toggleModoSimulacion();
              },
            ),

            if (puntosControl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.purple),
                title: const Text('Ir a punto de control'),
                subtitle: const Text('Teletransportarte a un punto específico'),
                onTap: () {
                  Navigator.pop(context);
                  controller.toggleModoSimulacion();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _mostrarPuntosParaTeletransporte(context);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarPuntosParaTeletransporte(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.purple),
                  const SizedBox(width: 12),
                  Text(
                    'Teletransportarse a...',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: puntosControl.length,
                  itemBuilder: (context, index) {
                    final punto = puntosControl[index];
                    return _PuntoControlTile(
                      punto: punto,
                      onTap: () {
                        Navigator.pop(context);
                        controller.simularUbicacion(punto.lat, punto.lng);
                        Get.snackbar(
                          '🎮 Teletransporte',
                          'Te has movido a: ${punto.nombre}',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarInputCoordenadas(BuildContext context) {
    final latController = TextEditingController();
    final lngController = TextEditingController();

    // Prellenar con ubicación actual si existe
    final ubicacionActual = controller.ubicacionActual.value;
    if (ubicacionActual != null) {
      latController.text = ubicacionActual.lat.toString();
      lngController.text = ubicacionActual.lng.toString();
    } else {
      // Coordenadas de Potosí por defecto
      latController.text = '-19.5836';
      lngController.text = '-65.7531';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_location, color: Colors.blue),
            SizedBox(width: 8),
            Text('Ingresar coordenadas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitud',
                hintText: 'Ej: -19.5836',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitud',
                hintText: 'Ej: -65.7531',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Botones rápidos para coordenadas comunes
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickLocationChip(
                  label: 'Potosí Centro',
                  onTap: () {
                    latController.text = '-19.5836';
                    lngController.text = '-65.7531';
                  },
                ),
                _QuickLocationChip(
                  label: 'Cerro Rico',
                  onTap: () {
                    latController.text = '-19.6167';
                    lngController.text = '-65.7500';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);

              if (lat == null || lng == null) {
                Get.snackbar(
                  'Error',
                  'Coordenadas inválidas',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
                Get.snackbar(
                  'Error',
                  'Coordenadas fuera de rango',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Navigator.pop(context);
              controller.simularUbicacion(lat, lng);

              Get.snackbar(
                '🎮 Ubicación simulada',
                'Lat: $lat, Lng: $lng',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}

class _PuntoControlTile extends StatelessWidget {
  final PuntoControlModel punto;
  final VoidCallback onTap;

  const _PuntoControlTile({required this.punto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color color;
    IconData icon;

    switch (punto.tipo) {
      case 'mina':
        color = Colors.brown;
        icon = Icons.terrain;
        break;
      case 'balanza_cooperativa':
        color = Colors.purple;
        icon = Icons.scale;
        break;
      case 'balanza_ingenio':
        color = Colors.blue;
        icon = Icons.scale;
        break;
      case 'balanza_comercializadora':
        color = Colors.teal;
        icon = Icons.scale;
        break;
      case 'almacen_ingenio':
      case 'almacen_comercializadora':
        color = Colors.green;
        icon = Icons.warehouse;
        break;
      default:
        color = Colors.grey;
        icon = Icons.location_on;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          punto.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${punto.tipo} • Radio: ${punto.radio}m'),
        trailing: punto.estaCompletado
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _QuickLocationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickLocationChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.location_on, size: 16),
      onPressed: onTap,
    );
  }
}
