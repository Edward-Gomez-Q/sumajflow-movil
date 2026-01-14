// lib/core/services/websocket_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';

enum WebSocketStatus { connecting, connected, disconnected, error }

class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();

  StompClient? _stompClient;
  Timer? _reconnectTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final Rx<WebSocketStatus> _status = WebSocketStatus.disconnected.obs;
  final RxList<Map<String, dynamic>> _notifications =
      <Map<String, dynamic>>[].obs;
  final RxInt _unreadCount = 0.obs;
  final RxBool _hasInternet = true.obs;

  WebSocketStatus get status => _status.value;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount.value;

  static final String _wsUrl = ApiConstants.wsUrl;
  static const Duration _reconnectDelay = Duration(seconds: 10);
  static const int _maxReconnectAttempts = 3;

  int _reconnectAttempts = 0;
  bool _isIntentionalDisconnect = false;

  Future<WebSocketService> init() async {
    _monitorConnectivity();
    // No conectar automáticamente en init, esperar a que haya conexión
    if (_hasInternet.value) {
      await connect();
    }
    return this;
  }

  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      final hadInternet = _hasInternet.value;
      _hasInternet.value = hasConnection;

      if (hasConnection && !hadInternet) {
        debugPrint(
          '🌐 Conexión a internet restaurada, reconectando WebSocket...',
        );
        _reconnectAttempts = 0;
        connect();
      } else if (!hasConnection && hadInternet) {
        debugPrint('📴 Sin conexión a internet, desconectando WebSocket...');
        _disconnectSilently();
      }
    });
  }

  Future<void> connect() async {
    // No intentar conectar si no hay internet
    if (!_hasInternet.value) {
      debugPrint('📴 Sin internet, no se puede conectar WebSocket');
      _status.value = WebSocketStatus.disconnected;
      return;
    }

    // No reconectar si ya estamos conectados o conectando
    if (_status.value == WebSocketStatus.connected ||
        _status.value == WebSocketStatus.connecting) {
      return;
    }

    // Límite de reintentos
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint(
        '⚠️ Máximo de reintentos alcanzado, esperando conexión estable',
      );
      return;
    }

    try {
      _status.value = WebSocketStatus.connecting;
      final authService = AuthService.to;
      final token = authService.authToken;
      final userId = authService.usuarioId;

      if (token == null || userId == null) {
        debugPrint('⚠️ No hay token o userId, no se puede conectar WebSocket');
        _status.value = WebSocketStatus.disconnected;
        return;
      }

      debugPrint(
        '🔌 Conectando WebSocket (intento ${_reconnectAttempts + 1}/$_maxReconnectAttempts)',
      );

      _isIntentionalDisconnect = false;

      _stompClient = StompClient(
        config: StompConfig(
          url: _wsUrl,
          onConnect: (StompFrame frame) => _onConnect(frame, userId),
          onWebSocketError: (dynamic error) => _onWebSocketError(error),
          onStompError: (StompFrame frame) => _onStompError(frame),
          onDisconnect: (_) => _onDisconnect(),
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
          heartbeatIncoming: const Duration(seconds: 20),
          heartbeatOutgoing: const Duration(seconds: 20),
          connectionTimeout: const Duration(seconds: 5),
        ),
      );

      _stompClient!.activate();
      _reconnectAttempts++;
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  void _onConnect(StompFrame frame, int userId) {
    _status.value = WebSocketStatus.connected;
    _reconnectAttempts = 0; // Reset al conectar exitosamente
    debugPrint('✅ WebSocket conectado correctamente');

    final destination = '/user/queue/notificaciones';
    debugPrint('📬 Suscribiéndose a: $destination');

    try {
      _stompClient!.subscribe(
        destination: destination,
        callback: (frame) {
          if (frame.body != null) {
            _handleNotification(frame.body!);
          }
        },
      );
      debugPrint('✅ Suscripción completada');
    } catch (e) {
      debugPrint('❌ Error en suscripción: $e');
    }
  }

  void _onWebSocketError(dynamic error) {
    // Solo loguear si no es un error de conexión esperado
    if (error is SocketException ||
        error.toString().contains('Network is unreachable')) {
      if (_status.value != WebSocketStatus.disconnected) {
        debugPrint('📴 WebSocket: Sin conexión de red');
      }
    } else {
      debugPrint('❌ Error WebSocket: $error');
    }

    _status.value = WebSocketStatus.error;
    _scheduleReconnectIfNeeded();
  }

  void _onStompError(StompFrame frame) {
    debugPrint('❌ Error STOMP: ${frame.body}');
    _status.value = WebSocketStatus.error;
  }

  void _onDisconnect() {
    if (_isIntentionalDisconnect) {
      debugPrint('🔌 WebSocket desconectado intencionalmente');
      _status.value = WebSocketStatus.disconnected;
      return;
    }

    debugPrint('🔌 WebSocket desconectado inesperadamente');
    _status.value = WebSocketStatus.disconnected;
    _scheduleReconnectIfNeeded();
  }

  void _handleConnectionError(dynamic error) {
    if (error is SocketException ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('Connection failed')) {
      // Error de red esperado - no loguear excesivamente
      if (_status.value != WebSocketStatus.disconnected) {
        debugPrint('📴 WebSocket: No se pudo conectar (sin red)');
      }
    } else {
      debugPrint('❌ Error al conectar WebSocket: $error');
    }

    _status.value = WebSocketStatus.error;
    _scheduleReconnectIfNeeded();
  }

  void _handleNotification(String body) {
    try {
      debugPrint('📬 Notificación recibida: $body');

      final data = {
        'message': body,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      };

      _notifications.insert(0, data);
      _unreadCount.value++;
    } catch (e) {
      debugPrint('❌ Error procesando notificación: $e');
    }
  }

  void disconnect() {
    _isIntentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts =
        _maxReconnectAttempts; // Prevenir reconexión automática

    try {
      _stompClient?.deactivate();
    } catch (e) {
      debugPrint('⚠️ Error al desconectar: $e');
    }

    _status.value = WebSocketStatus.disconnected;
    debugPrint('🔌 WebSocket desconectado manualmente');
  }

  void _disconnectSilently() {
    _reconnectTimer?.cancel();
    try {
      _stompClient?.deactivate();
    } catch (e) {
      // Ignorar errores al desconectar
    }
    _status.value = WebSocketStatus.disconnected;
  }

  void _scheduleReconnectIfNeeded() {
    // No reconectar si:
    // 1. Fue desconexión intencional
    // 2. No hay internet
    // 3. Se alcanzó el máximo de reintentos
    if (_isIntentionalDisconnect ||
        !_hasInternet.value ||
        _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_hasInternet.value && !_isIntentionalDisconnect) {
        debugPrint('🔄 Reintentando conexión WebSocket...');
        connect();
      }
    });
  }

  // Método para reiniciar intentos manualmente (útil al hacer login)
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    _isIntentionalDisconnect = false;
  }

  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['read'] = true;
      _unreadCount.value = _notifications
          .where((n) => n['read'] != true)
          .length;
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['read'] = true;
    }
    _unreadCount.value = 0;
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount.value = 0;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    disconnect();
    super.onClose();
  }
}
