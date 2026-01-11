// lib/presentation/pages/viaje/resumen_final_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_timeline_widget.dart';

/// Página de resumen final cuando el viaje está completado
class ResumenFinalPage extends StatelessWidget {
  final ViajeController controller;

  const ResumenFinalPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Celebración
                  _buildCelebrationHeader(theme),

                  const SizedBox(height: 32),

                  // Stats del viaje
                  //_buildStatsSection(theme),
                  const SizedBox(height: 24),

                  // Información del viaje
                  Obx(() {
                    final lote = controller.loteDetalle.value;
                    if (lote == null) return const SizedBox.shrink();

                    return ViajeInfoCard(
                      titulo: 'Resumen del Viaje',
                      iconoTitulo: Icons.summarize_rounded,
                      colorAccento: const Color(0xFF10B981),
                      items: [
                        ViajeInfoItem(
                          label: 'Código de Lote',
                          valor: lote.codigoLote,
                          icono: Icons.tag_rounded,
                        ),
                        ViajeInfoItem(
                          label: 'Origen',
                          valor: lote.minaNombre,
                          icono: Icons.terrain_rounded,
                        ),
                        ViajeInfoItem(
                          label: 'Destino',
                          valor: lote.destinoTipo,
                          icono: Icons.flag_rounded,
                        ),
                        ViajeInfoItem(
                          label: 'Tipo de Mineral',
                          valor: _formatTipoMineral(lote.tipoMineral),
                          icono: Icons.diamond_rounded,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 24),

                  // Resumen de pesajes
                  ///_buildPesajesResumen(theme),
                  const SizedBox(height: 24),

                  // Timeline de eventos
                  /*Obx(() {
                    final observ = controller.observaciones.value;
                    if (observ == null) return const SizedBox.shrink();

                    return ViajeTimelineWidget(eventos: observ.eventos);
                  }),*/
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Botón de finalizar
          _buildBottomButton(theme),
        ],
      ),
    );
  }

  Widget _buildCelebrationHeader(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          // Icono de celebración
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 56)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            '¡Viaje Completado!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtítulo
          Text(
            'Has completado exitosamente el transporte de mineral',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /*Widget _buildStatsSection(ThemeData theme) {
    return Obx(() {
      final observ = controller.observaciones.value;
      final totalEventos = observ?.eventos.length ?? 0;
      final totalEvidencias = observ?.todasLasEvidencias.length ?? 0;
      final totalPesajes = observ?.pesajes.length ?? 0;

      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              theme,
              icono: Icons.timeline_rounded,
              valor: totalEventos.toString(),
              label: 'Eventos',
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              theme,
              icono: Icons.photo_library_rounded,
              valor: totalEvidencias.toString(),
              label: 'Fotos',
              color: const Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              theme,
              icono: Icons.scale_rounded,
              valor: totalPesajes.toString(),
              label: 'Pesajes',
              color: const Color(0xFF06B6D4),
            ),
          ),
        ],
      );
    });
  }*/

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icono,
    required String valor,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icono, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            valor,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /*Widget _buildPesajesResumen(ThemeData theme) {
    return Obx(() {
      final observ = controller.observaciones.value;
      if (observ == null || observ.pesajes.isEmpty) {
        return const SizedBox.shrink();
      }

      final pesajes = observ.pesajes;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF06B6D4).withValues(alpha: 0.1),
              const Color(0xFF06B6D4).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.scale_rounded,
                    color: Color(0xFF06B6D4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Detalle de Pesajes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabla de pesajes
            ...pesajes.map((p) {
              if (p.datosPesaje == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.tipo.titulo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPesoItem(
                          theme,
                          label: 'Bruto',
                          valor: p.datosPesaje!.pesoBruto,
                        ),
                        _buildPesoItem(
                          theme,
                          label: 'Tara',
                          valor: p.datosPesaje!.pesoTara,
                        ),
                        _buildPesoItem(
                          theme,
                          label: 'Neto',
                          valor: p.datosPesaje!.pesoNeto,
                          destacado: true,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Total si hay más de un pesaje
            if (pesajes.length > 1 &&
                pesajes.every((p) => p.datosPesaje != null)) ...[
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diferencia entre pesajes:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _calcularDiferencia(pesajes),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
*/
  Widget _buildPesoItem(
    ThemeData theme, {
    required String label,
    required double valor,
    bool destacado = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${valor.toStringAsFixed(0)} kg',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: destacado ? const Color(0xFF06B6D4) : null,
            ),
          ),
        ],
      ),
    );
  }

  String _calcularDiferencia(List<dynamic> pesajes) {
    if (pesajes.length < 2) return '0 kg';

    final pesajeCoop = pesajes.firstWhere(
      (p) => p.tipo.valor.contains('coop'),
      orElse: () => null,
    );
    final pesajeDestino = pesajes.firstWhere(
      (p) => p.tipo.valor.contains('destino'),
      orElse: () => null,
    );

    if (pesajeCoop?.datosPesaje == null || pesajeDestino?.datosPesaje == null) {
      return '0 kg';
    }

    final diferencia =
        (pesajeCoop.datosPesaje!.pesoNeto - pesajeDestino.datosPesaje!.pesoNeto)
            .abs();

    return '${diferencia.toStringAsFixed(0)} kg';
  }

  Widget _buildBottomButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ViajeActionButton(
          texto: 'Volver al Inicio',
          icono: Icons.home_rounded,
          habilitado: true,
          cargando: false,
          onPressed: () => Get.back(),
          colorPrimario: const Color(0xFF10B981),
        ),
      ),
    );
  }

  String _formatTipoMineral(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'bruto':
        return 'Mineral Bruto';
      case 'concentrado':
        return 'Concentrado';
      default:
        return tipo;
    }
  }
}
