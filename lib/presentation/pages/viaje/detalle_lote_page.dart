// lib/presentation/pages/viaje/detalle_lote_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sumajflow_movil/presentation/getx/tracking_controller.dart';
import 'package:sumajflow_movil/presentation/widgets/mapa_ruta_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class DetalleLotePage extends StatefulWidget {
  final int asignacionId;

  const DetalleLotePage({super.key, required this.asignacionId});

  @override
  State<DetalleLotePage> createState() => _DetalleLotePageState();
}

class _DetalleLotePageState extends State<DetalleLotePage> {
  late TrackingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TrackingController());
    controller.cargarDetalleLote(widget.asignacionId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.loteDetalle.value?.codigoLote ?? 'Cargando...',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.loteDetalle.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final lote = controller.loteDetalle.value;
        if (lote == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value.isNotEmpty
                      ? controller.errorMessage.value
                      : 'No se pudo cargar el lote',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      controller.cargarDetalleLote(widget.asignacionId),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con información del socio
              _buildSocioHeader(lote, theme),

              // NUEVO: Mapa de la ruta
              _buildMapaSection(lote, theme),

              // Información de minerales y destino
              _buildInfoSection(lote, theme),

              // Información de ruta
              _buildRutaSection(lote, theme),

              // Pasos del viaje
              _buildPasosViaje(theme),

              // Botón de inicio
              _buildIniciarButton(theme),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  // NUEVO: Sección del mapa
  Widget _buildMapaSection(lote, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: MapaRutaWidget(lote: lote, mostrarAdvertencia: true),
    );
  }

  Widget _buildSocioHeader(lote, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lote.socioNombre ?? 'Socio Minero',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (lote.socioTelefono != null)
                  Text(
                    'Contacto: ${lote.socioTelefono}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
          if (lote.socioTelefono != null)
            IconButton(
              onPressed: () => _llamarSocio(lote.socioTelefono!),
              icon: Icon(Icons.phone, color: theme.colorScheme.primary),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(lote, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minerales
          Row(
            children: [
              Text(
                'MINERALES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const Spacer(),
              Text(
                'DESTINO',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Wrap(
                spacing: 6,
                children: lote.mineralTags
                    .map<Widget>((tag) => _MineralChip(tag: tag))
                    .toList(),
              ),
              const Spacer(),
              Text(
                lote.destinoNombre,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              lote.destinoTipo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const Divider(height: 32),

          // Ruta y distancia
          Text(
            'RUTA Y DISTANCIA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.straighten,
                  label: 'Distancia Total',
                  value: lote.distanciaDisplay,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.schedule,
                  label: 'Tiempo Est.',
                  value: lote.tiempoEstimadoDisplay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRutaSection(lote, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PUNTOS DE LA RUTA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),
          if (lote.tieneRutaCompleta) ...[
            ...lote.waypoints.map(
              (waypoint) => _buildWaypointItem(waypoint, theme),
            ),
          ] else
            Text(
              'Información de ruta no disponible',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          const Divider(height: 24),
          Text(
            'CAMIONES ASIGNADOS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${lote.totalCamiones} camiones',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Camión #${lote.numeroCamion}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaypointItem(waypoint, ThemeData theme) {
    final color = _parseColor(waypoint.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                '${waypoint.orden}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(waypoint.iconoEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  waypoint.tituloDescriptivo,
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  waypoint.nombre,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasosViaje(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximos Pasos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const _PasoItem(
            numero: 1,
            texto: 'Dirígete a la mina',
            icono: Icons.location_on,
          ),
          const _PasoItem(
            numero: 2,
            texto: 'Espera tu turno de carga',
            icono: Icons.hourglass_empty,
          ),
          const _PasoItem(
            numero: 3,
            texto: 'Carga el mineral',
            icono: Icons.download,
          ),
        ],
      ),
    );
  }

  Widget _buildIniciarButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading.value ? null : _iniciarViaje,
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow, size: 28),
            label: Text(
              controller.isLoading.value ? 'Iniciando...' : 'Comenzar Viaje',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _iniciarViaje() async {
    final success = await controller.iniciarViaje();
    if (success && mounted) {
      context.pushReplacement('/viaje/${widget.asignacionId}');
    }
  }

  void _llamarSocio(String telefono) async {
    final uri = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')} ${fecha.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _MineralChip extends StatelessWidget {
  final String tag;
  const _MineralChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (tag.toLowerCase()) {
      case 'ag':
        color = Colors.grey;
        break;
      case 'pb':
        color = Colors.blueGrey;
        break;
      case 'zn':
        color = Colors.teal;
        break;
      default:
        color = Colors.purple;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasoItem extends StatelessWidget {
  final int numero;
  final String texto;
  final IconData icono;

  const _PasoItem({
    required this.numero,
    required this.texto,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$numero',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icono, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text(texto, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
