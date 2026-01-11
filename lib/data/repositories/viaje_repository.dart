// lib/data/repositories/viaje_repository.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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
          debugPrint('🔵 Headers: ${options.headers}');
          debugPrint('🔵 Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ Response [${response.statusCode}]: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Error en viaje repository: ${error.message}');
          debugPrint('❌ Response: ${error.response?.data}');
          return handler.next(error);
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
      debugPrint('❌ DioException en iniciarViaje: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en iniciarViaje: $e');
      rethrow;
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
      debugPrint('❌ DioException en confirmarLlegadaMina: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en confirmarLlegadaMina: $e');
      rethrow;
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
      debugPrint('❌ DioException en confirmarCarguio: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en confirmarCarguio: $e');
      rethrow;
    }
  }

  // ==================== PESAJE ====================

  /// POST /transportista/viaje/{asignacionId}/registrar-pesaje
  /// Transiciones:
  /// - En camino balanza cooperativa → En camino balanza destino (tipoPesaje: "cooperativa")
  /// - En camino balanza destino → En camino almacén destino (tipoPesaje: "destino")
  Future<TransicionEstadoResponse> registrarPesaje({
    required int asignacionId,
    required String tipoPesaje, // "cooperativa" o "destino"
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
      debugPrint('❌ DioException en registrarPesaje: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en registrarPesaje: $e');
      rethrow;
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
      debugPrint('❌ DioException en iniciarDescarga: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en iniciarDescarga: $e');
      rethrow;
    }
  }

  /// Sube una evidencia (imagen) sin token de autenticación
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
    } catch (e) {
      debugPrint('❌ Error al subir evidencia: $e');
      rethrow;
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
      debugPrint('❌ DioException en confirmarDescarga: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en confirmarDescarga: $e');
      rethrow;
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
      debugPrint('❌ DioException en registrarEvento: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en registrarEvento: $e');
      rethrow;
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
      debugPrint('❌ DioException en getEstadoViaje: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('❌ Exception en getEstadoViaje: $e');
      rethrow;
    }
  }

  // ==================== UTILIDADES ====================

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final message = e.response!.data['message'] ?? 'Error del servidor';
      return Exception(message);
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Tiempo de conexión agotado');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de respuesta agotado');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Sin conexión a internet');
    }
    return Exception('Error de conexión: ${e.message}');
  }
}

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
