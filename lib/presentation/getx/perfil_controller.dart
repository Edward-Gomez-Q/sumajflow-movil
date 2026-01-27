// lib/presentation/getx/perfil_controller.dart

import 'package:get/get.dart';
import 'package:flutter/rendering.dart';
import 'package:sumajflow_movil/core/services/notification_service.dart';
import 'package:sumajflow_movil/data/models/perfil_models.dart';
import 'package:sumajflow_movil/data/repositories/perfil_repository.dart';

class PerfilController extends GetxController {
  final PerfilRepository _perfilRepository = PerfilRepository();
  final NotificationService _notificationService = NotificationService.to;

  var isLoading = false.obs;
  var perfil = Rx<PerfilModel?>(null);

  // ✅ NUEVO: Observable específico para datos del transportista
  var transportistaDetalle = Rx<TransportistaPerfilModel?>(null);
  var isLoadingTransportista = false.obs;

  @override
  void onInit() {
    super.onInit();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    isLoading.value = true;
    try {
      debugPrint('📋 Cargando perfil');
      perfil.value = await _perfilRepository.getPerfil();
      debugPrint('✅ Perfil cargado');
    } catch (e) {
      debugPrint('❌ Error al cargar perfil: $e');
      _notificationService.showError(
        'Error',
        'No se pudo cargar el perfil: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ NUEVO: Cargar datos específicos del transportista
  Future<void> cargarDatosTransportista() async {
    isLoadingTransportista.value = true;
    try {
      debugPrint('🚚 Cargando datos del transportista');
      transportistaDetalle.value = await _perfilRepository
          .getDatosTransportista();
      debugPrint('✅ Datos del transportista cargados');
      debugPrint('   Placa: ${transportistaDetalle.value?.placaVehiculo}');
      debugPrint('   Marca: ${transportistaDetalle.value?.marcaVehiculo}');
      debugPrint('   Modelo: ${transportistaDetalle.value?.modeloVehiculo}');
      debugPrint('   Color: ${transportistaDetalle.value?.colorVehiculo}');
      debugPrint('   Peso Tara: ${transportistaDetalle.value?.pesoTara}');
      debugPrint('   Capacidad: ${transportistaDetalle.value?.capacidadCarga}');
    } catch (e) {
      debugPrint('❌ Error al cargar datos del transportista: $e');
      _notificationService.showError(
        'Error',
        'No se pudieron cargar los datos del vehículo: ${e.toString()}',
      );
    } finally {
      isLoadingTransportista.value = false;
    }
  }

  Future<bool> actualizarDatosPersonales(PersonaPerfilModel persona) async {
    try {
      debugPrint('📝 Actualizando datos personales');
      await _perfilRepository.updateDatosPersonales(persona);
      await cargarPerfil();
      _notificationService.showSuccess(
        'Éxito',
        'Datos actualizados correctamente',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error al actualizar datos: $e');
      _notificationService.showError(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Actualizar datos del transportista
  Future<bool> actualizarDatosTransportista(
    TransportistaPerfilModel transportista,
  ) async {
    try {
      debugPrint('🚚 Actualizando datos del transportista');
      await _perfilRepository.updateDatosTransportista(transportista);

      // ✅ Recargar AMBOS perfiles después de actualizar
      await cargarPerfil();
      await cargarDatosTransportista();

      _notificationService.showSuccess(
        'Éxito',
        'Datos del vehículo actualizados correctamente',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error al actualizar datos del transportista: $e');
      _notificationService.showError(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> actualizarCorreo(
    String nuevoCorreo,
    String contrasenaActual,
  ) async {
    try {
      debugPrint('📧 Actualizando correo');
      await _perfilRepository.updateCorreo(nuevoCorreo, contrasenaActual);
      await cargarPerfil();
      _notificationService.showSuccess(
        'Éxito',
        'Correo actualizado correctamente',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error al actualizar correo: $e');
      _notificationService.showError(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> actualizarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    try {
      debugPrint('🔐 Actualizando contraseña');
      await _perfilRepository.updateContrasena(
        contrasenaActual: contrasenaActual,
        nuevaContrasena: nuevaContrasena,
        confirmarContrasena: confirmarContrasena,
      );
      _notificationService.showSuccess(
        'Éxito',
        'Contraseña actualizada correctamente',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error al actualizar contraseña: $e');
      _notificationService.showError(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}
