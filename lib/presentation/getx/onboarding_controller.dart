// lib/presentation/getx/onboarding_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/data/models/transportista_model.dart';
import 'package:sumajflow_movil/data/repositories/transportista_repository.dart';
import 'package:sumajflow_movil/data/repositories/onboarding_repository.dart';

/// Controlador del proceso de onboarding
class OnboardingController extends GetxController {
  final TransportistaRepository _repository = TransportistaRepository();
  final OnboardingRepository _onboardingRepository = OnboardingRepository();
  final ImagePicker _picker = ImagePicker();

  // Estado del stepper
  var currentStep = 0.obs;
  var isLoading = false.obs;
  var isLoadingData = false.obs;
  var isUploadingImage = false.obs;
  var token = ''.obs;

  // Datos pre-cargados de la invitación
  var nombreInvitacion = ''.obs;
  var telefonoInvitacion = ''.obs;

  // Paso 1: Información Personal
  final ciController = TextEditingController();
  final fechaNacimientoController = TextEditingController();
  var fechaNacimientoSeleccionada = Rx<DateTime?>(null);

  // Paso 2: Credenciales de Acceso
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final confirmarContrasenaController = TextEditingController();
  var obscurePassword = true.obs;
  var obscureConfirmPassword = true.obs;

  // Paso 3: Información del Vehículo
  final placaController = TextEditingController();
  final marcaController = TextEditingController();
  final modeloController = TextEditingController();
  final colorController = TextEditingController();
  final pesoTaraController = TextEditingController();
  final capacidadCargaController = TextEditingController();

  // Paso 4: Documentos y Licencia
  Rx<File?> licenciaFoto = Rx<File?>(null);
  var licenciaObjectName = ''.obs;
  var licenciaUploading = false.obs;

  var categoriaLicenciaSeleccionada = ''.obs;
  var fechaVencimientoLicencia = Rx<DateTime?>(null);
  final fechaVencimientoController = TextEditingController();

  // Validación por paso
  var paso1Valid = false.obs;
  var paso2Valid = false.obs;
  var paso3Valid = false.obs;
  var paso4Valid = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  @override
  void onClose() {
    ciController.dispose();
    correoController.dispose();
    contrasenaController.dispose();
    confirmarContrasenaController.dispose();
    placaController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    colorController.dispose();
    pesoTaraController.dispose();
    capacidadCargaController.dispose();
    fechaNacimientoController.dispose();
    fechaVencimientoController.dispose();
    super.onClose();
  }

  void _setupListeners() {
    ciController.addListener(validatePaso1);
    fechaNacimientoController.addListener(validatePaso1);
    correoController.addListener(_validatePaso2);
    contrasenaController.addListener(_validatePaso2);
    confirmarContrasenaController.addListener(_validatePaso2);
    placaController.addListener(_validatePaso3);
    marcaController.addListener(_validatePaso3);
    modeloController.addListener(_validatePaso3);
    colorController.addListener(_validatePaso3);
    pesoTaraController.addListener(_validatePaso3);
    capacidadCargaController.addListener(_validatePaso3);
  }

  void validatePaso1() {
    paso1Valid.value =
        ciController.text.isNotEmpty && ciController.text.length >= 5;
    paso1Valid.value &= fechaNacimientoSeleccionada.value != null;
  }

  void _validatePaso2() {
    final correoValido = _isValidEmail(correoController.text);
    final contrasenaValida = contrasenaController.text.length >= 8;
    final contrasenasCoinciden =
        contrasenaController.text == confirmarContrasenaController.text &&
        confirmarContrasenaController.text.isNotEmpty;

    paso2Valid.value = correoValido && contrasenaValida && contrasenasCoinciden;
  }

  void _validatePaso3() {
    paso3Valid.value =
        placaController.text.isNotEmpty &&
        marcaController.text.isNotEmpty &&
        modeloController.text.isNotEmpty &&
        colorController.text.isNotEmpty &&
        pesoTaraController.text.isNotEmpty &&
        capacidadCargaController.text.isNotEmpty;
  }

