/// Generic connection state for hardware peripherals.
enum HardwareConnectionState {
  disconnected,
  connecting,
  connected,
  error;

  String get label {
    switch (this) {
      case HardwareConnectionState.disconnected:
        return 'Disconnected';
      case HardwareConnectionState.connecting:
        return 'Connecting…';
      case HardwareConnectionState.connected:
        return 'Connected';
      case HardwareConnectionState.error:
        return 'Error';
    }
  }

  bool get isConnected => this == HardwareConnectionState.connected;
}