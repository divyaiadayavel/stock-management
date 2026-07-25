class ScannerDeviceModel {
  final String id;
  final String name;
  final String type; // e.g., 'BLUETOOTH', 'USB'
  final bool isConnected;

  const ScannerDeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isConnected': isConnected ? 1 : 0,
    };
  }

  factory ScannerDeviceModel.fromMap(Map<String, dynamic> map) {
    return ScannerDeviceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'UNKNOWN',
      isConnected: map['isConnected'] == 1,
    );
  }
}