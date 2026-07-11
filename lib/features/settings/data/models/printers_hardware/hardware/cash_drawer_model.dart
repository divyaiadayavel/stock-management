class CashDrawerModel {
  final String id;
  final String name;
  final bool isConnected;

  const CashDrawerModel({
    required this.id,
    required this.name,
    this.isConnected = false,
  });

  CashDrawerModel copyWith({
    String? id,
    String? name,
    bool? isConnected,
  }) {
    return CashDrawerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isConnected': isConnected ? 1 : 0,
    };
  }

  factory CashDrawerModel.fromMap(Map<String, dynamic> map) {
    return CashDrawerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isConnected: map['isConnected'] == 1,
    );
  }
}