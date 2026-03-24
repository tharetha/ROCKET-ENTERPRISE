import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocketClient {
  static IO.Socket? _socket;
  static const String serverUrl = 'http://10.140.0.20:5000'; // Updated to machine IP

  static void init() async {
    if (_socket != null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    // We assume the user is logged in as a Merchant HQ/Branch Admin
    // The node ID would be needed if we want to join specific rooms.
    // In a production scenario, we'd join a room based on the merchant profile ID.

    _socket = IO.io(serverUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build()
    );

    _socket!.onConnect((_) {
      debugPrint('[SOCKET] Connected to Backend');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SOCKET] Disconnected from Backend');
    });

    _socket!.onConnectError((err) {
      debugPrint('[SOCKET] Connection Error: $err');
    });
  }

  static void joinRoom(String roomId) {
    if (_socket == null) return;
    _socket!.emit('join', roomId);
    debugPrint('[SOCKET] Requested to join room: $roomId');
  }

  static void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  static void off(String event) {
    _socket?.off(event);
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
