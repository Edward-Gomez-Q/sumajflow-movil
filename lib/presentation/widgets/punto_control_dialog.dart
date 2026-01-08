// lib/presentation/widgets/punto_control_dialog.dart

import 'package:flutter/material.dart';

/// Diálogo para confirmar llegada o salida de un punto de control
class PuntoControlDialog extends StatefulWidget {
  final String tipoPunto;
  final String accion; // 'llegada' o 'salida'
  final VoidCallback onConfirmar;

  const PuntoControlDialog({
    super.key,
    required this.tipoPunto,
    required this.accion,
    required this.onConfirmar,
  });

  @override
  State<PuntoControlDialog> createState() => _PuntoControlDialogState();
}

class _PuntoControlDialogState extends State<PuntoControlDialog> {
  final _observacionesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  String get _titulo {
    if (widget.accion == 'llegada') {
      return 'Confirmar Llegada';
    }
    return 'Registrar Salida';
  }

  String get _descripcion {
    final nombrePunto = _getNombrePunto(widget.tipoPunto);

    if (widget.accion == 'llegada') {
      return 'Estás por confirmar tu llegada a $nombrePunto. Esta acción quedará registrada.';
    }
    return 'Estás por registrar tu salida de $nombrePunto. Asegúrate de haber completado todas las actividades necesarias.';
  }

  IconData get _icono {
    if (widget.accion == 'llegada') {
      return Icons.location_on;
    }
    return Icons.exit_to_app;
  }

  Color get _color {
    if (widget.accion == 'llegada') {
      return Colors.green;
    }
    return Colors.blue;
  }

  String _getNombrePunto(String tipo) {
    switch (tipo) {
      case 'mina':
        return 'la Mina';
      case 'balanza_cooperativa':
        return 'la Balanza de la Cooperativa';
      case 'balanza_ingenio':
        return 'la Balanza del Ingenio';
      case 'balanza_comercializadora':
        return 'la Balanza de la Comercializadora';
      case 'almacen_ingenio':
        return 'el Almacén del Ingenio';
      case 'almacen_comercializadora':
        return 'el Almacén de la Comercializadora';
      default:
        return 'el Punto de Control';
    }
  }

  Widget _getInstrucciones() {
    switch (widget.tipoPunto) {
      case 'mina':
        if (widget.accion == 'llegada') {
          return _buildInstruccionesList([
            'Ubícate en el área de carga',
            'Espera tu turno si hay cola',
            'Prepara tu vehículo para la carga',
          ]);
        }
        return _buildInstruccionesList([
          'Verifica que el mineral esté correctamente cargado',
          'Asegura la carga antes de partir',
          'Dirígete a la siguiente balanza',
        ]);

      case 'balanza_cooperativa':
      case 'balanza_ingenio':
      case 'balanza_comercializadora':
        if (widget.accion == 'llegada') {
          return _buildInstruccionesList([
            'Detén el vehículo en la balanza',
            'Espera a que se estabilice el peso',
            'El operador registrará el pesaje',
          ]);
        }
        return _buildInstruccionesList([
          'Verifica que el pesaje fue registrado',
          'Guarda el comprobante si te lo entregan',
          'Continúa hacia el siguiente punto',
        ]);

      case 'almacen_ingenio':
      case 'almacen_comercializadora':
        if (widget.accion == 'llegada') {
          return _buildInstruccionesList([
            'Ubícate en el área de descarga',
            'Espera instrucciones del operador',
            'Prepara el vehículo para descarga',
          ]);
        }
        return _buildInstruccionesList([
          'Verifica que la descarga fue completada',
          'Confirma la recepción con el operador',
          '¡Viaje completado!',
        ]);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInstruccionesList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Pasos a seguir:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icono, color: _color),
          ),
          const SizedBox(width: 12),
          Text(_titulo),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_descripcion),

            _getInstrucciones(),

            const SizedBox(height: 16),

            TextField(
              controller: _observacionesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Observaciones (opcional)',
                hintText: 'Ej: Sin novedades',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _confirmar,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  widget.accion == 'llegada' ? Icons.check : Icons.exit_to_app,
                ),
          label: Text(widget.accion == 'llegada' ? 'Confirmar' : 'Registrar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _color,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _confirmar() {
    setState(() => _isLoading = true);
    widget.onConfirmar();
  }
}

/// Diálogo para registrar pesaje en balanza
class PesajeDialog extends StatefulWidget {
  final String tipoBalanza;
  final Function(double pesoBruto, double pesoTara, String? observaciones)
  onConfirmar;

  const PesajeDialog({
    super.key,
    required this.tipoBalanza,
    required this.onConfirmar,
  });

  @override
  State<PesajeDialog> createState() => _PesajeDialogState();
}

class _PesajeDialogState extends State<PesajeDialog> {
  final _pesoBrutoController = TextEditingController();
  final _pesoTaraController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  double get _pesoNeto {
    final bruto = double.tryParse(_pesoBrutoController.text) ?? 0;
    final tara = double.tryParse(_pesoTaraController.text) ?? 0;
    return bruto - tara;
  }

  @override
  void dispose() {
    _pesoBrutoController.dispose();
    _pesoTaraController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.scale, color: Colors.purple),
          ),
          const SizedBox(width: 12),
          const Text('Registrar Pesaje'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa los datos del pesaje en la ${widget.tipoBalanza}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _pesoBrutoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso Bruto (kg)',
                  prefixIcon: Icon(Icons.scale),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el peso bruto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pesoTaraController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso Tara (kg)',
                  prefixIcon: Icon(Icons.local_shipping),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el peso tara';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Peso neto calculado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Peso Neto:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_pesoNeto.toStringAsFixed(2)} kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _observacionesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _confirmar,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Guardar Pesaje'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    final pesoBruto = double.parse(_pesoBrutoController.text);
    final pesoTara = double.parse(_pesoTaraController.text);

    if (pesoBruto <= pesoTara) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El peso bruto debe ser mayor que el peso tara'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    widget.onConfirmar(
      pesoBruto,
      pesoTara,
      _observacionesController.text.isNotEmpty
          ? _observacionesController.text
          : null,
    );
  }
}
