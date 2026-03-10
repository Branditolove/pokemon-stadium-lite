import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _lastError;

  // Guarda los listeners antes de que el socket exista
  final Map<String, Function(dynamic)> _pendingListeners = {};

  SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  bool get isConnected => _isConnected;
  String? get lastError => _lastError;

  void connect(String baseUrl) {
    try {
      // Desconectar socket anterior si existe
      _socket?.disconnect();
      _socket?.dispose();

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );

      // Aplicar listeners que se registraron antes de conectar
      _pendingListeners.forEach((event, callback) {
        _socket!.on(event, (data) => callback(data));
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        _isConnected = true;
        _lastError = null;
        print('Socket connected');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('Socket disconnected');
      });

      _socket!.onError((error) {
        _lastError = error.toString();
        print('Socket error: $error');
      });
    } catch (e) {
      print('Error connecting to socket: $e');
      _lastError = e.toString();
      _isConnected = false;
    }
  }

  void emit(String event, [dynamic data]) {
    if (_socket != null) {
      if (data != null) {
        _socket!.emit(event, data);
      } else {
        _socket!.emit(event);
      }
      print('Emitted: $event');
    } else {
      print('Socket not initialized. Cannot emit: $event');
    }
  }

  void on(String event, Function(dynamic) callback) {
    // Guardar en pendientes siempre (para reconexiones)
    _pendingListeners[event] = callback;
    // Si el socket ya existe, registrar directamente
    if (_socket != null) {
      _socket!.on(event, (data) => callback(data));
    }
  }

  void off(String event) {
    _pendingListeners.remove(event);
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }
}
