import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../data/models/customer_model.dart';
import '../provider/customer_provider.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  /// When true, on a successful save this screen pops with the newly
  /// created [CustomerModel] (including its server-assigned id) instead
  /// of the default `true`.
  ///
  /// Used by the Payment screen's "Add new customer" shortcut so the
  /// customer that was just created can be auto-selected back on the
  /// Payment screen. Defaults to `false` so every existing caller
  /// (e.g. the Customers screen) keeps behaving exactly as before.
  final bool returnCreatedCustomer;

  const AddCustomerScreen({
    super.key,
    this.returnCreatedCustomer = false,
  });

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final openBalanceCtrl = TextEditingController(text: "0");

  final Map<String, String?> _errors = {};

  bool _isSaving = false;

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  void _setError(String field, String? error) {
    if (!mounted) return;

    setState(() {
      _errors[field] = error;
    });
  }

  String? _getError(String field) {
    return _errors[field];
  }

  // ============================================================
  // FIELD VALIDATION
  // ============================================================

  String? _validateField(String field, String value) {
    switch (field) {
      case 'name':
        return Validators.validateName(
          value,
          fieldName: 'Customer name',
          minLength: 3,
        );

      case 'phone':
        return Validators.validatePhone(
          value,
          fieldName: 'Phone number',
        );

      case 'alternatePhone':
        return Validators.validateOptionalPhone(
          value,
          fieldName: 'Alternate phone number',
        );

      case 'email':
        return Validators.validateOptionalEmail(value);

      case 'gst':
        return Validators.validateGstin(value);

      case 'address':
        final addressError = Validators.validateAddress(
          value,
          required: false,
        );

        if (addressError != null) {
          return addressError;
        }

        return Validators.validateMaxLength(
          value,
          max: 500,
          fieldName: 'Address',
        );

      case 'openingBalance':
        return Validators.validateCustomerAmount(
          value,
          fieldName: 'Opening balance',
          required: true,
        );

      default:
        return null;
    }
  }

  void _validateOnChange(String field, String value) {
    final error = _validateField(field, value);
    _setError(field, error);
  }

  bool _validateAllFields() {
    final validationResults = <String, String?>{
      'name': _validateField('name', nameCtrl.text),
      'phone': _validateField('phone', phoneCtrl.text),
      'alternatePhone': _validateField(
        'alternatePhone',
        altPhoneCtrl.text,
      ),
      'email': _validateField(
        'email',
        emailCtrl.text,
      ),
      'gst': _validateField(
        'gst',
        gstCtrl.text,
      ),
      'address': _validateField(
        'address',
        addressCtrl.text,
      ),
      'openingBalance': _validateField(
        'openingBalance',
        openBalanceCtrl.text,
      ),
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(validationResults);
    });

    return validationResults.values.every(
      (error) => error == null,
    );
  }

  // ============================================================
  // DUPLICATE VALIDATION
  // ============================================================

  Future<String?> _checkDuplicatePhone() async {
    final phone = Validators.normalizeDigits(phoneCtrl.text);

    if (phone.isEmpty) {
      return null;
    }

    try {
      final customers = await ref.read(allCustomersProvider.future);

      final duplicate = customers.any(
        (customer) =>
            Validators.normalizeDigits(customer.phone) == phone,
      );

      if (duplicate) {
        return 'This phone number is already registered to another customer.';
      }
    } catch (_) {
      // Backend remains the final duplicate validation authority.
    }

    return null;
  }

  Future<String?> _checkDuplicateAlternatePhone() async {
    final alternatePhone = Validators.normalizeDigits(
      altPhoneCtrl.text,
    );

    if (alternatePhone.isEmpty) {
      return null;
    }

    final primaryPhone = Validators.normalizeDigits(
      phoneCtrl.text,
    );

    if (alternatePhone == primaryPhone) {
      return 'Alternate phone number must be different from the primary phone number.';
    }

    try {
      final customers = await ref.read(allCustomersProvider.future);

      final duplicate = customers.any(
        (customer) {
          final existingPhone = Validators.normalizeDigits(
            customer.phone,
          );

          final existingAlternate = Validators.normalizeDigits(
            customer.alternatePhone,
          );

          return existingPhone == alternatePhone ||
              existingAlternate == alternatePhone;
        },
      );

      if (duplicate) {
        return 'This alternate phone number is already registered to another customer.';
      }
    } catch (_) {
      // Backend remains final authority.
    }

    return null;
  }

  Future<String?> _checkDuplicateEmail() async {
    final email = Validators.normalizeEmail(
      emailCtrl.text,
    );

    if (email.isEmpty) {
      return null;
    }

    try {
      final customers = await ref.read(allCustomersProvider.future);

      final duplicate = customers.any(
        (customer) =>
            Validators.normalizeEmail(customer.email) == email,
      );

      if (duplicate) {
        return 'This email address is already registered to another customer.';
      }
    } catch (_) {
      // Backend remains final authority.
    }

    return null;
  }

  // ============================================================
  // NORMALIZATION
  // ============================================================

  void _normalizeControllers() {
    final normalizedName = Validators.normalizeName(
      nameCtrl.text,
    );

    final normalizedPhone = Validators.normalizeDigits(
      phoneCtrl.text,
    );

    final normalizedAlternatePhone =
        Validators.normalizeDigits(
      altPhoneCtrl.text,
    );

    final normalizedEmail = Validators.normalizeEmail(
      emailCtrl.text,
    );

    final normalizedGst = Validators.normalizeUppercase(
      gstCtrl.text,
    );

    final normalizedAddress = Validators.normalizeText(
      addressCtrl.text,
    );

    final normalizedBalance = openBalanceCtrl.text.trim();

    nameCtrl.text = normalizedName;
    phoneCtrl.text = normalizedPhone;
    altPhoneCtrl.text = normalizedAlternatePhone;
    emailCtrl.text = normalizedEmail;
    gstCtrl.text = normalizedGst;
    addressCtrl.text = normalizedAddress;
    openBalanceCtrl.text = normalizedBalance;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_validateAllFields()) {
      return;
    }

    // ----------------------------------------------------------
    // Duplicate phone
    // ----------------------------------------------------------

    final duplicatePhone = await _checkDuplicatePhone();

    if (duplicatePhone != null) {
      _setError('phone', duplicatePhone);
      return;
    }

    // ----------------------------------------------------------
    // Duplicate alternate phone
    // ----------------------------------------------------------

    final duplicateAlternatePhone =
        await _checkDuplicateAlternatePhone();

    if (duplicateAlternatePhone != null) {
      _setError(
        'alternatePhone',
        duplicateAlternatePhone,
      );
      return;
    }

    // ----------------------------------------------------------
    // Duplicate email
    // ----------------------------------------------------------

    final duplicateEmail = await _checkDuplicateEmail();

    if (duplicateEmail != null) {
      _setError('email', duplicateEmail);
      return;
    }

    // ----------------------------------------------------------
    // Normalize values only after validation
    // ----------------------------------------------------------

    _normalizeControllers();

    final openingBalance =
        double.tryParse(openBalanceCtrl.text.trim());

    if (openingBalance == null) {
      _setError(
        'openingBalance',
        'Enter a valid Opening balance',
      );
      return;
    }

    final customerData = CustomerModel(
      customerCode: "",
      customerName: Validators.normalizeName(
        nameCtrl.text,
      ),
      phone: Validators.normalizeDigits(
        phoneCtrl.text,
      ),
      alternatePhone: Validators.normalizeDigits(
        altPhoneCtrl.text,
      ),
      email: Validators.normalizeEmail(
        emailCtrl.text,
      ),
      gstNumber: Validators.normalizeUppercase(
        gstCtrl.text,
      ),
      address: Validators.normalizeText(
        addressCtrl.text,
      ),
      city: "",
      state: "",
      country: "",
      postalCode: "",
      openingBalance: openingBalance,
      currentBalance: openingBalance,
      loyaltyPoints: 0,
      notes: "",
      status: "ACTIVE",
    );

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.returnCreatedCustomer) {
        // Payment-screen flow: return the created customer object
        // (with its new id) so the caller can auto-select it.
        final createdCustomer = await ref
            .read(customerOperationsProvider.notifier)
            .addCustomerAndReturn(customerData);

        if (!mounted) return;

        if (createdCustomer != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Customer profile created successfully.",
              ),
            ),
          );

          Navigator.pop(context, createdCustomer);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Unable to create customer. Please check the entered details.",
              ),
            ),
          );
        }

        return;
      }

      final success = await ref
          .read(customerOperationsProvider.notifier)
          .addCustomer(customerData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Customer profile created successfully.",
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Unable to create customer. Please check the entered details.",
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    altPhoneCtrl.dispose();
    emailCtrl.dispose();
    gstCtrl.dispose();
    addressCtrl.dispose();
    openBalanceCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(
            R.sp(context, AppSpacing.xs + 2),
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(
              R.radius(
                context,
                AppSizes.radiusSm + 4,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: R.icon(
              context,
              AppSizes.iconSm,
            ),
            color: AppColors.primary,
          ),
        ),
        SizedBox(
          width: R.sp(
            context,
            AppSpacing.sm + 2,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: R.fs(context, 13),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: R.sp(
          context,
          AppSpacing.lg,
        ),
      ),
      padding: EdgeInsets.all(
        R.sp(
          context,
          AppSpacing.cardPadding,
        ),
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(
            context,
            AppSizes.radiusLg,
          ),
        ),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, icon),
          SizedBox(
            height: R.sp(
              context,
              AppSpacing.md,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _gapV([
    double size = AppSpacing.md,
  ]) {
    return SizedBox(
      height: R.sp(context, size),
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _field({
    required String fieldKey,
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool required = false,
    TextInputType keyboard =
        TextInputType.text,
    int maxLines = 1,
  }) {
    final error = _getError(fieldKey);
    final hasError = error != null;

    final borderColor = hasError
        ? AppColors.red
        : AppColors.border;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: R.fs(context, 12),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark
                  .withValues(alpha: 0.8),
            ),
            children: required
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(
                        color: AppColors.red,
                      ),
                    ),
                  ]
                : [],
          ),
        ),

        SizedBox(
          height: R.sp(
            context,
            AppSpacing.xs + 2,
          ),
        ),

        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,

          onChanged: (value) {
            _validateOnChange(
              fieldKey,
              value,
            );
          },

          style: TextStyle(
            fontSize: R.fs(context, 14),
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w500,
          ),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: TextStyle(
              fontSize: R.fs(context, 13),
              color: AppColors.textSecondary
                  .withValues(alpha: 0.7),
            ),

            prefixIcon: Icon(
              icon,
              size: R.icon(
                context,
                AppSizes.iconSm + 2,
              ),
              color: hasError
                  ? AppColors.red
                  : AppColors.textSecondary,
            ),

            filled: true,
            fillColor: AppColors.card,

            contentPadding:
                EdgeInsets.symmetric(
              horizontal: R.sp(
                context,
                AppSpacing.md + 2,
              ),
              vertical: R.sp(
                context,
                AppSpacing.md,
              ),
            ),

            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                R.radius(
                  context,
                  AppSizes.radiusMd,
                ),
              ),
              borderSide: BorderSide(
                color: borderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                R.radius(
                  context,
                  AppSizes.radiusMd,
                ),
              ),
              borderSide: BorderSide(
                color: borderColor,
                width: hasError ? 1.5 : 1,
              ),
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                R.radius(
                  context,
                  AppSizes.radiusMd,
                ),
              ),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.red
                    : AppColors.primary,
                width: 1.5,
              ),
            ),

            errorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                R.radius(
                  context,
                  AppSizes.radiusMd,
                ),
              ),
              borderSide: const BorderSide(
                color: AppColors.red,
                width: 1.5,
              ),
            ),

            focusedErrorBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                R.radius(
                  context,
                  AppSizes.radiusMd,
                ),
              ),
              borderSide: const BorderSide(
                color: AppColors.red,
                width: 1.5,
              ),
            ),

            errorText: error,

            errorStyle: TextStyle(
              color: AppColors.red,
              fontSize: R.fs(context, 11),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: R
                  .hPad(
                    context,
                    base: AppSpacing.screenPadding,
                  )
                  .copyWith(
                    top: R.sp(
                      context,
                      AppSpacing.lg,
                    ),
                    bottom: R.sp(
                      context,
                      AppSpacing.md,
                    ),
                  ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.pop(
                              context,
                            ),
                    icon: Icon(
                      Icons.arrow_back,
                      color:
                          AppColors.textPrimaryDark,
                      size: R.icon(
                        context,
                        22,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: R.sp(
                      context,
                      AppSpacing.sm,
                    ),
                  ),

                  Expanded(
                    child: Text(
                      "Add Customer",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: AppColors
                            .textPrimaryDark,
                        fontSize:
                            R.fs(context, 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: R
                    .hPad(
                      context,
                      base: AppSpacing.screenPadding,
                    )
                    .copyWith(
                      bottom: R.sp(
                        context,
                        AppSpacing.lg,
                      ),
                    ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // PERSONAL DETAILS
                    // ==================================================

                    _sectionCard(
                      title: "Personal Details",
                      icon:
                          Icons.person_rounded,
                      children: [
                        _field(
                          fieldKey: 'name',
                          label:
                              "Customer Name",
                          hint: "Enter name",
                          icon:
                              Icons.person_outline,
                          controller: nameCtrl,
                          required: true,
                        ),

                        _gapV(
                          AppSpacing.md + 2,
                        ),

                        _field(
                          fieldKey: 'phone',
                          label:
                              "Contact Number",
                          hint: "98xxxxxx21",
                          icon:
                              Icons.phone_outlined,
                          controller: phoneCtrl,
                          required: true,
                          keyboard:
                              TextInputType.phone,
                        ),

                        _gapV(
                          AppSpacing.md + 2,
                        ),

                        _field(
                          fieldKey:
                              'alternatePhone',
                          label:
                              "Alternate Phone",
                          hint:
                              "Enter secondary contact number",
                          icon: Icons
                              .phone_android_outlined,
                          controller:
                              altPhoneCtrl,
                          keyboard:
                              TextInputType.phone,
                        ),

                        _gapV(
                          AppSpacing.md + 2,
                        ),

                        _field(
                          fieldKey: 'email',
                          label:
                              "Email Address",
                          hint:
                              "example@mail.com",
                          icon:
                              Icons.email_outlined,
                          controller: emailCtrl,
                          keyboard:
                              TextInputType
                                  .emailAddress,
                        ),
                      ],
                    ),

                    // ==================================================
                    // BUSINESS & FINANCIAL
                    // ==================================================

                    _sectionCard(
                      title:
                          "Business & Financial",
                      icon: Icons
                          .account_balance_wallet_rounded,
                      children: [
                        _field(
                          fieldKey: 'gst',
                          label:
                              "GST Number",
                          hint:
                              "Enter valid GSTIN",
                          icon: Icons
                              .receipt_long_outlined,
                          controller: gstCtrl,
                        ),

                        _gapV(
                          AppSpacing.md + 2,
                        ),

                        _field(
                          fieldKey:
                              'openingBalance',
                          label:
                              "Opening Balance",
                          hint: "0.00",
                          icon: Icons
                              .account_balance_wallet_outlined,
                          controller:
                              openBalanceCtrl,
                          required: true,
                          keyboard:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    ),

                    // ==================================================
                    // ADDRESS
                    // ==================================================

                    _sectionCard(
                      title: "Address",
                      icon:
                          Icons.pin_drop_rounded,
                      children: [
                        _field(
                          fieldKey: 'address',
                          label: "Address",
                          hint:
                              "Enter full address (street, city, state, country, PIN)",
                          icon: Icons
                              .location_on_outlined,
                          controller:
                              addressCtrl,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ============================================================
      // BOTTOM BUTTONS
      // ============================================================

      bottomNavigationBar:
          Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(
              color: AppColors.border
                  .withValues(alpha: 0.4),
            ),
          ),
        ),

        padding: EdgeInsets.only(
          left: R.sp(
            context,
            AppSpacing.screenPadding + 2,
          ),
          right: R.sp(
            context,
            AppSpacing.screenPadding + 2,
          ),
          top: R.sp(
            context,
            AppSpacing.md,
          ),
          bottom: R.sp(
                context,
                AppSpacing.md,
              ) +
              MediaQuery.of(context)
                  .padding
                  .bottom,
        ),

        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: R.btnH(context),
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.pop(
                            context,
                          ),
                  style:
                      OutlinedButton.styleFrom(
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        R.radius(
                          context,
                          AppSizes.radiusMd +
                              2,
                        ),
                      ),
                    ),
                    side: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontWeight:
                          FontWeight.w600,
                      fontSize:
                          R.fs(context, 14),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(
              width: R.sp(
                context,
                AppSpacing.md,
              ),
            ),

            Expanded(
              flex: 2,
              child: SizedBox(
                height: R.btnH(context),
                child: Container(
                  decoration:
                      BoxDecoration(
                    gradient:
                        AppColors.brandGradient,
                    borderRadius:
                        BorderRadius.circular(
                      R.radius(
                        context,
                        AppSizes.radiusMd +
                            2,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors
                            .primary
                            .withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 8,
                        offset:
                            const Offset(
                          0,
                          4,
                        ),
                      ),
                    ],
                  ),

                  child:
                      ElevatedButton(
                    onPressed:
                        _isSaving
                            ? null
                            : _save,

                    style:
                        ElevatedButton
                            .styleFrom(
                      elevation: 0,
                      backgroundColor:
                          Colors.transparent,
                      shadowColor:
                          Colors.transparent,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          R.radius(
                            context,
                            AppSizes
                                    .radiusMd +
                                2,
                          ),
                        ),
                      ),
                    ),

                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            "Save Customer",
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize:
                                  R.fs(
                                context,
                                14,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}