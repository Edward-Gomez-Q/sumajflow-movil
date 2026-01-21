// lib/presentation/widgets/viaje/viaje_evidencia_uploader.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ViajeEvidenciaUploader extends StatefulWidget {
  final List<File> evidencias;
  final ValueChanged<File>? onAgregarEvidencia;
  final ValueChanged<int>? onEliminarEvidencia;
  final bool obligatorio;
  final int maxEvidencias;
  final bool habilitado;
  final bool mostrarSubiendo;

  const ViajeEvidenciaUploader({
    super.key,
    required this.evidencias,
    this.onAgregarEvidencia,
    this.onEliminarEvidencia,
    this.obligatorio = false,
    this.maxEvidencias = 5,
    this.habilitado = true,
    this.mostrarSubiendo = false,
  });

  @override
  State<ViajeEvidenciaUploader> createState() => _ViajeEvidenciaUploaderState();
}

class _ViajeEvidenciaUploaderState extends State<ViajeEvidenciaUploader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final puedeAgregar =
        widget.evidencias.length < widget.maxEvidencias && widget.habilitado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.camera,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Evidencias',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.obligatorio)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            Text(
              '${widget.evidencias.length}/${widget.maxEvidencias}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.evidencias.isEmpty && !puedeAgregar)
          _buildEmptyState(theme)
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: puedeAgregar
                  ? widget.evidencias.length + 1
                  : widget.evidencias.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (puedeAgregar && index == 0) {
                  return _buildBotonAgregar(context, theme);
                }
                final evidenciaIndex = puedeAgregar ? index - 1 : index;
                return _buildEvidenciaItem(
                  theme,
                  widget.evidencias[evidenciaIndex],
                  evidenciaIndex,
                );
              },
            ),
          ),
        if (widget.mostrarSubiendo) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Subiendo evidencias...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.obligatorio && widget.evidencias.isEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 12,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                'Se requiere al menos una foto',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBotonAgregar(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () => _mostrarOpcionesCamara(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.camera,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              'Agregar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenciaItem(ThemeData theme, File archivo, int index) {
    return Stack(
      children: [
        Hero(
          tag: 'evidencia_$index',
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                archivo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: FaIcon(
                      FontAwesomeIcons.triangleExclamation, // ✅ Corrección aquí
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.habilitado)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                widget.onEliminarEvidencia?.call(index);
                _animationController.forward(from: 0);
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const FaIcon(
                  FontAwesomeIcons.xmark,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.images,
              size: 28,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Sin evidencias',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarOpcionesCamara(BuildContext context) async {
    final theme = Theme.of(context);

    final opcion = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Agregar evidencia',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildOpcionCamara(
                      context,
                      icon: FontAwesomeIcons.camera,
                      label: 'Cámara',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOpcionCamara(
                      context,
                      icon: FontAwesomeIcons.images,
                      label: 'Galería',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (opcion != null && mounted) {
      final picker = ImagePicker();
      final XFile? imagen = await picker.pickImage(
        source: opcion,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (imagen != null && mounted) {
        widget.onAgregarEvidencia?.call(File(imagen.path));
        // FIX: Forzar rebuild para mostrar imagen inmediatamente
        setState(() {});
      }
    }
  }

  Widget _buildOpcionCamara(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              FaIcon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
