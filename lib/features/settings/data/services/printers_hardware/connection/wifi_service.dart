import 'dart:io';
import 'dart:typed_data';

class WifiService {
  Socket? _socket;
  bool _connected = false;

  Future<bool> connect(String ipAddress, int port) async {
    try {
      if (_connected) await disconnect();
      _socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 5));
      _connected = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    _socket?.destroy();
    _socket = null;
    _connected = false;
  }

  Future<bool> isConnected() async {
    return _connected && _socket != null;
  }

  Future<bool> printBytes(List<int> bytes) async {
    try {
      if (!await isConnected()) return false;
      _socket!.add(Uint8List.fromList(bytes));
      await _socket!.flush();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Legacy method kept for compatibility (but deprecated)
  @Deprecated('Use connect() + printBytes() instead')
  Future<bool> sendBytesToNetworkPrinter(String ipAddress, int port, List<int> bytes) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 5));
      socket.add(Uint8List.fromList(bytes));
      await socket.flush();
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}