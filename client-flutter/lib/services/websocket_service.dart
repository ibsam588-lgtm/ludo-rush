import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SocketConnectionPhase { idle, connecting, connected, reconnecting }

class WebSocketService {
  WebSocketService({WebSocketChannel Function(Uri)? connector})
      : _connector = connector ?? WebSocketChannel.connect;
  final WebSocketChannel Function(Uri) _connector;
  static const _backendWss = 'wss://ludo-rush-backend.ibsam588.workers.dev';
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  String? _socketPath;
  String? playerId;
  String? displayName;
  String? authToken;
  bool spectator = false;
  int _attempt = 0;
  bool _connected = false;
  bool _disposed = false;
  final _messages = StreamController<dynamic>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  final _phases = StreamController<SocketConnectionPhase>.broadcast();
  Stream<dynamic> get messages => _messages.stream;
  Stream<bool> get connections => _connections.stream;
  Stream<SocketConnectionPhase> get phases => _phases.stream;
  bool get isConnected => _connected;
  SocketConnectionPhase phase = SocketConnectionPhase.idle;
  int reconnectAttempts = 0;

  void _setPhase(SocketConnectionPhase value) {
    if (phase == value) return;
    phase = value;
    if (!_disposed) _phases.add(value);
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!_disposed) _connections.add(value);
  }

  void connect(String socketPath) {
    disconnect();
    if (_disposed) return;
    _socketPath = socketPath;
    reconnectAttempts = 0;
    _setPhase(SocketConnectionPhase.connecting);
    unawaited(_doConnect());
  }

  Future<void> _doConnect() async {
    if (_disposed || _socketPath == null || playerId == null) return;
    final attempt = ++_attempt;
    final uri = Uri.parse('$_backendWss$_socketPath');
    final url = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'playerId': playerId!,
      'displayName': displayName ?? '',
      'token': authToken ?? '',
    });
    try {
      final channel = _connector(url);
      _channel = channel;
      _sub = channel.stream.listen(
        (msg) {
          if (attempt == _attempt && !_disposed) _messages.add(msg);
        },
        onError: (_) => _scheduleReconnect(attempt),
        onDone: () => _scheduleReconnect(attempt),
      );
      await channel.ready.timeout(const Duration(seconds: 10));
      if (attempt != _attempt || _disposed) return;
      _setConnected(true);
      reconnectAttempts = 0;
      _setPhase(SocketConnectionPhase.connected);
      // Rejoin on every successful handshake, including reconnects. A fixed
      // delay can lose the join on a slow network and leave the table waiting.
      send({
        'type': spectator ? 'spectate' : 'join',
        'playerId': playerId,
        'displayName': displayName ?? 'Player'
      });
    } catch (_) {
      _scheduleReconnect(attempt);
    }
  }

  void _scheduleReconnect(int attempt) {
    if (_disposed || _socketPath == null || attempt != _attempt) return;
    ++_attempt;
    reconnectAttempts++;
    _setConnected(false);
    _setPhase(SocketConnectionPhase.reconnecting);
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _doConnect);
  }

  void send(Map<String, dynamic> msg) {
    if (!_connected) return;
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (_) {
      _scheduleReconnect(_attempt);
    }
  }

  void disconnect() {
    ++_attempt;
    _socketPath = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _setConnected(false);
    reconnectAttempts = 0;
    _setPhase(SocketConnectionPhase.idle);
  }

  void dispose() {
    disconnect();
    _disposed = true;
    _messages.close();
    _connections.close();
    _phases.close();
  }
}
