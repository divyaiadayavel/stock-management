class ScannerDevice {
  final String id;
  final String name;
  final String type;
  final bool isConnected;

  const ScannerDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
  });

  ScannerDevice copyWith({
    String? id,
    String? name,
    String? type,
    bool? isConnected,
  }) {
    return ScannerDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}