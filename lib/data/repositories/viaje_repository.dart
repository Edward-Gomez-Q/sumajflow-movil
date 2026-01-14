// lib/data/repositories/viaje_repository.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/exceptions/network_exception.dart';
import 'package:sumajflow_movil/data/providers/api_provider.dart';
import 'package:flutter/rendering.dart';

/// Repositorio para gestionar eventos del viaje operativo
/// Usa los endpoints existentes del backend: /transportista/viaje/{id}/...
class ViajeRepository {
  late final Dio _dio;
  final ApiProvider _apiProvider = ApiProvider();

  ViajeRepository() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthService.to.authToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('🔵 Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ Response [${response.statusCode}]: Success');
          return handler.next(response);
        },
        onError: (error, handler) {
          // No loguear errores de conexión para no saturar
          if (error.type != DioExceptionType.connectionTimeout &&
              error.type != DioExceptionType.receiveTimeout &&
              error.type != DioExceptionType.connectionError &&
              error.type != DioExceptionType.sendTimeout) {
            debugPrint('❌ DioError: ${error.type}');
          }

          // IMPORTANTE: usar reject, no next
          return handler.reject(error);
        },
      ),
    );
  }

  // ==================== INICIO DE VIAJE ====================

  /// POST /transportista/viaje/{asignacionId}/iniciar
  /// Transición: Esperando iniciar → En camino a la mina
  Future<TransicionEstadoResponse> iniciarViaje({
    required int asignacionId,
    required double lat,
    required double lng,
    String? observaciones,
  }) async {
    try {
      debugPrint('🚀 Iniciando viaje para asignacionId: $asignacionId');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/iniciar',
        data: {
          'lat': lat,
          'lng': lng,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Viaje iniciado exitosamente');
        return TransicionEstadoResponse.fromJson(response.data);
      }

      throw Exception(response.data['message'] ?? 'Error al iniciar viaje');
    } on DioException catch (e) {
      debugPrint('❌ DioException en iniciarViaje: ${e.type}');
      throw _handleDioError(e, 'iniciar viaje');
    } catch (e) {
      debugPrint('❌ Exception en iniciarViaje: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== LLEGADA A MINA ====================

  /// POST /transportista/viaje/{asignacionId}/llegada-mina
  /// Transición: En camino a la mina → Esperando carguío
  Future<TransicionEstadoResponse> confirmarLlegadaMina({
    required int asignacionId,
    required double lat,
    required double lng,
    String? observaciones,
    List<String>? fotosUrls,
    bool? palaOperativa,
    bool? mineralVisible,
    bool? espacioParaCarga,
  }) async {
    try {
      debugPrint(
        '📍 Confirmando llegada a mina para asignacionId: $asignacionId',
      );

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/llegada-mina',
        data: {
          'lat': lat,
          'lng': lng,
          if (observaciones != null) 'observaciones': observaciones,
          if (fotosUrls != null && fotosUrls.isNotEmpty) 'fotosUrls': fotosUrls,
          if (palaOperativa != null) 'palaOperativa': palaOperativa,
          if (mineralVisible != null) 'mineralVisible': mineralVisible,
          if (espacioParaCarga != null) 'espacioParaCarga': espacioParaCarga,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Llegada a mina confirmada');
        return TransicionEstadoResponse.fromJson(response.data);
      }

      throw Exception(
        response.data['message'] ?? 'Error al confirmar llegada a mina',
      );
    } on DioException catch (e) {
      debugPrint('❌ DioException en confirmarLlegadaMina: ${e.type}');
      throw _handleDioError(e, 'confirmar llegada a mina');
    } catch (e) {
      debugPrint('❌ Exception en confirmarLlegadaMina: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== CARGUÍO ====================

  /// POST /transportista/viaje/{asignacionId}/confirmar-carguio
  /// Transición: Esperando carguío → En camino balanza cooperativa
  Future<TransicionEstadoResponse> confirmarCarguio({
    required int asignacionId,
    required double lat,
    required double lng,
    String? observaciones,
    List<String>? fotosUrls,
    double? pesoEstimadoKg,
  }) async {
    try {
      debugPrint('⚖️ Confirmando carguío para asignacionId: $asignacionId');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/confirmar-carguio',
        data: {
          'lat': lat,
          'lng': lng,
          if (observaciones != null) 'observaciones': observaciones,
          if (fotosUrls != null && fotosUrls.isNotEmpty) 'fotosUrls': fotosUrls,
          if (pesoEstimadoKg != null) 'pesoEstimadoKg': pesoEstimadoKg,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Carguío confirmado');
        return TransicionEstadoResponse.fromJson(response.data);
      }

      throw Exception(response.data['message'] ?? 'Error al confirmar carguío');
    } on DioException catch (e) {
      debugPrint('❌ DioException en confirmarCarguio: ${e.type}');
      throw _handleDioError(e, 'confirmar carguío');
    } catch (e) {
      debugPrint('❌ Exception en confirmarCarguio: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== PESAJE ====================

  /// POST /transportista/viaje/{asignacionId}/registrar-pesaje
  /// Transiciones:
  /// - En camino balanza cooperativa → En camino balanza destino (tipoPesaje: "cooperativa")
  /// - En camino balanza destino → En camino almacén destino (tipoPesaje: "destino")
  Future<TransicionEstadoResponse> registrarPesaje({
    required int asignacionId,
    required String tipoPesaje,
    required double pesoBrutoKg,
    required double pesoTaraKg,
    String? observaciones,
    String? ticketPesajeUrl,
  }) async {
    try {
      debugPrint(
        '⚖️ Registrando pesaje $tipoPesaje para asignacionId: $asignacionId',
      );

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/registrar-pesaje',
        data: {
          'tipoPesaje': tipoPesaje,
          'pesoBrutoKg': pesoBrutoKg,
          'pesoTaraKg': pesoTaraKg,
          if (observaciones != null) 'observaciones': observaciones,
          if (ticketPesajeUrl != null) 'ticketPesajeUrl': ticketPesajeUrl,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Pesaje registrado');
        return TransicionEstadoResponse.fromJson(response.data);
      }

      throw Exception(response.data['message'] ?? 'Error al registrar pesaje');
    } on DioException catch (e) {
      debugPrint('❌ DioException en registrarPesaje: ${e.type}');
      throw _handleDioError(e, 'registrar pesaje');
    } catch (e) {
      debugPrint('❌ Exception en registrarPesaje: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== DESCARGA ====================

  /// POST /transportista/viaje/{asignacionId}/iniciar-descarga
  /// Transición: En camino almacén destino → Descargando
  Future<TransicionEstadoResponse> iniciarDescarga({
    required int asignacionId,
    required double lat,
    required double lng,
  }) async {
    try {
      debugPrint('📦 Iniciando descarga para asignacionId: $asignacionId');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/iniciar-descarga',
        data: {'lat': lat, 'lng': lng},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Descarga iniciada');
        return TransicionEstadoResponse.fromJson(response.data);
      }

      throw Exception(response.data['message'] ?? 'Error al iniciar descarga');
    } on DioException catch (e) {
      debugPrint('❌ DioException en iniciarDescarga: ${e.type}');
      throw _handleDioError(e, 'iniciar descarga');
    } catch (e) {
      debugPrint('❌ Exception en iniciarDescarga: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  /// POST /transportista/viaje/{asignacionId}/confirmar-descarga
  /// Transición: Descargando → Completado
  Future<TransicionEstadoResponse> confirmarDescarga({
    required int asignacionId,
    required double lat,
    required double lng,
    String? observaciones,
    List<String>? fotosUrls,
    String? firmaReceptor,
  }) async {
    try {
      debugPrint('✅ Confirmando descarga para asignacionId: $asignacionId');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/confirmar-descarga',
        data: {
          'lat': lat,
          'lng': lng,
          if (observaciones != null) 'observaciones': observaciones,
          if (fotosUrls != null && fotosUrls.isNotEmpty) 'fotosUrls': fotosUrls,
          if (firmaReceptor != null) 'firmaReceptor': firmaReceptor,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Descarga confirmada - Viaje completado');
        return TransicionEstadoResponse.fromJson(response.data);
      }

      throw Exception(
        response.data['message'] ?? 'Error al confirmar descarga',
      );
    } on DioException catch (e) {
      debugPrint('❌ DioException en confirmarDescarga: ${e.type}');
      throw _handleDioError(e, 'confirmar descarga');
    } catch (e) {
      debugPrint('❌ Exception en confirmarDescarga: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== UPLOAD EVIDENCIA ====================

  /// Sube una evidencia (imagen)
  /// Retorna el objectName del archivo subido
  Future<String> uploadEvidencia(File file, int asignacionId) async {
    try {
      debugPrint('📤 Subiendo evidencia para asignacionId: $asignacionId');

      final objectName = await _apiProvider.uploadFile(
        file,
        folder: 'evidencias/viajes/$asignacionId',
      );

      debugPrint('✅ Evidencia subida: $objectName');
      return objectName;
    } on DioException catch (e) {
      debugPrint('❌ DioException en uploadEvidencia: ${e.type}');
      throw _handleDioError(e, 'subir evidencia');
    } catch (e) {
      debugPrint('❌ Error al subir evidencia: $e');
      if (e is NetworkException) rethrow;
      throw NetworkException(
        'No se pudo subir la evidencia. Verifica tu conexión.',
        type: NetworkExceptionType.noConnection,
      );
    }
  }

  // ==================== EVENTO UNIFICADO (OPCIONAL) ====================

  /// POST /transportista/viaje/{asignacionId}/evento
  /// Endpoint unificado para cualquier evento del viaje
  Future<TransicionEstadoResponse> registrarEvento({
    required int asignacionId,
    required String tipoEvento,
    double? lat,
    double? lng,
    String? comentario,
    List<String>? evidencias,
    double? pesoBruto,
    double? pesoTara,
    Map<String, dynamic>? metadatosExtra,
  }) async {
    try {
      debugPrint(
        '📝 Registrando evento: $tipoEvento para asignacionId: $asignacionId',
      );

      final data = <String, dynamic>{'tipoEvento': tipoEvento};

      if (lat != null) data['lat'] = lat;
      if (lng != null) data['lng'] = lng;
      if (comentario != null) data['comentario'] = comentario;
      if (evidencias != null && evidencias.isNotEmpty) {
        data['evidencias'] = evidencias;
      }
      if (pesoBruto != null && pesoTara != null) {
        data['datosPesaje'] = {'pesoBruto': pesoBruto, 'pesoTara': pesoTara};
      }
      if (metadatosExtra != null) {
        data['metadatosExtra'] = metadatosExtra;
      }

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/evento',
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Evento registrado');
        return TransicionEstadoResponse.fromJson(response.data);
      }

      throw Exception(response.data['message'] ?? 'Error al registrar evento');
    } on DioException catch (e) {
      debugPrint('❌ DioException en registrarEvento: ${e.type}');
      throw _handleDioError(e, 'registrar evento');
    } catch (e) {
      debugPrint('❌ Exception en registrarEvento: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== CONSULTAS ====================

  /// GET /transportista/viaje/{asignacionId}/estado
  /// Obtiene el estado actual y eventos del viaje
  Future<EstadoViajeResponse> getEstadoViaje(int asignacionId) async {
    try {
      debugPrint(
        '📊 Obteniendo estado del viaje para asignacionId: $asignacionId',
      );

      final response = await _dio.get(
        '/transportista/viaje/$asignacionId/estado',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ Estado del viaje obtenido');
        return EstadoViajeResponse.fromJson(response.data);
      }

      throw Exception(
        response.data['message'] ?? 'Error al obtener estado del viaje',
      );
    } on DioException catch (e) {
      debugPrint('❌ DioException en getEstadoViaje: ${e.type}');
      throw _handleDioError(e, 'obtener estado del viaje');
    } catch (e) {
      debugPrint('❌ Exception en getEstadoViaje: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== MANEJO DE ERRORES ====================

  Exception _handleDioError(DioException e, String action) {
    debugPrint('🔍 Analizando DioError tipo: ${e.type}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Tiempo de espera agotado al $action. Los datos se guardarán localmente.',
          type: NetworkExceptionType.timeout,
        );

      case DioExceptionType.connectionError:
        if (e.error is SocketException) {
          return NetworkException(
            'Sin conexión a internet. Los datos se guardarán localmente.',
            type: NetworkExceptionType.noConnection,
          );
        }
        return NetworkException(
          'Error de conexión al $action. Verifica tu red.',
          type: NetworkExceptionType.noConnection,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'];

        if (statusCode == 400) {
          return Exception(message ?? 'Solicitud inválida al $action');
        } else if (statusCode == 401) {
          return Exception(
            'Sesión expirada. Por favor, inicia sesión nuevamente.',
          );
        } else if (statusCode == 403) {
          return Exception('No tienes permiso para realizar esta acción');
        } else if (statusCode == 404) {
          return Exception('Recurso no encontrado');
        } else if (statusCode == 500 ||
            statusCode == 502 ||
            statusCode == 503) {
          return NetworkException(
            'Error del servidor al $action. Los datos se guardarán localmente.',
            type: NetworkExceptionType.serverError,
          );
        }
        return NetworkException(
          'Error del servidor (${statusCode ?? "desconocido"})',
          type: NetworkExceptionType.serverError,
        );

      case DioExceptionType.cancel:
        return Exception('Operación cancelada');

      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return NetworkException(
            'Sin conexión a internet al $action.',
            type: NetworkExceptionType.noConnection,
          );
        }
        return NetworkException(
          'Error desconocido al $action: ${e.message}',
          type: NetworkExceptionType.unknown,
        );

      default:
        return NetworkException(
          'Error de conexión: ${e.message}',
          type: NetworkExceptionType.unknown,
        );
    }
  }
}

// ==================== MODELOS DE RESPUESTA ====================

/// Respuesta del estado del viaje
class EstadoViajeResponse {
  final bool success;
  final int asignacionId;
  final String estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final Map<String, dynamic> observaciones;

  EstadoViajeResponse({
    required this.success,
    required this.asignacionId,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    required this.observaciones,
  });

  factory EstadoViajeResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return EstadoViajeResponse(
      success: json['success'] as bool? ?? false,
      asignacionId: data['asignacionId'] as int? ?? 0,
      estado: data['estado'] as String? ?? '',
      fechaInicio: data['fechaInicio'] != null
          ? DateTime.parse(data['fechaInicio'])
          : null,
      fechaFin: data['fechaFin'] != null
          ? DateTime.parse(data['fechaFin'])
          : null,
      observaciones: data['observaciones'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Respuesta de transición de estado del backend
class TransicionEstadoResponse {
  final bool success;
  final String message;
  final String estadoAnterior;
  final String estadoNuevo;
  final String proximoPaso;
  final ProximoPuntoControl? proximoPuntoControl;

  TransicionEstadoResponse({
    required this.success,
    required this.message,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.proximoPaso,
    this.proximoPuntoControl,
  });

  factory TransicionEstadoResponse.fromJson(Map<String, dynamic> json) {
    return TransicionEstadoResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      estadoAnterior: json['estadoAnterior'] as String? ?? '',
      estadoNuevo: json['estadoNuevo'] as String? ?? '',
      proximoPaso: json['proximoPaso'] as String? ?? '',
      proximoPuntoControl: json['proximoPuntoControl'] != null
          ? ProximoPuntoControl.fromJson(json['proximoPuntoControl'])
          : null,
    );
  }
}

/// Próximo punto de control
class ProximoPuntoControl {
  final String tipo;
  final String nombre;
  final double latitud;
  final double longitud;

  ProximoPuntoControl({
    required this.tipo,
    required this.nombre,
    required this.latitud,
    required this.longitud,
  });

  factory ProximoPuntoControl.fromJson(Map<String, dynamic> json) {
    return ProximoPuntoControl(
      tipo: json['tipo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
