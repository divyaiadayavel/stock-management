class PrintHistoryEntry {
  final String id;
  final String billReference;
  final String? printerId;
  final String? printerName;
  final DateTime? printedAt;
  final DateTime createdAt;
  final int itemCount;
  final double grandTotal;
  final bool isSuccess;
  final String? errorMessage;

  const PrintHistoryEntry({
    required this.id,
    required this.billReference,
    this.printerId,
    this.printerName,
    this.printedAt,
    required this.createdAt,
    this.itemCount = 0,
    this.grandTotal = 0,
    required this.isSuccess,
    this.errorMessage,
  });

  String get printStatus => isSuccess ? 'Success' : 'Failed';

  PrintHistoryEntry copyWith({
    String? id,
    String? billReference,
    String? printerId,
    String? printerName,
    DateTime? printedAt,
    DateTime? createdAt,
    int? itemCount,
    double? grandTotal,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return PrintHistoryEntry(
      id: id ?? this.id,
      billReference: billReference ?? this.billReference,
      printerId: printerId ?? this.printerId,
      printerName: printerName ?? this.printerName,
      printedAt: printedAt ?? this.printedAt,
      createdAt: createdAt ?? this.createdAt,
      itemCount: itemCount ?? this.itemCount,
      grandTotal: grandTotal ?? this.grandTotal,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
