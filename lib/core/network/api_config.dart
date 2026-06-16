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

  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true', // ✅ prevents ngrok HTML warning page
  };
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
}
