import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:stock_management/core/constants/app_colors.dart';
import 'package:stock_management/core/constants/app_sizes.dart';
import 'package:stock_management/core/constants/app_spacing.dart';
import 'package:stock_management/core/utils/notification_utils.dart';
import 'package:stock_management/core/utils/responsive_helper.dart';
import 'package:stock_management/core/utils/validators.dart';

import '../../domain/entities/supplier.dart';
import '../providers/add_supplier_provider.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  ConsumerState<AddSupplierScreen> createState() =>
      _AddSupplierScreenState();
}

class _AddSupplierScreenState
    extends ConsumerState<AddSupplierScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final companyCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final postalCtrl = TextEditingController();
  final openingBalanceCtrl = TextEditingController();

  // ============================================================
  // CATEGORY STATE
  //
  // Stores selected product_categories.id values (NOT names).
  // The backend requires real category IDs to populate the
  // supplier_categories relationship table.
  // ============================================================

  final Set<int> _selectedCategoryIds = {};

  // ============================================================
  // INLINE ERRORS
  // ============================================================

  final Map<String, String?> _fieldErrors = {
    'company': null,
    'contact': null,
    'phone': null,
    'alternatePhone': null,
    'email': null,
    'gst': null,
    'pan': null,
    'address': null,
    'city': null,
    'state': null,
    'postal': null,
    'openingBalance': null,
    'category': null,
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dbCategoriesProvider);
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    companyCtrl.dispose();
    contactCtrl.dispose();
    phoneCtrl.dispose();
    altPhoneCtrl.dispose();
    emailCtrl.dispose();
    gstCtrl.dispose();
    panCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    postalCtrl.dispose();
    openingBalanceCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // VALIDATORS
  // ============================================================

  String? _validateCompanyName(String value) {
    final input = Validators.normalizeText(value);

    if (input.isEmpty) {
      return null;
    }

    final lengthError = Validators.validateText(
      input,
      fieldName: 'Company name',
      minLength: 3,
      maxLength: 150,
      required: false,
    );

    if (lengthError != null) {
      return lengthError;
    }

    if (!RegExp(
      r"^[A-Za-z0-9][A-Za-z0-9\s.,&'()/\-]*$",
    ).hasMatch(input)) {
      return 'Enter a valid company name';
    }

    return null;
  }

  String? _validateContactName(String value) {
    return Validators.validateName(
      value,
      fieldName: 'Contact name',
      minLength: 3,
    );
  }

  String? _validatePhone(String value) {
    return Validators.validatePhone(
      value,
      fieldName: 'Mobile number',
    );
  }

  String? _validateAlternatePhone(String value) {
    final error = Validators.validateOptionalPhone(
      value,
      fieldName: 'Alternate phone number',
    );

    if (error != null) {
      return error;
    }

    final phone =
        Validators.normalizeDigits(phoneCtrl.text);

    final alternate =
        Validators.normalizeDigits(value);

    if (alternate.isNotEmpty &&
        phone.isNotEmpty &&
        alternate == phone) {
      return 'Alternate phone must be different from mobile number';
    }

    return null;
  }

  String? _validateEmail(String value) {
    final error =
        Validators.validateOptionalEmail(value);

    if (error != null) {
      return error;
    }

    final normalized =
        Validators.normalizeEmail(value)
            .replaceAll(RegExp(r'\s+'), '');

    if (normalized.isEmpty) {
      return null;
    }

    if (!RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(normalized)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validateGst(String value) {
    return Validators.validateGstin(value);
  }

  String? _validatePan(String value) {
    return Validators.validatePan(value);
  }

  String? _validateAddress(String value) {
    return Validators.validateAddress(
      value,
      required: false,
    );
  }

  String? _validateCity(String value) {
    return Validators.validateLocationName(
      value,
      fieldName: 'City',
      required: false,
    );
  }

  String? _validateState(String value) {
    return Validators.validateLocationName(
      value,
      fieldName: 'State',
      required: false,
    );
  }

  String? _validatePostal(String value) {
    return Validators.validateIndianPin(value);
  }

  String? _validateOpeningBalance(String value) {
    return Validators.validateOptionalDecimal(
      value,
      fieldName: 'Opening balance',
      min: 0,
    );
  }

  String? _validateCategory() {
    if (_selectedCategoryIds.isEmpty) {
      return 'Select at least one category';
    }

    return null;
  }

  // ============================================================
  // LIVE FIELD VALIDATION
  // ============================================================

  void _validateField(
    String field,
    String value,
    String? Function(String) validator,
  ) {
    final error = validator(value);

    if (!mounted) {
      return;
    }

    setState(() {
      _fieldErrors[field] = error;
    });
  }

  // ============================================================
  // VALIDATE ALL
  // ============================================================

  bool _validateAllFields() {
    final errors = <String, String?>{
      'company':
          _validateCompanyName(companyCtrl.text),

      'contact':
          _validateContactName(contactCtrl.text),

      'phone':
          _validatePhone(phoneCtrl.text),

      'alternatePhone':
          _validateAlternatePhone(altPhoneCtrl.text),

      'email':
          _validateEmail(emailCtrl.text),

      'gst':
          _validateGst(gstCtrl.text),

      'pan':
          _validatePan(panCtrl.text),

      'address':
          _validateAddress(addressCtrl.text),

      'city':
          _validateCity(cityCtrl.text),

      'state':
          _validateState(stateCtrl.text),

      'postal':
          _validatePostal(postalCtrl.text),

      'openingBalance':
          _validateOpeningBalance(
        openingBalanceCtrl.text,
      ),

      'category':
          _validateCategory(),
    };

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });

    return !errors.values.any(
      (error) =>
          error != null &&
          error.isNotEmpty,
    );
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _pickAvatarImage() async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      ref
          .read(
            addSupplierNotifierProvider
                .notifier,
          )
          .setImage(
            File(pickedFile.path),
          );
    } catch (e) {
      if (!mounted) {
        return;
      }

      showCustomNotification(
        context,
        'Unable to select supplier image',
        isError: true,
      );
    }
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
            R.sp(
              context,
              AppSpacing.xs + 2,
            ),
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.08,
            ),
            borderRadius:
                BorderRadius.circular(
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
            fontSize: R.fs(
              context,
              13,
            ),
            fontWeight: FontWeight.bold,
            color:
                AppColors.textPrimaryDark,
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
        borderRadius:
            BorderRadius.circular(
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
          _sectionHeader(
            title,
            icon,
          ),
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

  // ============================================================
  // GAP
  // ============================================================

  Widget _gapV([
    double size = AppSpacing.md,
  ]) {
    return SizedBox(
      height: R.sp(
        context,
        size,
      ),
    );
  }

  // ============================================================
  // FIELD ROW
  // ============================================================

  Widget _fieldRow(
    Widget left,
    Widget right,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(
          width: R.sp(
            context,
            AppSpacing.md,
          ),
        ),
        Expanded(child: right),
      ],
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool required = false,
    TextInputType keyboard =
        TextInputType.text,
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _label(
          label,
          required: required,
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
          onChanged: onChanged,
          style: TextStyle(
            fontSize: R.fs(
              context,
              14,
            ),
            color:
                AppColors.textPrimaryDark,
          ),
          decoration: _inputDeco(
            hint: hint,
            icon: icon,
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDeco({
    required String hint,
    IconData? icon,
    String? errorText,
  }) {
    final hasError =
        errorText != null &&
        errorText.isNotEmpty;

    final normalBorder =
        OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(
        R.radius(
          context,
          AppSizes.radiusMd,
        ),
      ),
      borderSide: BorderSide(
        color: AppColors.border,
      ),
    );

    final errorBorder =
        OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(
        R.radius(
          context,
          AppSizes.radiusMd,
        ),
      ),
      borderSide:
          const BorderSide(
        color: AppColors.red,
        width: 1.4,
      ),
    );

    return InputDecoration(
      hintText: hint,

      hintStyle: TextStyle(
        fontSize: R.fs(
          context,
          13,
        ),
        color: AppColors.textSecondary
            .withValues(alpha: 0.7),
      ),

      prefixIcon: icon != null
          ? Icon(
              icon,
              size: R.icon(
                context,
                AppSizes.iconSm + 2,
              ),
              color: hasError
                  ? AppColors.red
                  : AppColors.textSecondary,
            )
          : null,

      filled: true,
      fillColor: AppColors.card,

      errorText:
          hasError ? errorText : null,

      errorStyle: TextStyle(
        fontSize: R.fs(
          context,
          11,
        ),
        color: AppColors.red,
      ),

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

      border: hasError
          ? errorBorder
          : normalBorder,

      enabledBorder: hasError
          ? errorBorder
          : normalBorder,

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

      errorBorder: errorBorder,

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          R.radius(
            context,
            AppSizes.radiusMd,
          ),
        ),
        borderSide:
            const BorderSide(
          color: AppColors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(
    String text, {
    bool required = false,
  }) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: R.fs(
            context,
            12,
          ),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark
              .withValues(alpha: 0.8),
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.red,
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  // ============================================================
  // CATEGORY PICKER
  // ============================================================

  void _showCategoryPicker(
    List<Map<String, dynamic>> categories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          AppColors.card,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(
            AppSizes.radiusXl,
          ),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (
            ctx,
            setModal,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xl,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom:
                    MediaQuery.of(ctx)
                            .viewInsets
                            .bottom +
                        AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Select Categories',
                        style: TextStyle(
                          fontSize:
                              R.fs(
                            context,
                            16,
                          ),
                          fontWeight:
                              FontWeight.w700,
                          color: AppColors
                              .textPrimaryDark,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _fieldErrors[
                                'category'] =
                                _validateCategory();
                          });

                          Navigator.pop(ctx);
                        },
                        child:
                            const Text(
                          'Done',
                          style:
                              TextStyle(
                            color:
                                AppColors
                                    .primary,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: R.sp(
                      context,
                      AppSpacing.sm,
                    ),
                  ),

                  const Divider(
                    color:
                        AppColors.border,
                    height: 1,
                  ),

                  SizedBox(
                    height: 250,
                    child: ListView(
                      children:
                          categories.map(
                        (category) {
                          final categoryId =
                              category['id']
                                  as int;
                          final categoryName =
                              category['name']
                                  .toString();

                          final selected =
                              _selectedCategoryIds
                                  .contains(
                            categoryId,
                          );

                          return CheckboxListTile(
                            value:
                                selected,
                            activeColor:
                                AppColors
                                    .primary,
                            dense:
                                true,
                            contentPadding:
                                EdgeInsets.zero,
                            title:
                                Text(
                              categoryName,
                              style:
                                  TextStyle(
                                fontSize:
                                    R.fs(
                                  context,
                                  14,
                                ),
                                fontWeight:
                                    FontWeight
                                        .w500,
                              ),
                            ),
                            onChanged:
                                (value) {
                              setModal(() {
                                if (value ==
                                    true) {
                                  _selectedCategoryIds
                                      .add(
                                    categoryId,
                                  );
                                } else {
                                  _selectedCategoryIds
                                      .remove(
                                    categoryId,
                                  );
                                }
                              });

                              setState(() {
                                _fieldErrors[
                                    'category'] =
                                    _validateCategory();
                              });
                            },
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CATEGORY FIELD
  // ============================================================

  Widget _categoryField(
    List<Map<String, dynamic>> categories,
  ) {
    final selectedNames = categories
        .where(
          (c) => _selectedCategoryIds.contains(
            c['id'] as int,
          ),
        )
        .map((c) => c['name'].toString())
        .toList();

    final display =
        selectedNames.isEmpty
            ? null
            : selectedNames.join(
                ', ',
              );

    final hasError =
        _fieldErrors['category'] != null;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _label(
          'Categories',
          required: true,
        ),

        SizedBox(
          height: R.sp(
            context,
            AppSpacing.xs + 2,
          ),
        ),

        GestureDetector(
          onTap: () =>
              _showCategoryPicker(
            categories,
          ),
          child: Container(
            width: double.infinity,
            padding:
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
            decoration:
                BoxDecoration(
              color:
                  AppColors.card,
              borderRadius:
                  BorderRadius.circular(
                R.radius(
                  context,
                  AppSizes.radiusMd,
                ),
              ),
              border:
                  Border.all(
                color: hasError
                    ? AppColors.red
                    : AppColors.border,
                width: hasError
                    ? 1.3
                    : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons
                      .category_outlined,
                  size: R.icon(
                    context,
                    AppSizes.iconSm + 2,
                  ),
                  color: hasError
                      ? AppColors.red
                      : AppColors
                          .textSecondary,
                ),

                SizedBox(
                  width: R.sp(
                    context,
                    AppSpacing.sm,
                  ),
                ),

                Expanded(
                  child: Text(
                    display ??
                        'Select operational categories',
                    style: TextStyle(
                      fontSize: R.fs(
                        context,
                        13,
                      ),
                      color: display !=
                              null
                          ? AppColors
                              .textPrimaryDark
                          : AppColors
                              .textSecondary
                              .withValues(
                              alpha: 0.7,
                            ),
                    ),
                    overflow:
                        TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  size: R.icon(
                    context,
                    18,
                  ),
                  color:
                      AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        if (hasError)
          Padding(
            padding:
                EdgeInsets.only(
              top: R.sp(
                context,
                5,
              ),
              left: R.sp(
                context,
                4,
              ),
            ),
            child: Text(
              _fieldErrors['category']!,
              style: TextStyle(
                fontSize: R.fs(
                  context,
                  11,
                ),
                color:
                    AppColors.red,
              ),
            ),
          ),

        if (selectedNames
            .isNotEmpty) ...[
          SizedBox(
            height: R.sp(
              context,
              AppSpacing.sm,
            ),
          ),

          Wrap(
            spacing: R.sp(
              context,
              AppSpacing.sm - 2,
            ),
            runSpacing: R.sp(
              context,
              AppSpacing.sm - 2,
            ),
            children: categories
                .where(
                  (c) => _selectedCategoryIds
                      .contains(
                    c['id'] as int,
                  ),
                )
                .map(
              (category) {
                final categoryId =
                    category['id'] as int;
                final categoryName =
                    category['name']
                        .toString();

                return Chip(
                  label: Text(
                    categoryName,
                    style:
                        TextStyle(
                      fontSize:
                          R.fs(
                        context,
                        11,
                      ),
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  deleteIcon:
                      const Icon(
                    Icons.close,
                    size: 14,
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedCategoryIds
                          .remove(
                        categoryId,
                      );

                      _fieldErrors[
                          'category'] =
                          _validateCategory();
                    });
                  },
                  backgroundColor:
                      AppColors.primary
                          .withValues(
                    alpha: 0.06,
                  ),
                  labelStyle:
                      const TextStyle(
                    color:
                        AppColors.primary,
                  ),
                  deleteIconColor:
                      AppColors.primary,
                  side:
                      const BorderSide(
                    color:
                        Colors.transparent,
                  ),
                  materialTapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap,
                  padding:
                      EdgeInsets
                          .symmetric(
                    horizontal:
                        R.sp(
                      context,
                      AppSpacing.xs,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // CLEAN BACKEND ERROR
  // ============================================================

  String _cleanErrorMessage(
    String message,
  ) {
    var cleaned =
        message.trim();

    if (cleaned.startsWith(
      'Exception: ',
    )) {
      cleaned =
          cleaned.substring(
        'Exception: '.length,
      );
    }

    if (cleaned.startsWith(
      'FormatException: ',
    )) {
      cleaned =
          cleaned.substring(
        'FormatException: '.length,
      );
    }

    return cleaned.isEmpty
        ? 'Failed to save supplier'
        : cleaned;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    // ----------------------------------------------------------
    // VALIDATE ALL FIELDS
    // ----------------------------------------------------------

    if (!_validateAllFields()) {
      showCustomNotification(
        context,
        'Please correct the highlighted fields',
        isError: true,
      );

      return;
    }

    // ----------------------------------------------------------
    // NORMALIZE
    // ----------------------------------------------------------

    final contactText =
        Validators.normalizeName(
      contactCtrl.text,
    );

    final companyText =
        Validators.normalizeText(
      companyCtrl.text,
    );

    final phoneText =
        Validators.normalizeDigits(
      phoneCtrl.text,
    );

    final alternatePhoneText =
        Validators.normalizeDigits(
      altPhoneCtrl.text,
    );

    final emailText =
        Validators.normalizeEmail(
      emailCtrl.text,
    ).replaceAll(
      RegExp(r'\s+'),
      '',
    );

    final gstText =
        Validators.normalizeUppercase(
      gstCtrl.text,
    );

    final panText =
        Validators.normalizeUppercase(
      panCtrl.text,
    );

    final addressText =
        Validators.normalizeText(
      addressCtrl.text,
    );

    final cityText =
        Validators.normalizeText(
      cityCtrl.text,
    );

    final stateText =
        Validators.normalizeText(
      stateCtrl.text,
    );

    final postalText =
        Validators.normalizeDigits(
      postalCtrl.text,
    );

    final openingBalanceText =
        openingBalanceCtrl.text.trim();

    final balanceValue =
        openingBalanceText.isEmpty
            ? 0.00
            : double.parse(
                openingBalanceText,
              );

    // ----------------------------------------------------------
    // SUPPLIER ENTITY
    // ----------------------------------------------------------

    final supplier = Supplier(
      id: 0,

      supplierCode:
          'SUP-${DateTime.now().millisecondsSinceEpoch}',

      /*
       * Existing backend/entity wiring.
       */
      supplierName:
          contactText,

      companyName:
          companyText,

      contactPerson:
          contactText,

      phone:
          phoneText,

      alternatePhone:
          alternatePhoneText.isNotEmpty
              ? alternatePhoneText
              : null,

      email:
          emailText.isNotEmpty
              ? emailText
              : null,

      gstNumber:
          gstText.isNotEmpty
              ? gstText
              : null,

      panNumber:
          panText.isNotEmpty
              ? panText
              : null,

      address:
          addressText.isNotEmpty
              ? addressText
              : null,

      city:
          cityText.isNotEmpty
              ? cityText
              : null,

      state:
          stateText.isNotEmpty
              ? stateText
              : null,

      /*
       * DO NOT put selected categories here.
       *
       * The backend expects a real country value in this
       * field. Categories are sent separately below via
       * categoryIds, which the backend persists in the
       * supplier_categories relationship table.
       */
      country:
          'India',

      postalCode:
          postalText.isNotEmpty
              ? postalText
              : null,

      openingBalance:
          balanceValue,

      currentBalance:
          balanceValue,

      creditLimit:
          0.00,

      notes:
          '',

      status:
          'ACTIVE',

      categoryIds:
          _selectedCategoryIds.toList(),
    );

    // ----------------------------------------------------------
    // SAVE
    //
    // Existing provider handles:
    //
    // 1. POST suppliers.php
    // 2. receives new supplier ID
    // 3. uploads selected image using that ID
    // ----------------------------------------------------------

    final success =
        await ref
            .read(
              addSupplierNotifierProvider
                  .notifier,
            )
            .saveSupplier(
              supplier,
            );

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (success) {
      showCustomNotification(
        context,
        'Supplier registered successfully',
      );

      Navigator.pop(
        context,
        true,
      );

      return;
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    final error =
        ref
            .read(
              addSupplierNotifierProvider,
            )
            .errorMessage;

    showCustomNotification(
      context,
      _cleanErrorMessage(error),
      isError: true,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final asyncCategories =
        ref.watch(
      dbCategoriesProvider,
    );

    final availableCategories =
        asyncCategories.value ??
            const <Map<String, dynamic>>[];

    final addState =
        ref.watch(
      addSupplierNotifierProvider,
    );

    return Scaffold(
      backgroundColor:
          AppColors.background,

      body: SafeArea(
        child: IgnorePointer(
          ignoring:
              addState.isSaving,

          child: Column(
            children: [
              // ==================================================
              // TOP BAR
              // ==================================================

              Padding(
                padding:
                    R.hPad(
                  context,
                  base:
                      AppSpacing
                          .screenPadding,
                ).copyWith(
                  top: R.sp(
                    context,
                    AppSpacing.lg,
                  ),
                  bottom: R.sp(
                    context,
                    AppSpacing.sm,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          addState.isSaving
                              ? null
                              : () =>
                                  Navigator.pop(
                                context,
                              ),
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors
                            .textPrimaryDark,
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
                        'Create Supplier Profile',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color: AppColors
                              .textPrimaryDark,
                          fontSize:
                              R.fs(
                            context,
                            18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // BODY
              // ==================================================

              Expanded(
                child:
                    SingleChildScrollView(
                  padding:
                      R.hPad(
                    context,
                    base:
                        AppSpacing
                            .screenPadding,
                  ).copyWith(
                    top: R.sp(
                      context,
                      AppSpacing.md,
                    ),
                    bottom: R.sp(
                      context,
                      AppSpacing.xl,
                    ),
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      // ==========================================
                      // IMAGE
                      // ==========================================

                      Center(
                        child:
                            Stack(
                          children: [
                            Container(
                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withValues(
                                      alpha:
                                          0.05,
                                    ),
                                    blurRadius:
                                        12,
                                    offset:
                                        const Offset(
                                      0,
                                      4,
                                    ),
                                  ),
                                ],
                              ),
                              child:
                                  CircleAvatar(
                                radius:
                                    R.sp(
                                  context,
                                  44,
                                ),
                                backgroundColor:
                                    AppColors
                                        .card,
                                backgroundImage:
                                    addState
                                                .selectedImage !=
                                            null
                                        ? FileImage(
                                            addState
                                                .selectedImage!,
                                          )
                                        : null,
                                child:
                                    addState.selectedImage ==
                                            null
                                        ? Icon(
                                            Icons
                                                .add_a_photo_outlined,
                                            size:
                                                R.icon(
                                              context,
                                              26,
                                            ),
                                            color:
                                                AppColors
                                                    .primary,
                                          )
                                        : null,
                              ),
                            ),

                            Positioned(
                              bottom: 2,
                              right: 2,
                              child:
                                  GestureDetector(
                                onTap:
                                    addState
                                            .isSaving
                                        ? null
                                        : _pickAvatarImage,
                                child:
                                    Container(
                                  width:
                                      R.sp(
                                    context,
                                    28,
                                  ),
                                  height:
                                      R.sp(
                                    context,
                                    28,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        AppColors
                                            .primary,
                                    shape:
                                        BoxShape
                                            .circle,
                                    border:
                                        Border.all(
                                      color:
                                          Colors.white,
                                      width:
                                          2,
                                    ),
                                  ),
                                  child:
                                      Icon(
                                    Icons
                                        .camera_alt,
                                    size:
                                        R.icon(
                                      context,
                                      13,
                                    ),
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: R.sp(
                          context,
                          AppSpacing.xl,
                        ),
                      ),

                      // ==========================================
                      // CORPORATE IDENTITY
                      // ==========================================

                      _sectionCard(
                        title:
                            'Corporate Identity',
                        icon:
                            Icons
                                .business_rounded,
                        children: [
                          _field(
                            label:
                                'Company Name',
                            hint:
                                'Enter registered legal trade entity name',
                            icon:
                                Icons
                                    .business_outlined,
                            controller:
                                companyCtrl,
                            errorText:
                                _fieldErrors[
                                    'company'],
                            onChanged:
                                (value) {
                              _validateField(
                                'company',
                                value,
                                _validateCompanyName,
                              );
                            },
                          ),
                        ],
                      ),

                      // ==========================================
                      // PRIMARY CONTACT
                      // ==========================================

                      _sectionCard(
                        title:
                            'Primary Contact Links',
                        icon:
                            Icons
                                .contact_phone_rounded,
                        children: [
                          _field(
                            label:
                                'Contact Name',
                            hint:
                                'Full operational name',
                            icon:
                                Icons
                                    .person_outline,
                            controller:
                                contactCtrl,
                            required:
                                true,
                            errorText:
                                _fieldErrors[
                                    'contact'],
                            onChanged:
                                (value) {
                              _validateField(
                                'contact',
                                value,
                                _validateContactName,
                              );
                            },
                          ),

                          _gapV(
                            AppSpacing
                                    .md +
                                2,
                          ),

                          _field(
                            label:
                                'Mobile Line',
                            hint:
                                '10-digit number',
                            icon:
                                Icons
                                    .phone_outlined,
                            controller:
                                phoneCtrl,
                            required:
                                true,
                            keyboard:
                                TextInputType.phone,
                            errorText:
                                _fieldErrors[
                                    'phone'],
                            onChanged:
                                (value) {
                              _validateField(
                                'phone',
                                value,
                                _validatePhone,
                              );

                              if (altPhoneCtrl
                                  .text
                                  .isNotEmpty) {
                                _validateField(
                                  'alternatePhone',
                                  altPhoneCtrl
                                      .text,
                                  _validateAlternatePhone,
                                );
                              }
                            },
                          ),

                          _gapV(
                            AppSpacing
                                    .md +
                                2,
                          ),

                          _field(
                            label:
                                'Secondary Line',
                            hint:
                                'Alternate contact',
                            icon:
                                Icons
                                    .phone_android_outlined,
                            controller:
                                altPhoneCtrl,
                            keyboard:
                                TextInputType.phone,
                            errorText:
                                _fieldErrors[
                                    'alternatePhone'],
                            onChanged:
                                (value) {
                              _validateField(
                                'alternatePhone',
                                value,
                                _validateAlternatePhone,
                              );
                            },
                          ),

                          _gapV(
                            AppSpacing
                                    .md +
                                2,
                          ),

                          _field(
                            label:
                                'Email Address',
                            hint:
                                'office@domain.com',
                            icon:
                                Icons
                                    .email_outlined,
                            controller:
                                emailCtrl,
                            keyboard:
                                TextInputType
                                    .emailAddress,
                            errorText:
                                _fieldErrors[
                                    'email'],
                            onChanged:
                                (value) {
                              _validateField(
                                'email',
                                value,
                                _validateEmail,
                              );
                            },
                          ),
                        ],
                      ),

                      // ==========================================
                      // TAX & FINANCIAL
                      // ==========================================

                      _sectionCard(
                        title:
                            'Tax & Financial Details',
                        icon:
                            Icons
                                .credit_card_rounded,
                        children: [
                          _fieldRow(
                            _field(
                              label:
                                  'GSTIN',
                              hint:
                                  '15-character GST number',
                              icon:
                                  Icons.percent,
                              controller:
                                  gstCtrl,
                              errorText:
                                  _fieldErrors[
                                      'gst'],
                              onChanged:
                                  (value) {
                                _validateField(
                                  'gst',
                                  value,
                                  _validateGst,
                                );
                              },
                            ),
                            _field(
                              label:
                                  'PAN',
                              hint:
                                  '10-character PAN',
                              icon:
                                  Icons
                                      .credit_card_outlined,
                              controller:
                                  panCtrl,
                              errorText:
                                  _fieldErrors[
                                      'pan'],
                              onChanged:
                                  (value) {
                                _validateField(
                                  'pan',
                                  value,
                                  _validatePan,
                                );
                              },
                            ),
                          ),

                          _gapV(
                            AppSpacing
                                    .md +
                                2,
                          ),

                          _field(
                            label:
                                'Opening Balance / Pending Amount',
                            hint:
                                'Enter amount (₹)',
                            icon:
                                Icons
                                    .account_balance_wallet_outlined,
                            controller:
                                openingBalanceCtrl,
                            keyboard:
                                const TextInputType
                                    .numberWithOptions(
                              decimal:
                                  true,
                            ),
                            errorText:
                                _fieldErrors[
                                    'openingBalance'],
                            onChanged:
                                (value) {
                              _validateField(
                                'openingBalance',
                                value,
                                _validateOpeningBalance,
                              );
                            },
                          ),
                        ],
                      ),

                      // ==========================================
                      // ADDRESS
                      // ==========================================

                      _sectionCard(
                        title:
                            'Geographic Logistics',
                        icon:
                            Icons
                                .pin_drop_rounded,
                        children: [
                          _field(
                            label:
                                'Corporate Address',
                            hint:
                                'Street info, warehouse location',
                            icon:
                                Icons
                                    .location_on_outlined,
                            controller:
                                addressCtrl,
                            maxLines:
                                2,
                            errorText:
                                _fieldErrors[
                                    'address'],
                            onChanged:
                                (value) {
                              _validateField(
                                'address',
                                value,
                                _validateAddress,
                              );
                            },
                          ),

                          _gapV(
                            AppSpacing
                                    .md +
                                2,
                          ),

                          _fieldRow(
                            _field(
                              label:
                                  'City',
                              hint:
                                  'City',
                              icon:
                                  Icons
                                      .location_city_outlined,
                              controller:
                                  cityCtrl,
                              errorText:
                                  _fieldErrors[
                                      'city'],
                              onChanged:
                                  (value) {
                                _validateField(
                                  'city',
                                  value,
                                  _validateCity,
                                );
                              },
                            ),
                            _field(
                              label:
                                  'State / Region',
                              hint:
                                  'State',
                              icon:
                                  Icons
                                      .map_outlined,
                              controller:
                                  stateCtrl,
                              errorText:
                                  _fieldErrors[
                                      'state'],
                              onChanged:
                                  (value) {
                                _validateField(
                                  'state',
                                  value,
                                  _validateState,
                                );
                              },
                            ),
                          ),

                          _gapV(
                            AppSpacing
                                    .md +
                                2,
                          ),

                          _field(
                            label:
                                'ZIP / Postal Code',
                            hint:
                                '6-digit PIN code',
                            icon:
                                Icons
                                    .local_post_office_outlined,
                            controller:
                                postalCtrl,
                            keyboard:
                                TextInputType.number,
                            errorText:
                                _fieldErrors[
                                    'postal'],
                            onChanged:
                                (value) {
                              _validateField(
                                'postal',
                                value,
                                _validatePostal,
                              );
                            },
                          ),
                        ],
                      ),

                      // ==========================================
                      // CATEGORIES
                      // ==========================================

                      _sectionCard(
                        title:
                            'Categories',
                        icon:
                            Icons
                                .category_rounded,
                        children: [
                          _categoryField(
                            availableCategories,
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
      ),

      // ==========================================================
      // BOTTOM ACTION BAR
      // ==========================================================

      bottomNavigationBar:
          Container(
        decoration:
            BoxDecoration(
          color:
              AppColors.card,
          border: Border(
            top: BorderSide(
              color: AppColors
                  .border
                  .withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ),
        padding:
            EdgeInsets.only(
          left: R.sp(
            context,
            AppSpacing
                    .screenPadding +
                2,
          ),
          right: R.sp(
            context,
            AppSpacing
                    .screenPadding +
                2,
          ),
          top: R.sp(
            context,
            AppSpacing.md,
          ),
          bottom:
              R.sp(
                context,
                AppSpacing.md,
              ) +
              MediaQuery.of(
                context,
              ).padding.bottom,
        ),
        child: Row(
          children: [
            // ====================================================
            // CANCEL
            // ====================================================

            Expanded(
              child: SizedBox(
                height:
                    R.btnH(context),
                child:
                    OutlinedButton(
                  onPressed:
                      addState
                              .isSaving
                          ? null
                          : () =>
                              Navigator.pop(
                            context,
                          ),
                  style:
                      OutlinedButton.styleFrom(
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        R.radius(
                          context,
                          AppSizes
                                  .radiusMd +
                              2,
                        ),
                      ),
                    ),
                    side:
                        const BorderSide(
                      color:
                          AppColors
                              .border,
                    ),
                  ),
                  child:
                      Text(
                    'Cancel',
                    style:
                        TextStyle(
                      color:
                          AppColors
                              .textSecondary,
                      fontWeight:
                          FontWeight.w600,
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

            SizedBox(
              width: R.sp(
                context,
                AppSpacing.md,
              ),
            ),

            // ====================================================
            // SAVE
            // ====================================================

            Expanded(
              flex: 2,
              child: SizedBox(
                height:
                    R.btnH(context),
                child:
                    Container(
                  decoration:
                      BoxDecoration(
                    gradient:
                        addState
                                .isSaving
                            ? null
                            : AppColors
                                .brandGradient,
                    color:
                        addState.isSaving
                            ? AppColors
                                .border
                            : null,
                    borderRadius:
                        BorderRadius
                            .circular(
                      R.radius(
                        context,
                        AppSizes
                                .radiusMd +
                            2,
                      ),
                    ),
                    boxShadow:
                        addState
                                .isSaving
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors
                                      .primary
                                      .withValues(
                                    alpha:
                                        0.25,
                                  ),
                                  blurRadius:
                                      8,
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
                        addState
                                .isSaving
                            ? null
                            : _save,
                    style:
                        ElevatedButton.styleFrom(
                      elevation:
                          0,
                      backgroundColor:
                          Colors
                              .transparent,
                      shadowColor:
                          Colors
                              .transparent,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          R.radius(
                            context,
                            AppSizes
                                    .radiusMd +
                                2,
                          ),
                        ),
                      ),
                    ),
                    child:
                        addState.isSaving
                            ? SizedBox(
                                width:
                                    R.sp(
                                  context,
                                  20,
                                ),
                                height:
                                    R.sp(
                                  context,
                                  20,
                                ),
                                child:
                                    const CircularProgressIndicator(
                                  color:
                                      AppColors
                                          .primary,
                                  strokeWidth:
                                      2.5,
                                ),
                              )
                            : Text(
                                'Save Supplier Record',
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
