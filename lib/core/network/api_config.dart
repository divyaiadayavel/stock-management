// =========================================================
// lib/core/network/api_config.dart
// =========================================================

class ApiConfig {
  ApiConfig._();

  // ==========================================================
  // Environment
  // ==========================================================

  /// true  -> Local Laragon server
  /// false -> Production server
  static const bool useLocalServer = false;

  // ==========================================================
  // Base URLs
  // ==========================================================

  /// Production API root.
  static const String productionBaseUrl =
      'https://catalystack.com/catalystockpd/public_html';

  /// Local Laragon API root for Flutter Windows/Desktop.
  ///
  /// Maps to:
  /// C:\laragon\www\catalystockdev\public_html
  // static const String localBaseUrl =
  //     'http://192.168.0.107/catalystockdev/public_html';

  /// Local XAMPP API through ngrok.
  static const String localBaseUrl =
      'https://nonredemptive-gyrational-pauletta.ngrok-free.dev/catalystockdev/public_html';

  /// Active API root.
  static const String baseUrl = useLocalServer
      ? localBaseUrl
      : productionBaseUrl;

  // ==========================================================
  // Auth
  // ==========================================================

  static const String staffLogin = '$baseUrl/api/auth/staff_login.php';

  static const String validateSession =
      '$baseUrl/api/auth/validate_session.php';

  static const String staffLogout = '$baseUrl/api/auth/staff_logout.php';

  static const String sendOtp = '$baseUrl/api/auth/send_otp.php';

  static const String verifyOtp = '$baseUrl/api/auth/verify_otp.php';

  static const String resetPassword = '$baseUrl/api/auth/reset_password.php';

  // ==========================================================
  // Settings
  // ==========================================================

  static const String getSettings = '$baseUrl/api/settings/get_settings.php';

  static const String saveSettings = '$baseUrl/api/settings/save_settings.php';

  static const String uploadBusinessLogo =
      '$baseUrl/api/settings/upload_logo.php';

  // ==========================================================
  // User Profile
  // ==========================================================

  static const String getUserProfile =
      '$baseUrl/api/settings/users_profile/get_user_profile.php';

  static const String saveUserProfile =
      '$baseUrl/api/settings/users_profile/save_user_profile.php';

  static const String uploadProfilePicture =
      '$baseUrl/api/settings/users_profile/upload_profile_picture.php';

  // ==========================================================
  // Settings - Customize
  // ==========================================================

  static const String productCategories =
      '$baseUrl/api/settings/categories_units/categories.php';

  static const String productUnits =
      '$baseUrl/api/settings/categories_units/units.php';

  // ==========================================================
  // Staff
  // ==========================================================

  static const String getStaff = '$baseUrl/api/staff/get_staff.php';

  static const String saveStaff = '$baseUrl/api/staff/save_staff.php';

  static const String deleteStaff = '$baseUrl/api/staff/delete_staff.php';

  static const String updateStatus = '$baseUrl/api/staff/update_status.php';

  // ==========================================================
  // Products
  // ==========================================================

  static const String getProducts = '$baseUrl/api/products/products.php';

  static const String addProduct = '$baseUrl/api/products/products.php';

  static const String updateProduct = '$baseUrl/api/products/products.php';

  static const String deleteProduct = '$baseUrl/api/products/products.php';

  static const String updateStock = '$baseUrl/api/products/products.php';

  static const String uploadImage = '$baseUrl/api/products/upload_image.php';

  // ==========================================================
  // Suppliers
  // ==========================================================

  static const String getSuppliers = '$baseUrl/api/suppliers/suppliers.php';

  static const String addSupplier = '$baseUrl/api/suppliers/suppliers.php';

  static const String updateSupplier = '$baseUrl/api/suppliers/suppliers.php';

  static const String deleteSupplier = '$baseUrl/api/suppliers/suppliers.php';

  static String get uploadSupplierImage =>
      '$baseUrl/api/suppliers/upload_image.php';

  // ==========================================================
  // Customers
  // ==========================================================

  static const String getCustomers = '$baseUrl/api/customers/customers.php';

  static const String addCustomer = '$baseUrl/api/customers/customers.php';

  static const String updateCustomer = '$baseUrl/api/customers/customers.php';

  static const String deleteCustomer = '$baseUrl/api/customers/customers.php';

  // ==========================================================
  // Sales & Invoices
  // ==========================================================

