// =========================================================
// lib/core/network/api_config.dart
// =========================================================
class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
      'https://nonredemptive-gyrational-pauletta.ngrok-free.dev/public_html';

  // ── Auth ──────────────────────────────────────────────────
  static const String staffLogin = '$baseUrl/api/auth/staff_login.php';
  static const String sendOtp = '$baseUrl/api/auth/send_otp.php';
  static const String verifyOtp = '$baseUrl/api/auth/verify_otp.php';
  static const String resetPassword = '$baseUrl/api/auth/reset_password.php';

  // ── Settings ──────────────────────────────────────────────
  static const String getSettings = '$baseUrl/api/settings/get_settings.php';
  static const String saveSettings = '$baseUrl/api/settings/save_settings.php';

  // ── Staff ─────────────────────────────────────────────────
  static const String getStaff = '$baseUrl/api/staff/get_staff.php';
  static const String saveStaff = '$baseUrl/api/staff/save_staff.php';
  static const String deleteStaff = '$baseUrl/api/staff/delete_staff.php';
  static const String updateStatus = '$baseUrl/api/staff/update_status.php';

  // ── Products ──────────────────────────────────────────────
  static const String getProducts = '$baseUrl/api/products/products.php';
  static const String addProduct = '$baseUrl/api/products/products.php';
  static const String updateProduct = '$baseUrl/api/products/products.php';
  static const String deleteProduct = '$baseUrl/api/products/products.php';
  static const String updateStock = '$baseUrl/api/products/products.php';
  static const String uploadImage = '$baseUrl/api/products/upload_image.php';

  // ── Suppliers ─────────────────────────────────────────────
  static const String getSuppliers = '$baseUrl/api/suppliers/suppliers.php';
  static const String addSupplier = '$baseUrl/api/suppliers/suppliers.php';
  static const String updateSupplier = '$baseUrl/api/suppliers/suppliers.php';
  static const String deleteSupplier = '$baseUrl/api/suppliers/suppliers.php';
  static String get uploadSupplierImage =>
      '$baseUrl/api/suppliers/upload_image.php';

  // ── Customers ─────────────────────────────────────────────
  static const String getCustomers = '$baseUrl/api/customers/customers.php';
  static const String addCustomer = '$baseUrl/api/customers/customers.php';
  static const String updateCustomer = '$baseUrl/api/customers/customers.php';
  static const String deleteCustomer = '$baseUrl/api/customers/customers.php';

  // ── Sales & Invoices ──────────────────────────────────────
  static const String createSale = '$baseUrl/api/sales/create_sale.php';
  static const String getInvoice = '$baseUrl/api/sales/get_invoice.php';

  // ── Inventory & Purchase Management Routes ────────────────
  static const String inventory = '$baseUrl/api/inventory/inventory.php';
  static const String purchases =
      '$baseUrl/api/purchases/purchases.php'; // 🟢 Added Purchases Route

  // ── Reports ────────────────────────────────────────────────
  static const String reports = '$baseUrl/api/reports/reports.php'; // ✅ Added

  // ── Dashboard ──────────────────────────────────────────────
  static const String dashboard = '$baseUrl/api/dashboard/dashboard.php';

  // ── Backup ──────────────────────────────────────────────────
  static const String getBackupStatus =
      '$baseUrl/api/backup/backup.php?action=status';
  static const String createBackup =
      '$baseUrl/api/backup/backup.php?action=create';
  static const String completeBackup =
      '$baseUrl/api/backup/backup.php?action=complete';
  static const String getBackupHistory =
      '$baseUrl/api/backup/backup.php?action=history';
  static const String restoreBackup =
      '$baseUrl/api/backup/backup.php?action=restore';
  static const String saveBackupSettings =
      '$baseUrl/api/backup/backup.php?action=saveSettings';

  // ── Printers & Hardware ───────────────────────────────────
  static const String getSavedPrinters =
      '$baseUrl/api/settings/printers_hardware/get_saved_printers.php';
  static const String saveDefaultPrinter =
      '$baseUrl/api/settings/printers_hardware/save_default_printer.php';
  static const String deletePrinter =
      '$baseUrl/api/settings/printers_hardware/delete_printer.php';
  static const String getReceiptSettings =
      '$baseUrl/api/settings/printers_hardware/get_receipt_settings.php';
  static const String saveReceiptSettings =
      '$baseUrl/api/settings/printers_hardware/save_receipt_settings.php';

  // ── Printed Bills ─────────────────────────────────────────
  static const String savePrintedBill =
      '$baseUrl/api/settings/printers_hardware/save_printed_bill.php';
  static const String getPrintedBills =
      '$baseUrl/api/settings/printers_hardware/get_printed_bills.php';

  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
}
