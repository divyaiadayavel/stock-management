class CashDrawer {
  final String id;
  final String name;
  final bool isConnected;

  const CashDrawer({
    required this.id,
    required this.name,
    this.isConnected = false,
  });

  CashDrawer copyWith({
    String? id,
    String? name,
    bool? isConnected,
  }) {
    return CashDrawer(
      id: id ?? this.id,
      name: name ?? this.name,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}