  static const String createSale = '$baseUrl/api/sales/create_sale.php';

  static const String getInvoice = '$baseUrl/api/sales/get_invoice.php';

  static const String addPayment = '$baseUrl/api/sales/add_payment.php';

  // ==========================================================
  // Inventory & Purchase Management
  // ==========================================================

  static const String inventory = '$baseUrl/api/inventory/inventory.php';

  static const String purchases = '$baseUrl/api/purchases/purchases.php';

  // ==========================================================
  // Reports
  // ==========================================================

  static const String reports = '$baseUrl/api/reports/reports.php';

  // ==========================================================
  // Dashboard
  // ==========================================================

  static const String dashboard = '$baseUrl/api/dashboard/dashboard.php';

  // ==========================================================
  // Backup
  // ==========================================================

  static const String backup = '$baseUrl/api/backup/backup.php';

  // ==========================================================
  // Printers & Hardware
  // ==========================================================

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

  // ==========================================================
  // Printed Bills
  // ==========================================================

  static const String savePrintedBill =
      '$baseUrl/api/settings/printers_hardware/save_printed_bill.php';

  static const String getPrintedBills =
      '$baseUrl/api/settings/printers_hardware/get_printed_bills.php';

  // ==========================================================
  // Notifications
  // ==========================================================

  static const String saveFcmToken =
      '$baseUrl/api/notifications/user/save_token.php';

  static const String getUserNotifications =
      '$baseUrl/api/notifications/user/get_user_notifications.php';

  static const String markNotificationRead =
      '$baseUrl/api/notifications/user/mark_read.php';

  static const String checkLowStock =
      '$baseUrl/api/notifications/stocks_notifications/check_low_stock.php';

  static const String sendTestNotification =
      '$baseUrl/api/notifications/dev/send_test_notification.php';

  static const String triggerStockStatus =
      '$baseUrl/api/notifications/stocks_notifications/stock_status_trigger.php';

  // ==========================================================
  // Service Management (Admin)
  // ==========================================================

  static const String getServiceCategories =
      '$baseUrl/api/services/admin/categories.php';

  static const String saveServiceCategory =
      '$baseUrl/api/services/admin/categories.php';

  static const String deleteServiceCategory =
      '$baseUrl/api/services/admin/categories.php';

  static const String getServices = '$baseUrl/api/services/admin/services.php';

  static const String getServiceDetail =
      '$baseUrl/api/services/admin/services.php';

  static const String saveService = '$baseUrl/api/services/admin/services.php';

  static const String deleteService =
      '$baseUrl/api/services/admin/services.php';

  // ==========================================================
  // Services (User side)
  // ==========================================================

  static const String submitServiceRequest =
      '$baseUrl/api/services/user/service_requests.php';

  static const String getServiceRequests =
      '$baseUrl/api/services/user/service_requests.php';

  static String get uploadServiceRequestFile =>
      '$baseUrl/api/services/user/upload_answer_file.php';

  // ─── SERVICE PROVIDERS (admin side) ───────────────────────
  static const String getServiceProviders =
      '$baseUrl/api/services/admin/providers.php';

  static const String getServiceProviderDetail =
      '$baseUrl/api/services/admin/providers.php';

  static const String saveServiceProvider =
      '$baseUrl/api/services/admin/providers.php';

  static const String deleteServiceProvider =
      '$baseUrl/api/services/admin/providers.php';

  static const String reloadServiceProviderBalance =
      '$baseUrl/api/services/admin/providers.php?action=reload';

  // ─── PROVIDER RELOAD / BALANCE HISTORY (Provider Reports) ─
  // NEW — standalone file, does not touch providers.php at all.
  static const String getProviderReloadLogs =
      '$baseUrl/api/services/admin/provider_reload_history.php';

  // ─── PROVIDER RECHARGES (user side) ───────────────────────
  static const String submitProviderRecharge =
      '$baseUrl/api/services/user/provider_recharges.php';

  static const String getProviderRecharges =
      '$baseUrl/api/services/user/provider_recharges.php';

  // NEW — standalone file, does not touch provider_recharges.php at all.
  static const String addProviderRechargePayment =
      '$baseUrl/api/services/user/provider_recharge_payments.php';

  // ==========================================================
  // Expenses
  // ==========================================================

  static const String expenses = '$baseUrl/api/expenses/expense.php';

  // ==========================================================
  // Headers
  // ==========================================================

  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };
}
