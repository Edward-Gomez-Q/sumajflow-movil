// lib/presentation/widgets/viaje/viaje_pesaje_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ViajePesajeForm extends StatefulWidget {
  final double? pesoBrutoInicial;
  final double? pesoTaraInicial;
  final ValueChanged<double>? onPesoBrutoChanged;
  final ValueChanged<double>? onPesoTaraChanged;
  final bool habilitado;
  final bool mostrarPesoNeto;

  const ViajePesajeForm({
    super.key,
    this.pesoBrutoInicial,
    this.pesoTaraInicial,
    this.onPesoBrutoChanged,
    this.onPesoTaraChanged,
    this.habilitado = true,
    this.mostrarPesoNeto = true,
  });

  @override
  State<ViajePesajeForm> createState() => _ViajePesajeFormState();
}

class _ViajePesajeFormState extends State<ViajePesajeForm> {
  late TextEditingController _pesoBrutoController;
  late TextEditingController _pesoTaraController;

  double _pesoBruto = 0.0;
  double _pesoTara = 0.0;

  @override
  void initState() {
    super.initState();
    _pesoBruto = widget.pesoBrutoInicial ?? 0.0;
    _pesoTara = widget.pesoTaraInicial ?? 0.0;

    _pesoBrutoController = TextEditingController(
      text: _pesoBruto > 0 ? _pesoBruto.toString() : '',
    );
    _pesoTaraController = TextEditingController(
      text: _pesoTara > 0 ? _pesoTara.toString() : '',
    );
  }

  @override
  void dispose() {
    _pesoBrutoController.dispose();
    _pesoTaraController.dispose();
    super.dispose();
  }

  double get _pesoNeto {
    if (_pesoBruto <= 0 || _pesoTara <= 0) return 0.0;
    if (_pesoTara >= _pesoBruto) return 0.0;
    return _pesoBruto - _pesoTara;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  FontAwesomeIcons.scaleBalanced,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos de Pesaje',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Ingresa los pesos en kilogramos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCampoPeso(
                  theme,
                  controller: _pesoBrutoController,
                  label: 'Peso Bruto',
                  hint: '0.00',
                  icono: FontAwesomeIcons.weightHanging,
                  onChanged: (valor) {
                    setState(() {
                      _pesoBruto = double.tryParse(valor) ?? 0.0;
                    });
                    widget.onPesoBrutoChanged?.call(_pesoBruto);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCampoPeso(
                  theme,
                  controller: _pesoTaraController,
                  label: 'Peso Tara',
                  hint: '0.00',
                  icono: FontAwesomeIcons.truck,
                  onChanged: (valor) {
                    setState(() {
                      _pesoTara = double.tryParse(valor) ?? 0.0;
                    });
                    widget.onPesoTaraChanged?.call(_pesoTara);
                  },
                ),
              ),
            ],
          ),
          if (widget.mostrarPesoNeto) ...[
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _pesoNeto > 0
                      ? [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ]
                      : [
                          theme.colorScheme.surfaceContainerHighest,
                          theme.colorScheme.surfaceContainerHighest,
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pesoNeto > 0
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peso Neto',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calculado automáticamente',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '${_pesoNeto.toStringAsFixed(2)} kg',
                      key: ValueKey(_pesoNeto),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _pesoNeto > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_pesoTara > 0 && _pesoBruto > 0 && _pesoTara >= _pesoBruto) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El peso tara debe ser menor al peso bruto',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampoPeso(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icono,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: widget.habilitado,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: onChanged,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixText: 'kg',
              suffixStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ViajePesajeDisplay extends StatelessWidget {
  final double pesoBruto;
  final double pesoTara;
  final double pesoNeto;
  final String? titulo;
  final DateTime? timestamp;

  const ViajePesajeDisplay({
    super.key,
    required this.pesoBruto,
    required this.pesoTara,
    required this.pesoNeto,
    this.titulo,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null || timestamp != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (titulo != null)
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.scaleBalanced,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        titulo!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (timestamp != null)
                  Text(
                    _formatTimestamp(timestamp!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          if (titulo != null || timestamp != null) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPesoItem(theme, label: 'Bruto', valor: pesoBruto),
              ),
              Container(
                height: 40,
                width: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildPesoItem(theme, label: 'Tara', valor: pesoTara),
              ),
              Container(
                height: 40,
                width: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildPesoItem(
                  theme,
                  label: 'Neto',
                  valor: pesoNeto,
                  destacado: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPesoItem(
    ThemeData theme, {
    required String label,
    required double valor,
    bool destacado = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${valor.toStringAsFixed(2)} kg',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: destacado ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hora = dt.hour.toString().padLeft(2, '0');
    final minuto = dt.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }
}
