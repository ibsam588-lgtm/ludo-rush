import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  static const String _backendWss =
      'wss://ludo-rush-backend.ibsam588.workers.dev';

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  String? _socketPath;
  String? playerId;
  String? displayName;
  String? authToken;

  final StreamController<dynamic> _msgController = StreamController.broadcast();
  Stream<dynamic> get messages => _msgController.stream;

  bool get isConnected => _channel != null;

  void connect(String socketPath) {
    _socketPath = socketPath;
    _reconnectTimer?.cancel();
    _doConnect();
  }

  void _doConnect() {
    if (_socketPath == null || playerId == null) return;
    final encoded = Uri.encodeComponent(displayName ?? '');
    final token = Uri.encodeComponent(authToken ?? '');
    final url =
        '$_backendWss$_socketPath?playerId=$playerId&displayName=$encoded&token=$token';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _sub = _channel!.stream.listen(
        (msg) => _msgController.add(msg),
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_socketPath == null) return;
    _sub?.cancel();
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _doConnect);
  }

  void send(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socketPath = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }
}
