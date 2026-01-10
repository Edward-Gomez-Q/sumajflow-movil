import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:sumajflow_movil/core/services/auth_service.dart';
import 'package:sumajflow_movil/core/constants/api_constants.dart';

enum WebSocketStatus { connecting, connected, disconnected, error }

class WebSocketService extends GetxService {
  static WebSocketService get to => Get.find();

  StompClient? _stompClient;
  Timer? _reconnectTimer;

  final Rx<WebSocketStatus> _status = WebSocketStatus.disconnected.obs;
  final RxList<Map<String, dynamic>> _notifications =
      <Map<String, dynamic>>[].obs;
  final RxInt _unreadCount = 0.obs;

  WebSocketStatus get status => _status.value;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount.value;

  static final String _wsUrl = ApiConstants.wsUrl;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  Future<WebSocketService> init() async {
    await connect();
    return this;
  }

  Future<void> connect() async {
    if (_status.value == WebSocketStatus.connected ||
        _status.value == WebSocketStatus.connecting) {
      return;
    }

    try {
      _status.value = WebSocketStatus.connecting;
      final authService = AuthService.to;
      final token = authService.authToken;
      final userId = authService.usuarioId;

      if (token == null || userId == null) {
        debugPrint('No hay token o userId, no se puede conectar WebSocket');
        _status.value = WebSocketStatus.disconnected;
        return;
      }

      debugPrint('🔌 Conectando WebSocket con userId: $userId');

      _stompClient = StompClient(
        config: StompConfig(
          url: _wsUrl,
          onConnect: (StompFrame frame) => _onConnect(frame, userId),

          onWebSocketError: (dynamic error) {
            debugPrint('❌ Error WebSocket: $error');
            _status.value = WebSocketStatus.error;
            _scheduleReconnect();
          },

          onStompError: (StompFrame frame) {
            debugPrint('❌ Error STOMP: ${frame.body}');
            _status.value = WebSocketStatus.error;
          },

          onDisconnect: (_) {
            debugPrint('🔌 WebSocket desconectado');
            _status.value = WebSocketStatus.disconnected;
            _scheduleReconnect();
          },

          // ✅ Headers con token JWT
          stompConnectHeaders: {'Authorization': 'Bearer $token'},

          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},

          // ✅ Heartbeat
          heartbeatIncoming: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 10),
        ),
      );

      _stompClient!.activate();
      debugPrint('🔄 Activando cliente STOMP...');
    } catch (e) {
      debugPrint('❌ Error al conectar WebSocket: $e');
      _status.value = WebSocketStatus.error;
      _scheduleReconnect();
    }
  }

  void _onConnect(StompFrame frame, int userId) {
    _status.value = WebSocketStatus.connected;
    debugPrint('✅ WebSocket STOMP conectado correctamente');
    debugPrint('📡 Frame headers: ${frame.headers}');

    // ✅ SUSCRIPCIÓN CORRECTA - Spring añade el userId automáticamente
    final destination = '/user/queue/notificaciones';

    debugPrint('📬 Suscribiéndose a: $destination');

    _stompClient!.subscribe(
      destination: destination,
      callback: (frame) {
        debugPrint('📨 Mensaje recibido en /user/queue/notificaciones');
        if (frame.body != null) {
          _handleNotification(frame.body!);
        }
      },
    );

    debugPrint('✅ Suscripción completada exitosamente');
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
    _reconnectTimer?.cancel();
    _stompClient?.deactivate();
    _status.value = WebSocketStatus.disconnected;
    debugPrint('🔌 WebSocket desconectado manualmente');
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

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      debugPrint('🔄 Reintentando conexión WebSocket...');
      connect();
    });
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
