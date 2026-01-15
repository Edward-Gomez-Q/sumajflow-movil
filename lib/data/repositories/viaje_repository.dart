// lib/data/repositories/viaje_repository.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/exceptions/network_exception.dart';
import 'package:sumajflow_movil/data/providers/api_provider.dart';
import 'package:flutter/rendering.dart';

/// Repositorio para gestionar eventos del viaje operativo
/// Endpoints: /api/transportista/viaje/{asignacionId}/*
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
          return handler.reject(error);
        },
      ),
    );
  }

  // ==================== PASO 1: INICIAR VIAJE ====================

  /// POST /transportista/viaje/{asignacionId}/iniciar
  /// Transición: Esperando iniciar → En camino a la mina
  Future<TransicionEstadoResponse> iniciarViaje({
    required int asignacionId,
    required double lat,
    required double lng,
    String? observaciones,
  }) async {
    try {
      debugPrint('🚀 POST /transportista/viaje/$asignacionId/iniciar');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/iniciar',
        data: {
          'lat': lat,
          'lng': lng,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
        },
      );

      debugPrint('✅ Viaje iniciado exitosamente');
      return TransicionEstadoResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioException en iniciarViaje: ${e.type}');
      throw _handleDioError(e, 'iniciar viaje');
    } catch (e) {
      debugPrint('❌ Exception en iniciarViaje: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== PASO 2: LLEGADA A MINA ====================

  /// POST /transportista/viaje/{asignacionId}/llegada-mina
  /// Transición: En camino a la mina → Esperando carguío
  Future<TransicionEstadoResponse> confirmarLlegadaMina({
    required int asignacionId,
    required double lat,
    required double lng,
    required bool palaOperativa,
    required bool mineralVisible,
    String? observaciones,
    String? fotoReferenciaUrl,
  }) async {
    try {
      debugPrint('🏔️ POST /viaje/$asignacionId/llegada-mina');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/llegada-mina',
        data: {
          'lat': lat,
          'lng': lng,
          'palaOperativa': palaOperativa,
          'mineralVisible': mineralVisible,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
          if (fotoReferenciaUrl != null && fotoReferenciaUrl.isNotEmpty)
            'fotoReferenciaUrl': fotoReferenciaUrl,
        },
      );

      debugPrint('✅ Llegada a mina confirmada');
      return TransicionEstadoResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioException en confirmarLlegadaMina: ${e.type}');
      throw _handleDioError(e, 'confirmar llegada a mina');
    } catch (e) {
      debugPrint('❌ Exception en confirmarLlegadaMina: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== PASO 3: CARGUÍO ====================

  /// POST /transportista/viaje/{asignacionId}/carguio
  /// Transición: Esperando carguío → En camino balanza cooperativa
  Future<TransicionEstadoResponse> confirmarCarguio({
    required int asignacionId,
    required double lat,
    required double lng,
    required bool mineralCargadoCompletamente,
    String? observaciones,
    String? fotoCamionCargadoUrl,
  }) async {
    try {
      debugPrint('🚛 POST /viaje/$asignacionId/carguio');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/carguio',
        data: {
          'lat': lat,
          'lng': lng,
          'mineralCargadoCompletamente': mineralCargadoCompletamente,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
          if (fotoCamionCargadoUrl != null && fotoCamionCargadoUrl.isNotEmpty)
            'fotoCamionCargadoUrl': fotoCamionCargadoUrl,
        },
      );

      debugPrint('✅ Carguío confirmado');
      return TransicionEstadoResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioException en confirmarCarguio: ${e.type}');
      throw _handleDioError(e, 'confirmar carguío');
    } catch (e) {
      debugPrint('❌ Exception en confirmarCarguio: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== PASO 4: PESAJE COOPERATIVA ====================

  /// POST /transportista/viaje/{asignacionId}/pesaje-cooperativa
  /// Transición: En camino balanza cooperativa → En camino balanza destino
  Future<TransicionEstadoResponse> registrarPesajeCooperativa({
    required int asignacionId,
    required double lat,
    required double lng,
    required double pesoBrutoKg,
    required double pesoTaraKg,
    String? observaciones,
    String? ticketPesajeUrl,
  }) async {
    try {
      debugPrint('⚖️ POST /viaje/$asignacionId/pesaje-cooperativa');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/pesaje-cooperativa',
        data: {
          'lat': lat,
          'lng': lng,
          'pesoBrutoKg': pesoBrutoKg,
          'pesoTaraKg': pesoTaraKg,
          'tipoPesaje':
              'cooperativa', // Se setea en el backend pero lo incluimos
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
          if (ticketPesajeUrl != null && ticketPesajeUrl.isNotEmpty)
            'ticketPesajeUrl': ticketPesajeUrl,
        },
      );

      debugPrint('✅ Pesaje cooperativa registrado');
      return TransicionEstadoResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioException en registrarPesajeCooperativa: ${e.type}');
      throw _handleDioError(e, 'registrar pesaje cooperativa');
    } catch (e) {
      debugPrint('❌ Exception en registrarPesajeCooperativa: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== PASO 5: PESAJE DESTINO ====================

  /// POST /transportista/viaje/{asignacionId}/pesaje-destino
  /// Transición: En camino balanza destino → En camino almacén destino
  Future<TransicionEstadoResponse> registrarPesajeDestino({
    required int asignacionId,
    required double lat,
    required double lng,
    required double pesoBrutoKg,
    required double pesoTaraKg,
    String? observaciones,
    String? ticketPesajeUrl,
  }) async {
    try {
      debugPrint('⚖️ POST /viaje/$asignacionId/pesaje-destino');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/pesaje-destino',
        data: {
          'lat': lat,
          'lng': lng,
          'pesoBrutoKg': pesoBrutoKg,
          'pesoTaraKg': pesoTaraKg,
          'tipoPesaje': 'destino', // Se setea en el backend pero lo incluimos
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
          if (ticketPesajeUrl != null && ticketPesajeUrl.isNotEmpty)
            'ticketPesajeUrl': ticketPesajeUrl,
        },
      );

      debugPrint('✅ Pesaje destino registrado');
      return TransicionEstadoResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioException en registrarPesajeDestino: ${e.type}');
      throw _handleDioError(e, 'registrar pesaje destino');
    } catch (e) {
      debugPrint('❌ Exception en registrarPesajeDestino: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== PASO 6: LLEGADA A ALMACÉN ====================

  /// POST /transportista/viaje/{asignacionId}/llegada-almacen
  /// Transición: En camino almacén destino → Descargando
  Future<TransicionEstadoResponse> confirmarLlegadaAlmacen({
    required int asignacionId,
    required double lat,
    required double lng,
    required bool confirmacionLlegada,
    String? observaciones,
  }) async {
    try {
      debugPrint('🏭 POST /viaje/$asignacionId/llegada-almacen');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/llegada-almacen',
        data: {
          'lat': lat,
          'lng': lng,
          'confirmacionLlegada': confirmacionLlegada,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
        },
      );

      debugPrint('✅ Llegada a almacén confirmada');
      return TransicionEstadoResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioException en confirmarLlegadaAlmacen: ${e.type}');
      throw _handleDioError(e, 'confirmar llegada a almacén');
    } catch (e) {
      debugPrint('❌ Exception en confirmarLlegadaAlmacen: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== PASO 7: DESCARGA ====================

  /// POST /transportista/viaje/{asignacionId}/descarga
  /// Transición: Descargando → Descargando (preparado para finalizar)
  Future<TransicionEstadoResponse> confirmarDescarga({
    required int asignacionId,
    required double lat,
    required double lng,
    String? observaciones,
  }) async {
    try {
      debugPrint('📦 POST /viaje/$asignacionId/descarga');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/descarga',
        data: {
          'lat': lat,
          'lng': lng,
          if (observaciones != null && observaciones.isNotEmpty)
            'observaciones': observaciones,
        },
      );

      debugPrint('✅ Descarga confirmada');
      return TransicionEstadoResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioException en confirmarDescarga: ${e.type}');
      throw _handleDioError(e, 'confirmar descarga');
    } catch (e) {
      debugPrint('❌ Exception en confirmarDescarga: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== PASO 8: FINALIZAR RUTA ====================

  /// POST /transportista/viaje/{asignacionId}/finalizar
  /// Transición: Descargando → Completado
  Future<TransicionEstadoResponse> finalizarRuta({
    required int asignacionId,
    required double lat,
    required double lng,
    String? observacionesFinales,
  }) async {
    try {
      debugPrint('✅ POST /viaje/$asignacionId/finalizar');

      final response = await _dio.post(
        '/transportista/viaje/$asignacionId/finalizar',
        data: {
          'lat': lat,
          'lng': lng,
          if (observacionesFinales != null && observacionesFinales.isNotEmpty)
            'observacionesFinales': observacionesFinales,
        },
      );

      debugPrint('✅ Ruta finalizada - Viaje completado');
      return TransicionEstadoResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioException en finalizarRuta: ${e.type}');
      throw _handleDioError(e, 'finalizar ruta');
    } catch (e) {
      debugPrint('❌ Exception en finalizarRuta: $e');
      if (e is NetworkException) rethrow;
      throw Exception('Error inesperado: $e');
    }
  }

  // ==================== UPLOAD EVIDENCIA ====================

  /// Sube una evidencia (imagen) usando el ApiProvider
  /// Retorna el objectName del archivo subido en MinIO
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

/// Respuesta de transición de estado del backend
/// Corresponde a: TransicionEstadoResponseDto
class TransicionEstadoResponse {
  final bool success;
  final String message;
  final String estadoAnterior;
  final String estadoNuevo;
  final String proximoPaso;
  final ProximoPuntoControl? proximoPuntoControl;
  final Map<String, dynamic>? metadata;
  final DateTime? timestamp;

  TransicionEstadoResponse({
    required this.success,
    required this.message,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.proximoPaso,
    this.proximoPuntoControl,
    this.metadata,
    this.timestamp,
  });

  factory TransicionEstadoResponse.fromJson(Map<String, dynamic> json) {
    return TransicionEstadoResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      estadoAnterior: json['estadoAnterior'] as String? ?? '',
      estadoNuevo: json['estadoNuevo'] as String? ?? '',
      proximoPaso: json['proximoPaso'] as String? ?? '',
      proximoPuntoControl: json['proximoPuntoControl'] != null
          ? ProximoPuntoControl.fromJson(
              json['proximoPuntoControl'] as Map<String, dynamic>,
            )
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'estadoAnterior': estadoAnterior,
      'estadoNuevo': estadoNuevo,
      'proximoPaso': proximoPaso,
      if (proximoPuntoControl != null)
        'proximoPuntoControl': proximoPuntoControl!.toJson(),
      if (metadata != null) 'metadata': metadata,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}

/// Próximo punto de control
/// Corresponde a: ProximoPuntoControlDto
class ProximoPuntoControl {
  final String tipo; // mina, balanza_cooperativa, balanza_destino, almacen
  final String nombre;
  final double latitud;
  final double longitud;
  final String? descripcion;

  ProximoPuntoControl({
    required this.tipo,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.descripcion,
  });

  factory ProximoPuntoControl.fromJson(Map<String, dynamic> json) {
    return ProximoPuntoControl(
      tipo: json['tipo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}
