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
  static const String staffLogin    = '$baseUrl/api/auth/staff_login.php';
  static const String sendOtp       = '$baseUrl/api/auth/send_otp.php';
  static const String verifyOtp     = '$baseUrl/api/auth/verify_otp.php';
  static const String resetPassword = '$baseUrl/api/auth/reset_password.php';
 
  // ── Settings ──────────────────────────────────────────────
  static const String getSettings  = '$baseUrl/api/settings/get_settings.php';
  static const String saveSettings = '$baseUrl/api/settings/save_settings.php';
 
  // ── Staff ─────────────────────────────────────────────────
  static const String getStaff     = '$baseUrl/api/staff/get_staff.php';
  static const String saveStaff    = '$baseUrl/api/staff/save_staff.php';
  static const String deleteStaff  = '$baseUrl/api/staff/delete_staff.php';
  static const String updateStatus = '$baseUrl/api/staff/update_status.php';
 

// ── Products (Consolidated CRUD Route) ────────────────────
  static const String getProducts    = '$baseUrl/api/products/products.php';
  static const String addProduct     = '$baseUrl/api/products/products.php';
  static const String updateProduct  = '$baseUrl/api/products/products.php';
  static const String deleteProduct  = '$baseUrl/api/products/products.php'; 
  static const String updateStock    = '$baseUrl/api/products/products.php';
  
  // Keep image upload separate as planned
  static const String uploadImage    = '$baseUrl/api/products/upload_image.php';

// ── Suppliers (Consolidated CRUD Route) ───────────────────
  static const String getSuppliers       = '$baseUrl/api/suppliers/suppliers.php';
  static const String addSupplier        = '$baseUrl/api/suppliers/suppliers.php';
  static const String updateSupplier     = '$baseUrl/api/suppliers/suppliers.php';
  static const String deleteSupplier     = '$baseUrl/api/suppliers/suppliers.php';
  
  // Dedicated Image Upload Route for Suppliers
 static String get uploadSupplierImage => '$baseUrl/api/suppliers/upload_image.php';

 // 🟢 CUSTOMERS ENDPOINT ROUTES
static const String getCustomers = '$baseUrl/api/customers/customers.php';
  static const String addCustomer = '$baseUrl/api/customers/customers.php';
  static const String updateCustomer = '$baseUrl/api/customers/customers.php';
  static const String deleteCustomer = '$baseUrl/api/customers/customers.php';
 
  // ── Sales & Invoices ──────────────────────────────────────
static const String createSale = "$baseUrl/api/sales/create_sale.php";
static const String getInvoice = "$baseUrl/api/sales/get_invoice.php";

static const String inventory = "$baseUrl/api/inventory/inventory.php";
 
  // ── Printers & Hardware ───────────────────────────────────
  static const String getSavedPrinters    = '$baseUrl/api/settings/printers_hardware/get_saved_printers.php';
  static const String saveDefaultPrinter  = '$baseUrl/api/settings/printers_hardware/save_default_printer.php';
  static const String deletePrinter       = '$baseUrl/api/settings/printers_hardware/delete_printer.php';
  static const String getReceiptSettings  = '$baseUrl/api/settings/printers_hardware/get_receipt_settings.php';
  static const String saveReceiptSettings = '$baseUrl/api/settings/printers_hardware/save_receipt_settings.php';
 
  // ── Printed Bills (backup) ────────────────────────────────
  // Dedicated MySQL table (printed_bills) — every print attempt,
  // success or failure, is recorded here. Not on-device SQLite.
  static const String savePrintedBill = '$baseUrl/api/settings/printers_hardware/save_printed_bill.php';
  static const String getPrintedBills = '$baseUrl/api/settings/printers_hardware/get_printed_bills.php';
 
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true', // ✅ prevents ngrok HTML warning page
  };
}
 