import 'notification_event.dart';
import 'notification_module.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationModule module;
  final NotificationEvent event;
  final DateTime createdAt;
  final bool isRead;

  /// Original backend payload.
  final Map<String, dynamic>? payload;

  /// Purchase Order fields.
  final int? purchaseId;
  final String? purchaseNumber;
  final int? supplierId;
  final String? supplierName;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.module,
    required this.event,
    required this.createdAt,
    this.isRead = false,
    this.payload,
    this.purchaseId,
    this.purchaseNumber,
    this.supplierId,
    this.supplierName,
  });

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawPayload =
        json['payload'];

    final Map<String, dynamic>? payload =
        rawPayload is Map
            ? Map<String, dynamic>.from(rawPayload)
            : null;

    /*
     * Support both:
     *
     * 1. Direct backend fields
     * 2. Fields inside payload
     */

    final dynamic rawPurchaseId =
        json['purchase_id'] ??
        payload?['purchase_id'];

    final dynamic rawPurchaseNumber =
        json['purchase_number'] ??
        payload?['purchase_number'];

    final dynamic rawSupplierId =
        json['supplier_id'] ??
        payload?['supplier_id'];

    final dynamic rawSupplierName =
        json['supplier_name'] ??
        payload?['supplier_name'];

    return AppNotification(
      id: json['id']?.toString() ?? '',

      title:
          json['title']?.toString() ?? '',

      message:
          json['message']?.toString() ?? '',

      module:
          NotificationModule.fromString(
        json['module']?.toString(),
      ),

      event:
          NotificationEvent.fromString(
        json['event_type']?.toString() ??
            json['notification_type']?.toString(),
      ),

      createdAt:
          DateTime.tryParse(
                json['created_at']?.toString() ?? '',
              ) ??
              DateTime.now(),

      isRead:
          json['is_read'] == 1 ||
          json['is_read'] == true ||
          json['is_read'] == '1',

      payload: payload,

      purchaseId:
          int.tryParse(
            rawPurchaseId?.toString() ?? '',
          ),

      purchaseNumber:
          rawPurchaseNumber?.toString(),

      supplierId:
          int.tryParse(
            rawSupplierId?.toString() ?? '',
          ),

      supplierName:
          rawSupplierName?.toString(),
    );
  }

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      module: module,
      event: event,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      payload: payload,
      purchaseId: purchaseId,
      purchaseNumber: purchaseNumber,
      supplierId: supplierId,
      supplierName: supplierName,
    );
  }
}