  void validatePaso4() {
    paso4Valid.value =
        licenciaFoto.value != null &&
        licenciaObjectName.value.isNotEmpty &&
        categoriaLicenciaSeleccionada.value.isNotEmpty &&
        fechaVencimientoLicencia.value != null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  /// Muestra un snackbar de forma segura
  void _showSnackbar(String title, String message, Color backgroundColor) {
    // Usar Future.delayed para asegurar que el contexto esté disponible
    Future.delayed(Duration.zero, () {
      if (Get.context != null) {
        Get.snackbar(
          title,
          message,
          backgroundColor: backgroundColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        );
        print('📢 Snackbar mostrado: $title - $message');
      } else {
        print('⚠️ Get.context es null, no se puede mostrar snackbar');
      }
    });
  }

  /// Cargar datos de la invitación desde el backend
  Future<void> cargarDatosInvitacion() async {
    if (token.value.isEmpty) {
      _showSnackbar('Error', 'Token no válido', Colors.red);
      return;
    }

    isLoadingData.value = true;

    try {
      final datos = await _onboardingRepository.obtenerDatosInvitacion(
        token.value,
      );

      String nombre = '';
      if (datos['primerNombre'] != null) {
        nombre += datos['primerNombre'];
      }
      if (datos['segundoNombre'] != null &&
          datos['segundoNombre'].toString().isNotEmpty) {
        nombre += ' ${datos['segundoNombre']}';
      }
      if (datos['primerApellido'] != null) {
        nombre += ' ${datos['primerApellido']}';
      }
      if (datos['segundoApellido'] != null &&
          datos['segundoApellido'].toString().isNotEmpty) {
        nombre += ' ${datos['segundoApellido']}';
      }

      nombreInvitacion.value = nombre.trim();
      telefonoInvitacion.value = datos['numeroCelular'] ?? '';

      print('✅ Datos cargados exitosamente');
    } catch (e) {
      print('❌ Error al cargar datos de invitación: $e');
      _showSnackbar(
        'Error',
        'No se pudieron cargar los datos de la invitación',
        Colors.red,
      );
    } finally {
      isLoadingData.value = false;
    }
  }

  Future<void> seleccionarFechaNacimiento(BuildContext context) async {
    try {
      await Future.delayed(Duration.zero);

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
        firstDate: DateTime(1940),
        lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
        locale: const Locale('es', 'ES'),
        helpText: 'Selecciona tu fecha de nacimiento',
        cancelText: 'Cancelar',
        confirmText: 'Confirmar',
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        fechaNacimientoSeleccionada.value = picked;

        final formattedDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

        fechaNacimientoController.text = formattedDate;

        print('✅ Fecha seleccionada: $formattedDate');

        validatePaso1();
      }
    } catch (e) {
      print('❌ Error al seleccionar fecha: $e');
      _showSnackbar(
        'Error',
        'No se pudo abrir el selector de fecha',
        Colors.red,
      );
    }
  }

  /// ✅ Solicitar permisos antes de abrir el picker
  Future<bool> _solicitarPermisos(
    ImageSource source,
    BuildContext context,
  ) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();

        if (status.isDenied) {
          _showSnackbar(
            'Permiso denegado',
            'Necesitas conceder acceso a la cámara',
            Colors.orange,
          );
          return false;
        }

