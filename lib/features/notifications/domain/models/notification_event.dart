enum NotificationEvent {
  // Product / Stock Status Events
  lowStock,
  outOfStock,
  inStock,

  // Product Actions
  productAdded,
  productUpdated,
  productDeleted,

  // Supplier Actions
  supplierAdded,
  supplierUpdated,
  supplierDeleted,

  // Customer Actions
  customerAdded,
  customerUpdated,
  customerDeleted,

  // Hardware Actions
  printerConnected,
  printerDisconnected,
  printerForgot,
  printSuccess,

  // Purchase Order Actions
  purchaseOrderCreated,
  purchaseOrderPlaced,
  purchaseOrderPartiallyReceived,
  purchaseOrderPending,
  purchaseOrderReceived,

  unknown;

  static NotificationEvent fromString(String? raw) {
    if (raw == null) {
      return NotificationEvent.unknown;
    }

    switch (raw.toLowerCase().trim()) {
      // ------------------------------------------------------
      // STOCK
      // ------------------------------------------------------

      case 'low_stock_alert':
        return NotificationEvent.lowStock;

      case 'out_of_stock':
        return NotificationEvent.outOfStock;

      case 'in_stock':
        return NotificationEvent.inStock;

      // ------------------------------------------------------
      // PRODUCT
      // ------------------------------------------------------

      case 'product_added':
        return NotificationEvent.productAdded;

      case 'product_updated':
        return NotificationEvent.productUpdated;

      case 'product_deleted':
        return NotificationEvent.productDeleted;

      // ------------------------------------------------------
      // SUPPLIER
      // ------------------------------------------------------

      case 'supplier_added':
        return NotificationEvent.supplierAdded;

      case 'supplier_updated':
        return NotificationEvent.supplierUpdated;

      case 'supplier_deleted':
        return NotificationEvent.supplierDeleted;

      // ------------------------------------------------------
      // CUSTOMER
      // ------------------------------------------------------

      case 'customer_added':
        return NotificationEvent.customerAdded;

      case 'customer_updated':
        return NotificationEvent.customerUpdated;

      case 'customer_deleted':
        return NotificationEvent.customerDeleted;

      // ------------------------------------------------------
      // PRINTER
      // ------------------------------------------------------

      case 'printer_connected':
        return NotificationEvent.printerConnected;

      case 'printer_disconnected':
        return NotificationEvent.printerDisconnected;

      case 'printer_forgot':
        return NotificationEvent.printerForgot;

      case 'print_success':
        return NotificationEvent.printSuccess;

      // ------------------------------------------------------
      // PURCHASE ORDER
      // ------------------------------------------------------

      case 'purchase_order_created':
      case 'po_created':
        return NotificationEvent.purchaseOrderCreated;

      case 'purchase_order_placed':
      case 'po_sent':
        return NotificationEvent.purchaseOrderPlaced;

      case 'purchase_order_partially_received':
        return NotificationEvent.purchaseOrderPartiallyReceived;

      case 'purchase_order_pending':
        return NotificationEvent.purchaseOrderPending;

      case 'purchase_order_received':
      case 'po_received':
        return NotificationEvent.purchaseOrderReceived;

      default:
        return NotificationEvent.unknown;
    }
  }
}