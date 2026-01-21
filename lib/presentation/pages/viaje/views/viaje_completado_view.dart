// lib/presentation/pages/viaje/views/viaje_completado_view.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/config/routes/route_names.dart';
import 'package:sumajflow_movil/data/repositories/lotes_repository.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';

class ViajeCompletadoView extends StatefulWidget {
  final ViajeController controller;

  const ViajeCompletadoView({super.key, required this.controller});

  @override
  State<ViajeCompletadoView> createState() => _ViajeCompletadoViewState();
}

class _ViajeCompletadoViewState extends State<ViajeCompletadoView>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _bounceController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
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
                  child: FaIcon(
                    FontAwesomeIcons.trophy,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    '¡Viaje Completado!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Has completado exitosamente el transporte de mineral.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Obx(() {
              final lote = widget.controller.loteDetalle.value;
              if (lote == null) return const SizedBox.shrink();

              return FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: FontAwesomeIcons.hashtag,
                        label: 'Código Lote',
                        value: lote.codigoLote,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: FontAwesomeIcons.mountain,
                        label: 'Origen',
                        value: lote.minaNombre,
                        theme: theme,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: FontAwesomeIcons.flagCheckered,
                        label: 'Destino',
                        value: lote.destinoTipo,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            ViajeActionButton(
              texto: 'Volver al Inicio',
              icono: FontAwesomeIcons.house,
              habilitado: true,
              colorPrimario: const Color(0xFF10B981),
              onPressed: () {
                Get.delete<ViajeController>(
                  tag: 'viaje_${widget.controller.asignacionId}',
                );
                //Recargar el dashboard para actualizar el estado del viaje
                LotesRepository controller = Get.find<LotesRepository>();
                controller.getMisLotes();
                context.go(RouteNames.dashboard);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        FaIcon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
