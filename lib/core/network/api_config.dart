// class ApiConfig {
//   const ApiConfig._();

//   static const String baseUrl =
//       'https://nonredemptive-gyrational-pauletta.ngrok-free.dev/public_html';

//   static const Map<String, String> jsonHeaders = {
//     'Accept': 'application/json',
//     'Content-Type': 'application/json',
//     'ngrok-skip-browser-warning': 'true',
//   };
// }
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
  static const String getProducts = '$baseUrl/api/products/get_products.php';
  static const String addProduct = '$baseUrl/api/products/add_product.php';
  static const String updateProduct =
      '$baseUrl/api/products/update_product.php';
  static const String deleteProduct =
      '$baseUrl/api/products/delete_product.php';
  static const String updateStock = '$baseUrl/api/products/update_stock.php';

  // ── Suppliers ─────────────────────────────────────────────
  static const String getSuppliers = '$baseUrl/api/suppliers/get_suppliers.php';
  static const String addSupplier = '$baseUrl/api/suppliers/add_supplier.php';
  static const String updateSupplier =
      '$baseUrl/api/suppliers/update_supplier.php';
  static const String deleteSupplier =
      '$baseUrl/api/suppliers/delete_supplier.php';

  // ── Sales & Invoices ──────────────────────────────────────
  static const String createInvoice = '$baseUrl/api/sales/create_invoice.php';
  static const String getSalesStats = '$baseUrl/api/sales/get_sales_stats.php';

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

  // 🔹 ADD THESE BACKUP & SYNC STRING ENDPOINTS
  static const String getBackupStatus = "$baseUrl/api/backup/status";
  static const String saveBackupStatus = "$baseUrl/api/backup/status/save";
  static const String getBackupHistory = "$baseUrl/api/backup/history";
  static const String recordBackupEvent = "$baseUrl/api/backup/event/record";

  // ── Printed Bills (backup) ────────────────────────────────
  // Dedicated MySQL table (printed_bills) — every print attempt,
  // success or failure, is recorded here. Not on-device SQLite.
  static const String savePrintedBill =
      '$baseUrl/api/settings/printers_hardware/save_printed_bill.php';
  static const String getPrintedBills =
      '$baseUrl/api/settings/printers_hardware/get_printed_bills.php';

  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true', // ✅ prevents ngrok HTML warning page
  };
}
