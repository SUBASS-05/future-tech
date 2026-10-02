import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../api/api_service.dart';
import 'sync_event.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  bool _isConnected = false;
  bool _shouldReconnect = false;
  
  String? _token;
  String? _role;

  int _retryAttempt = 0;
  Timer? _reconnectTimer;

  final Set<String> _seenEventIds = {};
  static const int _maxSeenEventIds = 200;

  final StreamController<SyncEvent> _eventStreamController = StreamController<SyncEvent>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<SyncEvent> get eventStream => _eventStreamController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected;

  String _buildWsUrl(String httpUrl) {
    String wsUrl = httpUrl;
    if (wsUrl.startsWith('http://')) {
      wsUrl = wsUrl.replaceFirst('http://', 'ws://');
    } else if (wsUrl.startsWith('https://')) {
      wsUrl = wsUrl.replaceFirst('https://', 'wss://');
    }

    if (wsUrl.endsWith('/api')) {
      wsUrl = wsUrl.substring(0, wsUrl.length - 4);
    } else if (wsUrl.endsWith('/api/')) {
      wsUrl = wsUrl.substring(0, wsUrl.length - 5);
    }

    if (wsUrl.endsWith('/')) {
      wsUrl = '${wsUrl}ws';
    } else {
      wsUrl = '$wsUrl/ws';
    }

    return wsUrl;
  }

  Future<void> connect({required String token, required String role}) async {
    _token = token;
    _role = role;
    _shouldReconnect = true;
    _retryAttempt = 0;

    await _initClient();
  }

  Future<void> _initClient() async {
    if (_token == null || !_shouldReconnect) return;

    // Clean up existing client if any
    _reconnectTimer?.cancel();
    _stompClient?.deactivate();

    final baseUrl = await ApiService.getValidBaseUrl();
    final wsUrl = _buildWsUrl(baseUrl);

    debugPrint('[WebSocket] Connecting to $wsUrl');

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: _onWebSocketError,
        onStompError: _onStompError,
        stompConnectHeaders: {
          'Authorization': 'Bearer $_token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $_token',
        },
        reconnectDelay: Duration.zero, // Controlled manually via exponential backoff
      ),
    );

    _stompClient?.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('[WebSocket] Connected successfully!');
    _isConnected = true;
    _retryAttempt = 0;
    _connectionStatusController.add(true);

    // Subscribe to personal user queue
    _stompClient?.subscribe(
      destination: '/user/queue/updates',
      callback: _handleIncomingFrame,
    );

    // Subscribe to admin topic if admin
    if (_role == 'ADMIN' || _role == 'TOP_ADMIN') {
      _stompClient?.subscribe(
        destination: '/topic/admin',
        callback: _handleIncomingFrame,
      );
    }

    // Trigger a RECONNECTED event so providers can refresh state missed during offline period
    _eventStreamController.add(SyncEvent(
      eventId: 'reconnected_${DateTime.now().millisecondsSinceEpoch}',
      eventType: 'WS_RECONNECTED',
      entityType: 'SYSTEM',
      timestamp: DateTime.now().toIso8601String(),
    ));
  }

  void _handleIncomingFrame(StompFrame frame) {
    if (frame.body == null || frame.body!.isEmpty) return;

    try {
      debugPrint('[WebSocket] Frame received: ${frame.body}');
      final event = SyncEvent.fromRawJson(frame.body!);

      // Deduplicate events
      if (event.eventId.isNotEmpty && _seenEventIds.contains(event.eventId)) {
        debugPrint('[WebSocket] Duplicate event ignored: ${event.eventId}');
        return;
      }

      if (event.eventId.isNotEmpty) {
        if (_seenEventIds.length >= _maxSeenEventIds) {
          _seenEventIds.remove(_seenEventIds.first);
        }
        _seenEventIds.add(event.eventId);
      }

      _eventStreamController.add(event);
    } catch (e) {
      debugPrint('[WebSocket] Failed to parse frame body: $e');
    }
  }

  void _onDisconnect(StompFrame frame) {
    debugPrint('[WebSocket] Disconnected');
    _isConnected = false;
    _connectionStatusController.add(false);
    _scheduleReconnection();
  }

  void _onWebSocketError(dynamic error) {
    debugPrint('[WebSocket] WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController.add(false);
    _scheduleReconnection();
  }

  void _onStompError(StompFrame frame) {
    debugPrint('[WebSocket] STOMP error: ${frame.body}');
    _isConnected = false;
    _connectionStatusController.add(false);
    _scheduleReconnection();
  }

  void _scheduleReconnection() {
    if (!_shouldReconnect || _token == null) return;

    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s max
    int delaySeconds = (1 << _retryAttempt);
    if (delaySeconds > 30) delaySeconds = 30;

    debugPrint('[WebSocket] Scheduling reconnection in $delaySeconds seconds (attempt ${_retryAttempt + 1})');

    _retryAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_shouldReconnect) {
        _initClient();
      }
    });
  }

  void disconnect() {
    debugPrint('[WebSocket] Manually disconnecting');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnected = false;
    _token = null;
    _role = null;
    _connectionStatusController.add(false);
  }

  void dispose() {
    disconnect();
    _eventStreamController.close();
    _connectionStatusController.close();
  }
}
