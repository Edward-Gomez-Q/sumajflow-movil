// lib/presentation/pages/viaje/views/viaje_iniciar_view.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:sumajflow_movil/presentation/getx/viaje_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_action_button.dart';
import 'package:sumajflow_movil/presentation/widgets/viaje/viaje_info_card.dart';

class ViajeIniciarView extends StatefulWidget {
  final ViajeController controller;

  const ViajeIniciarView({super.key, required this.controller});

  @override
  State<ViajeIniciarView> createState() => _ViajeIniciarViewState();
}

class _ViajeIniciarViewState extends State<ViajeIniciarView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.truckFast,
                    size: 48,
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
                    '¡Todo listo para comenzar!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Presiona el botón para iniciar el viaje y comenzar el seguimiento GPS.',
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

              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: ViajeInfoCard(
                  titulo: 'Información del Viaje',
                  iconoTitulo: FontAwesomeIcons.circleInfo,
                  items: [
                    ViajeInfoItem(
                      label: 'Código',
                      valor: "00${lote.loteId.toString()}",
                      icono: FontAwesomeIcons.hashtag,
                    ),
                    ViajeInfoItem(
                      label: 'Origen',
                      valor: lote.minaNombre,
                      icono: FontAwesomeIcons.mountain,
                    ),
                    ViajeInfoItem(
                      label: 'Destino',
                      valor: lote.destinoTipo,
                      icono: FontAwesomeIcons.flagCheckered,
                    ),
                  ],
                ),
              );
            }),
            const Spacer(),
            Obx(() {
              return ViajeActionButton(
                texto: widget.controller.textoBotonPrincipal,
                icono: widget.controller.iconoBotonPrincipal,
                habilitado: !widget.controller.isLoading.value,
                cargando: widget.controller.isLoading.value,
                onPressed: widget.controller.ejecutarAccionPrincipal,
              );
            }),
          ],
        ),
      ),
    );
  }
}
