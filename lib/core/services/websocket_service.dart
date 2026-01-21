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
        debugPrint('🌐 Internet restaurado, reconectando WebSocket...');
        _reconnectAttempts = 0;
        connect();
      } else if (!hasConnection && hadInternet) {
        debugPrint('📴 Sin internet, desconectando WebSocket...');
        _disconnectSilently();
      }
    });
  }

  Future<void> connect() async {
    if (!_hasInternet.value) {
      debugPrint('📴 Sin internet');
      _status.value = WebSocketStatus.disconnected;
      return;
    }

    if (_status.value == WebSocketStatus.connected ||
        _status.value == WebSocketStatus.connecting) {
      debugPrint('⏭️ Ya conectado/conectando');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('⚠️ Máximo de reintentos alcanzado');
      return;
    }

    if (_stompClient != null) {
      debugPrint('🧹 Limpiando conexión anterior...');
      try {
        _stompClient!.deactivate();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('⚠️ Error limpiando: $e');
      }
      _stompClient = null;
    }

    try {
      _status.value = WebSocketStatus.connecting;
      final authService = AuthService.to;
      final token = authService.authToken;
      final userId = authService.usuarioId;

      if (token == null || userId == null) {
        debugPrint('⚠️ No hay token o userId');
        _status.value = WebSocketStatus.disconnected;
        return;
      }

      debugPrint(
        '🔌 Conectando WebSocket (intento ${_reconnectAttempts + 1}/$_maxReconnectAttempts)',
      );
      debugPrint('   URL: $_wsUrl');
      debugPrint('   Usuario ID: $userId');

      _isIntentionalDisconnect = false;

      _stompClient = StompClient(
        config: StompConfig(
          url: _wsUrl,
          onConnect: (StompFrame frame) => _onConnect(frame, userId),
          onWebSocketError: (dynamic error) => _onWebSocketError(error),
          onStompError: (StompFrame frame) => _onStompError(frame),
          onDisconnect: (_) => _onDisconnect(),
          beforeConnect: () async {
            debugPrint('⏳ Preparando conexión...');
            await Future.delayed(const Duration(milliseconds: 100));
          },
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
          heartbeatIncoming: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 10),
          connectionTimeout: const Duration(seconds: 8),
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
    _reconnectAttempts = 0;
    debugPrint('✅ WebSocket conectado');

    // Suscribirse a notificaciones del usuario
    final destination = '/user/queue/notificaciones';
    debugPrint('📬 Suscribiéndose a: $destination');

    try {
      _stompClient!.subscribe(
        destination: destination,
        callback: (frame) {
          if (frame.body != null) {
            debugPrint('📨 Notificación recibida: ${frame.body}');
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
    if (error is SocketException ||
        error.toString().contains('No route to host')) {
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
        error.toString().contains('No route to host')) {
      if (_status.value != WebSocketStatus.disconnected) {
        debugPrint('📴 No se pudo conectar (sin red)');
      }
    } else {
      debugPrint('❌ Error al conectar: $error');
    }

    _status.value = WebSocketStatus.error;
    _scheduleReconnectIfNeeded();
  }

  void _handleNotification(String body) {
    try {
      debugPrint('📬 Procesando notificación: $body');

      // El body ya viene como JSON desde el servidor
      final data = {
        'message': body,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      };

      _notifications.insert(0, data);
      _unreadCount.value++;

      debugPrint('✅ Notificación agregada. Total: ${_notifications.length}');
    } catch (e) {
      debugPrint('❌ Error procesando notificación: $e');
    }
  }

  void disconnect() async {
    debugPrint('🛑 Desconectando WebSocket...');
    _isIntentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts;

    if (_stompClient != null) {
      try {
        _stompClient!.deactivate();
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('⚠️ Error al desconectar: $e');
      }
      _stompClient = null;
    }

    _status.value = WebSocketStatus.disconnected;
    debugPrint('✅ WebSocket desconectado');
  }

  void _disconnectSilently() {
    _reconnectTimer?.cancel();
    try {
      _stompClient?.deactivate();
    } catch (e) {
      // Ignorar errores
    }
    _status.value = WebSocketStatus.disconnected;
  }

  void _scheduleReconnectIfNeeded() {
    if (_isIntentionalDisconnect ||
        !_hasInternet.value ||
        _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_hasInternet.value && !_isIntentionalDisconnect) {
        debugPrint('🔄 Reintentando conexión...');
        connect();
      }
    });
  }

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
