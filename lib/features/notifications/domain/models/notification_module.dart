enum NotificationModule {
  product,
  supplier,
  customer,
  printer,
  inventory,
  purchaseOrder,
  general;

  static NotificationModule fromString(String? val) {
    if (val == null) {
      return NotificationModule.general;
    }

    switch (val.toLowerCase().trim()) {
      case 'product':
        return NotificationModule.product;

      case 'supplier':
        return NotificationModule.supplier;

      case 'customer':
        return NotificationModule.customer;

      case 'printer':
        return NotificationModule.printer;

      case 'inventory':
        return NotificationModule.inventory;

      case 'purchaseorder':
      case 'purchase_order':
      case 'purchase-order':
        return NotificationModule.purchaseOrder;

      default:
        return NotificationModule.general;
    }
  }
}