        if (status.isPermanentlyDenied) {
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('Permiso de cámara requerido'),
              content: const Text(
                'El acceso a la cámara ha sido denegado permanentemente. '
                '¿Deseas abrir la configuración para habilitarlo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Abrir configuración'),
                ),
              ],
            ),
          );

          if (openSettings == true) {
            await openAppSettings();
          }
          return false;
        }

        return status.isGranted;
      } else {
        PermissionStatus status;

        if (await Permission.photos.isRestricted ||
            await Permission.photos.isLimited ||
            await Permission.photos.isDenied) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }

        if (status.isDenied) {
          _showSnackbar(
            'Permiso denegado',
            'Necesitas conceder acceso a la galería',
            Colors.orange,
          );
          return false;
        }

        if (status.isPermanentlyDenied) {
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('Permiso de galería requerido'),
              content: const Text(
                'El acceso a la galería ha sido denegado permanentemente. '
                '¿Deseas abrir la configuración para habilitarlo?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Abrir configuración'),
                ),
              ],
            ),
          );

          if (openSettings == true) {
            await openAppSettings();
          }
          return false;
        }

        return status.isGranted || status.isLimited;
      }
    } catch (e) {
      print('❌ Error al solicitar permisos: $e');
      _showSnackbar('Error', 'Error al verificar permisos: $e', Colors.red);
      return false;
    }
  }

  /// ✅ Captura una foto y la sube a MinIO
  Future<void> pickImage(String tipo, BuildContext context) async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Seleccionar fuente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () =>
                    Navigator.of(dialogContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () =>
                    Navigator.of(dialogContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        print('⚠️ Usuario canceló la selección de fuente');
        return;
      }

      print(
        '🔐 Solicitando permisos para ${source == ImageSource.camera ? 'cámara' : 'galería'}...',
      );
      final permisosConcedidos = await _solicitarPermisos(source, context);

      if (!permisosConcedidos) {
        print('❌ Permisos no concedidos');
        return;
      }

      print('✅ Permisos concedidos, abriendo picker...');

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        print('⚠️ No se seleccionó ninguna imagen');
        _showSnackbar(
          'Cancelado',
          'No se seleccionó ninguna imagen',
          Colors.orange,
        );
        return;
      }

      print('📷 Imagen capturada: ${image.path}');

      final File imageFile = File(image.path);

      if (!await imageFile.exists()) {
        print('❌ El archivo no existe en la ruta: ${image.path}');
        _showSnackbar(
          'Error',
          'No se pudo acceder a la imagen seleccionada',
          Colors.red,
        );
        return;
      }

      print('✅ Archivo válido, tamaño: ${await imageFile.length()} bytes');

      // Solo licencia
      if (tipo == 'licencia') {
        licenciaFoto.value = imageFile;
        licenciaUploading.value = true;
      }

      validatePaso4();

      await _uploadImageToMinio(imageFile, tipo);
    } catch (e, stackTrace) {
      print('❌ Error al capturar imagen: $e');
      print('Stack trace: $stackTrace');

      _showSnackbar(
        'Error',
        'No se pudo capturar la imagen. Por favor intenta nuevamente.',
        Colors.red,
      );

      if (tipo == 'licencia') {
        licenciaFoto.value = null;
        licenciaUploading.value = false;
      }
      validatePaso4();
    }
  }

  /// Sube una imagen a MinIO
  Future<void> _uploadImageToMinio(File file, String tipo) async {
    try {
      print('📤 Subiendo imagen de $tipo...');

      const String folder = 'documentos-transportistas';
      final objectName = await _repository.uploadFile(file, folder);

      print('✅ Imagen subida exitosamente: $objectName');

      if (tipo == 'licencia') {
        licenciaObjectName.value = objectName;
        licenciaUploading.value = false;
      }

      validatePaso4();
      _showSnackbar('Éxito', 'Documento subido correctamente', Colors.green);
    } catch (e) {
      print('❌ Error al subir imagen: $e');

      if (tipo == 'licencia') {
        licenciaFoto.value = null;
        licenciaObjectName.value = '';
        licenciaUploading.value = false;
      }

      validatePaso4();
      _showSnackbar('Error', 'No se pudo subir el documento', Colors.red);
    }
  }

  /// Navega al siguiente paso
  void nextStep() {
    if (currentStep.value < 4) {
      currentStep.value++;
    }
  }

  /// Navega al paso anterior
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  /// Verifica si se puede avanzar
  bool canGoNext() {
    switch (currentStep.value) {
      case 0:
        return paso1Valid.value;
      case 1:
        return paso2Valid.value;
      case 2:
        return paso3Valid.value;
      case 3:
        return paso4Valid.value && !licenciaUploading.value;
      case 4:
        return paso1Valid.value &&
            paso2Valid.value &&
            paso3Valid.value &&
            paso4Valid.value &&
            !isAnyUploadInProgress;
      default:
        return false;
    }
  }

  bool get isAnyUploadInProgress => licenciaUploading.value;

  // Actualiza solo el método submitOnboarding en tu controlador

  Future<bool> submitOnboarding() async {
    if (!paso1Valid.value ||
        !paso2Valid.value ||
        !paso3Valid.value ||
        !paso4Valid.value) {
      _showSnackbar(
        'Error',
        'Por favor completa todos los campos',
        Colors.orange,
      );
      return false;
    }

    if (licenciaObjectName.value.isEmpty) {
      _showSnackbar(
        'Error',
        'Por favor espera a que se suba la licencia',
        Colors.orange,
      );
      return false;
    }

    if (isAnyUploadInProgress) {
      _showSnackbar('Espera', 'La licencia se está subiendo...', Colors.orange);
      return false;
    }

    isLoading.value = true;

    try {
      final fechaNacFormateada = fechaNacimientoSeleccionada.value != null
          ? '${fechaNacimientoSeleccionada.value!.year}-${fechaNacimientoSeleccionada.value!.month.toString().padLeft(2, '0')}-${fechaNacimientoSeleccionada.value!.day.toString().padLeft(2, '0')}'
          : '';

      final fechaVencFormateada = fechaVencimientoLicencia.value != null
          ? '${fechaVencimientoLicencia.value!.year}-${fechaVencimientoLicencia.value!.month.toString().padLeft(2, '0')}-${fechaVencimientoLicencia.value!.day.toString().padLeft(2, '0')}'
          : '';

      final transportistaData = TransportistaModel(
        ci: ciController.text,
        fechaNacimiento: fechaNacFormateada,
        correo: correoController.text,
        contrasena: contrasenaController.text,
        placaVehiculo: placaController.text,
        marcaVehiculo: marcaController.text,
        modeloVehiculo: modeloController.text,
        colorVehiculo: colorController.text,
        pesoTara: double.tryParse(pesoTaraController.text) ?? 0.0,
        capacidadCarga: double.tryParse(capacidadCargaController.text) ?? 0.0,
        licenciaConducirUrl: licenciaObjectName.value,
        categoriaLicencia: categoriaLicenciaSeleccionada.value,
        fechaVencimientoLicencia: fechaVencFormateada,
      );

      final response = await _repository.completarOnboarding(
        token: token.value,
        transportista: transportistaData,
      );

      print('✅ Onboarding completado, procesando respuesta...');
      print('📥 Respuesta completa: $response');

      isLoading.value = false;

      if (response != null && response['success'] == true) {
        // ✅ CORRECCIÓN: Acceder a los datos dentro de 'data'
        final data = response['data'] as Map<String, dynamic>?;

        if (data != null) {
          final authToken = data['token'] as String?;
          final usuarioId = data['usuarioId'] as int?;
          final transportistaId = data['transportistaId'] as int?;
          final correo = data['correo'] as String?;

          print('🔍 Token extraído: $authToken');
          print('🔍 Usuario ID: $usuarioId');
          print('🔍 Transportista ID: $transportistaId');
          print('🔍 Correo: $correo');

          if (authToken != null &&
              usuarioId != null &&
              transportistaId != null &&
              correo != null) {
            // Guardar los datos de autenticación
            await AuthService.to.saveAuthData(
              token: authToken,
              usuarioId: usuarioId,
              transportistaId: transportistaId,
              correo: correo,
            );

            print('✅ Datos guardados en AuthService');

            _showSnackbar(
              'Éxito',
              'Registro completado correctamente',
              Colors.green,
            );

            return true;
          } else {
            print('❌ Datos incompletos en data');
            _showSnackbar(
              'Error',
              'Datos incompletos en la respuesta del servidor',
              Colors.red,
            );
            return false;
          }
        } else {
          print('❌ No se encontró el objeto data en la respuesta');
          _showSnackbar('Error', 'Formato de respuesta incorrecto', Colors.red);
          return false;
        }
      } else {
        print('❌ Respuesta nula o success=false');
        _showSnackbar('Error', 'No se pudo completar el registro', Colors.red);
        return false;
      }
    } catch (e, stackTrace) {
      isLoading.value = false;
      print('❌ Error al procesar: $e');
      print('Stack trace: $stackTrace');
      _showSnackbar('Error', 'Error al procesar: ${e.toString()}', Colors.red);
      return false;
    }
  }
}
