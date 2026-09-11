class Validators {
  Validators._();

  // ============================================================
  // NORMALIZATION
  // ============================================================

  /// Trims leading/trailing spaces and collapses multiple spaces.
  ///
  /// Example:
  /// "  John    Kumar  " -> "John Kumar"
  static String normalizeText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Trims and converts email to lowercase.
  ///
  /// Example:
  /// "  USER@GMAIL.COM " -> "user@gmail.com"
  static String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  /// Converts a name to title case.
  ///
  /// Examples:
  /// "john kumar" -> "John Kumar"
  /// "JOHN KUMAR" -> "John Kumar"
  /// "mary-jane" -> "Mary-Jane"
  /// "o'connor" -> "O'Connor"
  static String normalizeName(String value) {
    final input = normalizeText(value);

    if (input.isEmpty) {
      return '';
    }

    return input.split(' ').map(_capitalizeWord).join(' ');
  }

  static String _capitalizeWord(String value) {
    if (value.isEmpty) {
      return value;
    }

    if (value.contains('-')) {
      return value.split('-').map(_capitalizeSimpleWord).join('-');
    }

    if (value.contains("'")) {
      return value.split("'").map(_capitalizeSimpleWord).join("'");
    }

    return _capitalizeSimpleWord(value);
  }

  static String _capitalizeSimpleWord(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  /// Trims and converts value to uppercase.
  static String normalizeUppercase(String value) {
    return value.trim().toUpperCase();
  }

  /// Trims and converts value to lowercase.
  static String normalizeLowercase(String value) {
    return value.trim().toLowerCase();
  }

  /// Keeps only numeric digits.
  static String normalizeDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Normalizes ordinary submitted text.
  ///
  /// Do NOT use for passwords.
  static String normalizeSubmittedValue(String value) {
    return normalizeText(value);
  }

  // ============================================================
  // REQUIRED
  // ============================================================

  static String? required(String value, {String fieldName = 'This field'}) {
    if (normalizeText(value).isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  // ============================================================
  // GENERAL TEXT
  // ============================================================

  static String? validateText(
    String value, {
    required String fieldName,
    int minLength = 1,
    int? maxLength,
    bool required = true,
  }) {
    final input = normalizeText(value);

    if (input.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    if (input.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && input.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  // ============================================================
  // NAME
  // ============================================================

  static String? validateName(
    String value, {
    String fieldName = 'Name',
    int minLength = 3,
  }) {
    final input = normalizeText(value);

    if (input.isEmpty) {
      return '$fieldName is required';
    }

    if (input.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    final nameRegex = RegExp(r"^[A-Za-z]+(?:[\s'-][A-Za-z]+)*$");

    if (!nameRegex.hasMatch(input)) {
      return 'Enter a valid $fieldName';
    }

    return null;
  }

  // ============================================================
  // EMAIL
  // ============================================================

  static String? validateEmail(String value) {
    // Reject a value that is empty or only whitespace.
    if (value.trim().isEmpty) {
      return 'Email is required';
    }

    // Reject leading/trailing spaces instead of silently trimming,
    // so the user can see exactly what was wrong.
    if (value != value.trim()) {
      return 'Email must not start or end with a space';
    }

    // Only lowercase letters are allowed (no uppercase).
    if (value != value.toLowerCase()) {
      return 'Email must be in lowercase letters only';
    }

    final email = value;

    if (!email.contains('@')) {
      return 'Email must contain @ symbol';
    }

    final parts = email.split('@');

    if (parts.length != 2 || parts[0].isEmpty) {
      return 'Enter a valid email address';
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    // Spaces BETWEEN characters are allowed here; leading/trailing
    // spaces on the whole email were already rejected above.
    final localRegex = RegExp(r'^[a-z0-9._%+\- ]+$');
    if (!localRegex.hasMatch(localPart)) {
      return 'Email contains invalid characters before @';
    }

    if (domainPart.isEmpty || !domainPart.contains('.')) {
      return 'Email must contain a valid domain like example.com';
    }

    final domainRegex = RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$');
    if (!domainRegex.hasMatch(domainPart)) {
      return 'Enter a valid domain like .com, .in or .org';
    }

    return null;
  }

  /// Use when email is optional.
  static String? validateOptionalEmail(String value) {
    final email = normalizeEmail(value);

    if (email.isEmpty) {
      return null;
    }

    return validateEmail(email);
  }

  // ============================================================
  // PHONE
  // ============================================================

  /// Validates an Indian 10-digit mobile number.
  static String? validatePhone(
    String value, {
    String fieldName = 'Phone number',
  }) {
    final phone = normalizeDigits(value);

    if (phone.isEmpty) {
      return '$fieldName is required';
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit $fieldName';
    }

    return null;
  }

  /// Use when phone is optional.
  static String? validateOptionalPhone(
    String value, {
    String fieldName = 'Phone number',
  }) {
    final phone = normalizeDigits(value);

    if (phone.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit $fieldName';
    }

    return null;
  }

  // ============================================================
  // GSTIN
  // ============================================================

  static String? validateGstin(String value) {
    final gstin = normalizeUppercase(value);

    if (gstin.isEmpty) {
      return null;
    }

    final gstinRegex = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
    );

    if (!gstinRegex.hasMatch(gstin)) {
      return 'Enter a valid GSTIN';
    }

    return null;
  }

  // ============================================================
  // PAN
  // ============================================================

  static String? validatePan(String value) {
    final pan = normalizeUppercase(value);

    if (pan.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
      return 'Enter a valid PAN';
    }

    return null;
  }

  // ============================================================
  // INDIAN PIN CODE
  // ============================================================

  static String? validateIndianPin(String value) {
    final pin = normalizeDigits(value);

    if (pin.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(pin)) {
      return 'Enter a valid 6-digit PIN code';
    }

    return null;
  }

  // ============================================================
  // HSN
  // ============================================================

  static String? validateHsn(String value) {
    final hsn = normalizeDigits(value);

    if (hsn.isEmpty) {
      return null;
    }

    if (hsn.length != 4 && hsn.length != 6 && hsn.length != 8) {
      return 'HSN must contain 4, 6, or 8 digits';
    }

    return null;
  }

  // ============================================================
  // PRODUCT CODE
  // ============================================================

  static String? validateProductCode(String value) {
    final code = normalizeText(value);

    if (code.isEmpty) {
      return null;
    }

    if (code.length > 100) {
      return 'Product code must not exceed 100 characters';
    }

    if (!RegExp(r'^[A-Za-z0-9._\-/]+$').hasMatch(code)) {
      return 'Enter a valid product code';
    }

    return null;
  }
// ============================================================
// PRODUCT NAME
// ============================================================

/// Validates a product name.
///
/// Product names may contain:
/// - Letters
/// - Numbers
/// - Spaces
/// - Hyphens
/// - Apostrophes
/// - Common product-name symbols such as &, /, ., (, )
///
/// Examples:
/// "Basmati Rice Bag 7kg" -> valid
/// "Rice 25kg" -> valid
/// "T-Shirt 2XL" -> valid
/// "Oil 1.5L" -> valid
/// "A4 Paper - 500 Sheets" -> valid
static String? validateProductName(
  String value, {
  String fieldName = 'Product name',
  int minLength = 3,
  int maxLength = 150,
}) {
  final input = normalizeText(value);

  if (input.isEmpty) {
    return '$fieldName is required';
  }

  if (input.length < minLength) {
    return '$fieldName must be at least $minLength characters';
  }

  if (input.length > maxLength) {
    return '$fieldName must not exceed $maxLength characters';
  }

  // Product names are intentionally more flexible than
  // person names. Numbers and common product characters
  // are allowed.
  final productNameRegex = RegExp(
    r"^[A-Za-z0-9][A-Za-z0-9\s'&().,/_+\-]*$",
  );

  if (!productNameRegex.hasMatch(input)) {
    return 'Enter a valid $fieldName';
  }

  return null;
}
  // ============================================================
  // BARCODE
  // ============================================================

  static String? validateBarcode(String value) {
    final barcode = normalizeDigits(value);

    if (barcode.isEmpty) {
      return null;
    }

    if (barcode.length < 8 || barcode.length > 14) {
      return 'Barcode must contain 8 to 14 digits';
    }

    return null;
  }

  // ============================================================
  // REQUIRED INTEGER
  // ============================================================

  static String? validateRequiredInteger(
    String value, {
    String fieldName = 'Value',
    int min = 0,
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return '$fieldName is required';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(input)) {
      return '$fieldName must be a whole number';
    }

    final number = int.tryParse(input);

    if (number == null) {
      return 'Enter a valid $fieldName';
    }

    if (number < min) {
      return '$fieldName must be at least $min';
    }

    return null;
  }

  // ============================================================
  // OPTIONAL INTEGER
  // ============================================================

  static String? validateOptionalInteger(
    String value, {
    String fieldName = 'Value',
    int min = 0,
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(input)) {
      return '$fieldName must be a whole number';
    }

    final number = int.tryParse(input);

    if (number == null) {
      return 'Enter a valid $fieldName';
    }

    if (number < min) {
      return '$fieldName must be at least $min';
    }

    return null;
  }

  // ============================================================
  // REQUIRED DECIMAL / MONEY
  // ============================================================

  static String? validateRequiredDecimal(
    String value, {
    String fieldName = 'Amount',
    double min = 0,
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(input);

    if (number == null || !number.isFinite) {
      return 'Enter a valid $fieldName';
    }

    if (number < min) {
      return '$fieldName must be at least $min';
    }

    return null;
  }

  // ============================================================
  // OPTIONAL DECIMAL / MONEY
  // ============================================================

  static String? validateOptionalDecimal(
    String value, {
    String fieldName = 'Amount',
    double min = 0,
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return null;
    }

    final number = double.tryParse(input);

    if (number == null || !number.isFinite) {
      return 'Enter a valid $fieldName';
    }

    if (number < min) {
      return '$fieldName must be at least $min';
    }

    return null;
  }

  // ============================================================
  // PERCENTAGE
  // ============================================================

  static String? validatePercentage(
    String value, {
    String fieldName = 'Percentage',
    bool required = false,
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    final number = double.tryParse(input);

    if (number == null || !number.isFinite) {
      return 'Enter a valid $fieldName';
    }

    if (number < 0 || number > 100) {
      return '$fieldName must be between 0 and 100';
    }

    return null;
  }

  // ============================================================
  // LOGIN PASSWORD
  // ============================================================

  /// Login validation.
  ///
  /// Existing users may have passwords created before the
  /// strong-password policy was introduced, so login only checks
  /// that the password exists and meets the minimum length.
  ///
  /// IMPORTANT:
  /// Password is NOT trimmed or modified.
  static String? validateLoginPassword(String value) {
    if (value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // ============================================================
  // STRONG PASSWORD
  // ============================================================

  /// Strong password requirements:
  ///
  /// - Minimum 8 characters
  /// - At least 1 uppercase letter
  /// - At least 1 lowercase letter
  /// - At least 1 number
  /// - At least 1 special character
  ///
  /// Password is intentionally NOT trimmed or modified.
  static String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least 1 uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least 1 lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least 1 number';
    }

    if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\\/\[\]+=;`~]''').hasMatch(value)) {
      return 'Password must contain at least 1 special character';
    }

    return null;
  }

  // ============================================================
  // STRONG PASSWORD (min 6, used across Login / Register / Reset)
  // ============================================================

  /// Strong password requirements used on the input fields:
  ///
  /// - Minimum 6 characters (no fixed upper limit — the user may set
  ///   a longer password)
  /// - At least 1 uppercase letter
  /// - At least 1 number
  /// - At least 1 special character (symbol)
  /// - No leading/trailing spaces (a space in the middle IS allowed),
  ///   and not empty/whitespace-only
  ///
  /// Returns the FIRST rule that fails so only one error shows at a time.
  static String? validateStrongPassword(
    String value, {
    int minLength = 6,
    int? maxLength,
  }) {
    if (value.trim().isEmpty) {
      return 'Password is required';
    }

    // Only leading/trailing spaces are rejected — a space in the
    // middle of the password is allowed.
    if (value != value.trim()) {
      return 'Password must not start or end with a space';
    }

    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return 'Password must not exceed $maxLength characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least 1 capital letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least 1 number';
    }

    if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\\/\[\]+=;`~]''').hasMatch(value)) {
      return 'Password must contain at least 1 symbol';
    }

    return null;
  }

  // ============================================================
  // REGISTER PASSWORD
  // ============================================================

  static String? validateRegisterPassword(String value) {
    return validatePassword(value);
  }

  // ============================================================
  // CONFIRM PASSWORD
  // ============================================================

  static String? validateConfirmPassword(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.trim().isEmpty) {
      return 'Confirm password is required';
    }

    if (confirmPassword != confirmPassword.trim()) {
      return 'Password must not start or end with a space';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ============================================================
  // OTP
  // ============================================================

  static String? validateOtp(String value) {
    final otp = value.trim();

    if (otp.isEmpty) {
      return 'OTP is required';
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      return 'OTP must be 6 digits';
    }

    return null;
  }

  // ============================================================
  // MINIMUM LENGTH
  // ============================================================

  static String? validateMinLength(
    String value, {
    required int min,
    String fieldName = 'Value',
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return '$fieldName is required';
    }

    if (input.length < min) {
      return '$fieldName must be at least $min characters';
    }

    return null;
  }

  // ============================================================
  // MAXIMUM LENGTH
  // ============================================================

  static String? validateMaxLength(
    String value, {
    required int max,
    String fieldName = 'Value',
  }) {
    if (value.trim().length > max) {
      return '$fieldName must not exceed $max characters';
    }

    return null;
  }

  // ============================================================
  // ALPHANUMERIC
  // ============================================================

  static String? validateAlphanumeric(
    String value, {
    String fieldName = 'Value',
    bool required = false,
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(input)) {
      return '$fieldName can contain only letters and numbers';
    }

    return null;
  }

  // ============================================================
  // INVOICE PREFIX
  // ============================================================

  static String? validateInvoicePrefix(String value) {
    final prefix = normalizeUppercase(value);

    if (prefix.isEmpty) {
      return 'Invoice prefix is required';
    }

    if (prefix.length > 20) {
      return 'Invoice prefix must not exceed 20 characters';
    }

    if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(prefix)) {
      return 'Invoice prefix contains invalid characters';
    }

    return null;
  }

  // ============================================================
  // INVOICE NUMBER - FORMAT ONLY
  // ============================================================

  static String? validateInvoiceNumber(String value) {
    final input = value.trim();

    if (input.isEmpty) {
      return 'Invoice number is required';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(input)) {
      return 'Invoice number must be a whole number';
    }

    final number = int.tryParse(input);

    if (number == null || number < 1) {
      return 'Invoice number must be greater than 0';
    }

    return null;
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  static String? validateAddress(String value, {bool required = false}) {
    final address = normalizeText(value);

    if (address.isEmpty) {
      return required ? 'Address is required' : null;
    }

    if (address.length < 5) {
      return 'Enter a valid address';
    }

    return null;
  }

  // ============================================================
  // CITY / STATE / COUNTRY
  // ============================================================

  static String? validateLocationName(
    String value, {
    String fieldName = 'Location',
    bool required = false,
  }) {
    final input = normalizeText(value);

    if (input.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    if (input.length < 2) {
      return 'Enter a valid $fieldName';
    }

    if (!RegExp(r"^[A-Za-z]+(?:[\s'-][A-Za-z]+)*$").hasMatch(input)) {
      return 'Enter a valid $fieldName';
    }

    return null;
  }

  // ============================================================
  // POSITIVE INTEGER
  // ============================================================

  static String? validatePositiveInteger(
    String value, {
    String fieldName = 'Value',
  }) {
    return validateRequiredInteger(value, fieldName: fieldName, min: 1);
  }

  // ============================================================
  // POSITIVE DECIMAL
  // ============================================================

  static String? validatePositiveDecimal(
    String value, {
    String fieldName = 'Amount',
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(input);

    if (number == null || !number.isFinite) {
      return 'Enter a valid $fieldName';
    }

    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

static String? validateFutureDate(
  String value, {
  String fieldName = 'Date',
}) {
  final trimmed = value.trim();

  // Optional field.
  if (trimmed.isEmpty) {
    return null;
  }

  try {
    final parts = trimmed.split('/');

    if (parts.length != 3) {
      return '$fieldName is invalid';
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return '$fieldName is invalid';
    }

    final selectedDate = DateTime(year, month, day);

    // Prevent DateTime from silently normalizing
    // invalid dates such as 31/02/2026.
    if (selectedDate.year != year ||
        selectedDate.month != month ||
        selectedDate.day != day) {
      return '$fieldName is invalid';
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Expiry date can be TODAY or any future date.
    // Only dates before today are invalid.
    if (selectedDate.isBefore(today)) {
      return '$fieldName cannot be before today';
    }

    return null;
  } catch (_) {
    return '$fieldName is invalid';
  }
}
  // ============================================================
  // CUSTOMER MONEY / DECIMAL
  // ============================================================

  /// Validates a non-negative monetary value with maximum 2 decimals.
  ///
  /// Examples:
  /// "100"     -> valid
  /// "100.5"   -> valid
  /// "100.50"  -> valid
  /// "100.555" -> invalid
  /// "-100"    -> invalid
  /// "abc"     -> invalid
  static String? validateCustomerAmount(
    String value, {
    String fieldName = 'Amount',
    bool required = false,
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(input)) {
      return '$fieldName must be a valid amount with maximum 2 decimal places';
    }

    final number = double.tryParse(input);

    if (number == null || !number.isFinite) {
      return 'Enter a valid $fieldName';
    }

    if (number < 0) {
      return '$fieldName must be at least 0';
    }

    return null;
  }
}
