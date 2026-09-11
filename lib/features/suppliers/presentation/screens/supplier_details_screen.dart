import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/core/constants/app_colors.dart';
import 'package:stock_management/core/constants/app_sizes.dart';
import 'package:stock_management/core/constants/app_spacing.dart';
import 'package:stock_management/core/network/api_config.dart';
import 'package:stock_management/core/utils/responsive_helper.dart';
import 'package:stock_management/core/utils/notification_utils.dart';
import 'package:stock_management/features/suppliers/domain/entities/supplier.dart';
import '../providers/add_supplier_provider.dart';
import '../providers/supplier_provider.dart';

class SupplierDetailsScreen extends ConsumerStatefulWidget {
  final Supplier supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailsScreen> createState() =>
      _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends ConsumerState<SupplierDetailsScreen> {
  late TextEditingController companyCtrl;
  late TextEditingController contactCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController altPhoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController gstCtrl;
  late TextEditingController panCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController postalCtrl;
  late TextEditingController openingBalanceCtrl;

  // Stores selected product_categories.id values (NOT names).
  final Set<int> _selectedCategoryIds = {};

  bool _isUpdating = false;

  // Capitalize first letter helper
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    companyCtrl = TextEditingController(
      text: s.companyName != null
          ? _capitalizeFirstLetter(s.companyName!)
          : _capitalizeFirstLetter(s.supplierName),
    );
    contactCtrl = TextEditingController(
      text: _capitalizeFirstLetter(s.supplierName),
    );
    phoneCtrl = TextEditingController(text: s.phone ?? "");
    altPhoneCtrl = TextEditingController(text: s.alternatePhone ?? "");
    emailCtrl = TextEditingController(text: s.email ?? "");
    gstCtrl = TextEditingController(text: s.gstNumber ?? "");
    panCtrl = TextEditingController(text: s.panNumber ?? "");
    addressCtrl = TextEditingController(text: s.address ?? "");
    cityCtrl = TextEditingController(text: s.city ?? "");
    stateCtrl = TextEditingController(text: s.state ?? "");
    postalCtrl = TextEditingController(text: s.postalCode ?? "");

    double initialBal = s.currentBalance > 0
        ? s.currentBalance
        : s.openingBalance;
    openingBalanceCtrl = TextEditingController(
      text: initialBal > 0
          ? (initialBal == initialBal.truncateToDouble()
                ? initialBal.toInt().toString()
                : initialBal.toStringAsFixed(2))
          : "",
    );

    // Categories are stored in Supplier.categoryIds (product_categories
    // relationship), NOT in the country field. Earlier code incorrectly
    // packed category names into country — fixed here to match the
    // add-supplier flow.
    _selectedCategoryIds.addAll(s.categoryIds);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dbCategoriesProvider);
    });
  }

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

  Future<void> _changeAvatarImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null && mounted) {
      ref
          .read(addSupplierNotifierProvider.notifier)
          .setImage(File(pickedFile.path));
      showCustomNotification(
        context,
        "New thumbnail image staged. Tap Update below to save.",
      );
    }
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(R.sp(context, AppSpacing.xs + 2)),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(
              R.radius(context, AppSizes.radiusSm + 4),
            ),
          ),
          child: Icon(
            icon,
            size: R.icon(context, AppSizes.iconSm),
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: R.sp(context, AppSpacing.sm + 2)),
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.lg)),
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusLg),
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, icon),
          SizedBox(height: R.sp(context, AppSpacing.md)),
          ...children,
        ],
      ),
    );
  }

  Widget _gapV([double size = AppSpacing.md]) =>
      SizedBox(height: R.sp(context, size));

  Widget _fieldRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: R.sp(context, AppSpacing.md)),
        Expanded(child: right),
      ],
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: R.fs(context, 12),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark.withValues(alpha: 0.8),
        ),
        children: required
            ? const [
                TextSpan(
                  text: " *",
                  style: TextStyle(color: AppColors.red),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),
        SizedBox(height: R.sp(context, AppSpacing.xs + 2)),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          enabled: !_isUpdating,
          style: TextStyle(
            fontSize: R.fs(context, 14),
            color: _isUpdating
                ? AppColors.textSecondary
                : AppColors.textPrimaryDark,
          ),
          decoration: _inputDeco(hint: hint, icon: icon, errorText: errorText),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    IconData? icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: R.fs(context, 13),
        color: AppColors.textSecondary.withValues(alpha: 0.7),
      ),
      prefixIcon: icon != null
          ? Icon(
              icon,
              size: R.icon(context, AppSizes.iconSm + 2),
              color: AppColors.textSecondary,
            )
          : null,
      filled: true,
      fillColor: _isUpdating ? AppColors.background : AppColors.card,
      errorText: errorText != null && errorText.isNotEmpty ? errorText : null,
      errorStyle: TextStyle(fontSize: R.fs(context, 11), color: AppColors.red),
      contentPadding: EdgeInsets.symmetric(
        horizontal: R.sp(context, AppSpacing.md + 2),
        vertical: R.sp(context, AppSpacing.md),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusMd),
        ),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusMd),
        ),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          R.radius(context, AppSizes.radiusMd),
        ),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  void _showCategoryPicker(List<Map<String, dynamic>> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xl,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Select Categories",
                        style: TextStyle(
                          fontSize: R.fs(context, 16),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          "Done",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: R.sp(context, AppSpacing.sm)),
                  const Divider(color: AppColors.border, height: 1),
                  SizedBox(
                    height: 220,
                    child: ListView(
                      children: categories.map((cat) {
                        final categoryId = cat['id'] as int;
                        final categoryName = cat['name'].toString();
                        final selected =
                            _selectedCategoryIds.contains(categoryId);
                        return CheckboxListTile(
                          value: selected,
                          activeColor: AppColors.primary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: R.fs(context, 14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onChanged: (val) {
                            setModal(() {
                              if (val == true) {
                                _selectedCategoryIds.add(categoryId);
                              } else {
                                _selectedCategoryIds.remove(categoryId);
                              }
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
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

  Widget _categoryField(List<Map<String, dynamic>> categories) {
    final selectedNames = categories
        .where((c) => _selectedCategoryIds.contains(c['id'] as int))
        .map((c) => c['name'].toString())
        .toList();

    final display =
        selectedNames.isEmpty ? null : selectedNames.join(", ");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Operational Categories"),
        SizedBox(height: R.sp(context, AppSpacing.xs + 2)),
        GestureDetector(
          onTap: _isUpdating ? null : () => _showCategoryPicker(categories),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, AppSpacing.md + 2),
              vertical: R.sp(context, AppSpacing.md),
            ),
            decoration: BoxDecoration(
              color: _isUpdating ? AppColors.background : AppColors.card,
              borderRadius: BorderRadius.circular(
                R.radius(context, AppSizes.radiusMd),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: R.icon(context, AppSizes.iconSm + 2),
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: R.sp(context, AppSpacing.sm)),
                Expanded(
                  child: Text(
                    display ?? "No categories selected",
                    style: TextStyle(
                      fontSize: R.fs(context, 13),
                      color: display != null
                          ? AppColors.textPrimaryDark
                          : AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: R.icon(context, 18),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (selectedNames.isNotEmpty) ...[
          SizedBox(height: R.sp(context, AppSpacing.sm)),
          Wrap(
            spacing: R.sp(context, AppSpacing.sm - 2),
            runSpacing: R.sp(context, AppSpacing.sm - 2),
            children: categories
                .where((c) => _selectedCategoryIds.contains(c['id'] as int))
                .map((cat) {
              final categoryId = cat['id'] as int;
              final categoryName = cat['name'].toString();
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, AppSpacing.sm + 4),
                  vertical: R.sp(context, AppSpacing.xs + 1),
                ),
                decoration: BoxDecoration(
                  gradient: _isUpdating ? null : AppColors.brandGradient,
                  color: _isUpdating ? AppColors.border : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: R.fs(context, 11),
                        color: _isUpdating
                            ? AppColors.textSecondary
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: R.sp(context, AppSpacing.xs + 2)),
                    GestureDetector(
                      onTap: _isUpdating
                          ? null
                          : () => setState(
                              () => _selectedCategoryIds.remove(categoryId),
                            ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: _isUpdating
                            ? AppColors.textSecondary
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _update() async {
    final contactText = _capitalizeFirstLetter(contactCtrl.text.trim());
    final phoneText = phoneCtrl.text.trim();

    if (contactText.isEmpty) {
      showCustomNotification(
        context,
        "Contact name is required",
        isError: true,
      );
      return;
    }
    if (phoneText.isEmpty) {
      showCustomNotification(
        context,
        "Phone number is required",
        isError: true,
      );
      return;
    }

    setState(() => _isUpdating = true);

    final balanceVal = double.tryParse(openingBalanceCtrl.text.trim()) ?? 0.0;

    final updatedSupplier = Supplier(
      id: widget.supplier.id,
      supplierCode: widget.supplier.supplierCode,
      supplierName: contactText,
      companyName: companyCtrl.text.trim().isNotEmpty
          ? _capitalizeFirstLetter(companyCtrl.text.trim())
          : contactText,
      contactPerson: contactText,
      phone: phoneText,
      alternatePhone: altPhoneCtrl.text.trim().isNotEmpty
          ? altPhoneCtrl.text.trim()
          : null,
      email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
      gstNumber: gstCtrl.text.trim().isNotEmpty ? gstCtrl.text.trim() : null,
      panNumber: panCtrl.text.trim().isNotEmpty ? panCtrl.text.trim() : null,
      address: addressCtrl.text.trim().isNotEmpty
          ? addressCtrl.text.trim()
          : null,
      city: cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : null,
      state: stateCtrl.text.trim().isNotEmpty ? stateCtrl.text.trim() : null,
      // Preserve the supplier's actual country — categories are no
      // longer packed into this field, they go through categoryIds.
      country: widget.supplier.country ?? 'India',
      postalCode: postalCtrl.text.trim().isNotEmpty
          ? postalCtrl.text.trim()
          : null,
      openingBalance: balanceVal,
      currentBalance: balanceVal,
      creditLimit: widget.supplier.creditLimit,
      notes: widget.supplier.notes,
      status: widget.supplier.status,
      image: widget.supplier.image,
      categoryIds: _selectedCategoryIds.toList(),
    );

    final success = await ref
        .read(addSupplierNotifierProvider.notifier)
        .saveSupplier(updatedSupplier);

    setState(() => _isUpdating = false);

    if (success && mounted) {
      showCustomNotification(context, "Supplier modified successfully");
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = ref.read(addSupplierNotifierProvider).errorMessage;
      showCustomNotification(
        context,
        error.isNotEmpty ? error : "Modification push rejected by gateway",
        isError: true,
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(
          "Delete Supplier",
          style: TextStyle(
            fontSize: R.fs(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to permanently soft delete this corporate partner profile?",
          style: TextStyle(
            fontSize: R.fs(context, 13),
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontSize: R.fs(context, 14),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            child: Text(
              "Delete",
              style: TextStyle(
                fontSize: R.fs(context, 14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(suppliersNotifierProvider.notifier)
          .removeSupplier(widget.supplier.id);
      if (success && mounted) {
        showCustomNotification(
          context,
          "Supplier removed from active indexing parameters successfully",
        );
        Navigator.pop(context, true);
      }
    }
  }

  bool _hasValidImage(String? image) {
    return image != null &&
        image.isNotEmpty &&
        (image.contains('/') || image.contains('.'));
  }

  @override
  Widget build(BuildContext context) {
    final name = _capitalizeFirstLetter(widget.supplier.supplierName);
    final parts = name.trim().split(" ");
    final initials = parts.length >= 2
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : "?";
    final asyncCategories = ref.watch(dbCategoriesProvider);
    final availableCategories =
        asyncCategories.value ?? const <Map<String, dynamic>>[];
    final localImage = ref.watch(addSupplierNotifierProvider).selectedImage;

    final bool hasValidImage = _hasValidImage(widget.supplier.image);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IgnorePointer(
          ignoring: _isUpdating,
          child: Column(
            children: [
              // ── Fixed Top Bar ──
              Padding(
                padding: R
                    .hPad(context, base: AppSpacing.screenPadding)
                    .copyWith(
                      top: R.sp(context, AppSpacing.lg),
                      bottom: R.sp(context, AppSpacing.sm),
                    ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimaryDark,
                        size: R.icon(context, 22),
                      ),
                    ),
                    SizedBox(width: R.sp(context, AppSpacing.sm)),
                    Expanded(
                      child: Text(
                        "Supplier Management",
                        style: TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: R.fs(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isUpdating ? null : _delete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.textPrimaryDark,
                        size: R.icon(context, 22),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable Body ──
              Expanded(
                child: SingleChildScrollView(
                  padding: R
                      .hPad(context, base: AppSpacing.screenPadding)
                      .copyWith(
                        top: R.sp(context, AppSpacing.md),
                        bottom: R.sp(context, AppSpacing.xl),
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar + name ──
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: R.fluid(context, 76, 88),
                              height: R.fluid(context, 76, 88),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: localImage == null && !hasValidImage
                                    ? AppColors.brandGradient
                                    : null,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                image: localImage != null
                                    ? DecorationImage(
                                        image: FileImage(localImage),
                                        fit: BoxFit.cover,
                                      )
                                    : (hasValidImage
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                '${ApiConfig.baseUrl}/${widget.supplier.image}',
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null),
                              ),
                              alignment: Alignment.center,
                              child: localImage == null && !hasValidImage
                                  ? Text(
                                      initials,
                                      style: TextStyle(
                                        fontSize: R.fs(context, 24),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUpdating ? null : _changeAvatarImage,
                                child: Container(
                                  width: R.sp(context, 28),
                                  height: R.sp(context, 28),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: R.icon(context, 12),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: R.sp(context, AppSpacing.sm + 4)),
                      Center(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: R.fs(context, 18),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ),
                      SizedBox(height: R.sp(context, AppSpacing.xl)),

                      // ── Corporate Identity ──
                      _sectionCard(
                        title: "Corporate Identity",
                        icon: Icons.business_rounded,
                        children: [
                          _field(
                            label: "Company Name",
                            hint: "Enter registered legal trade entity name",
                            icon: Icons.business_outlined,
                            controller: companyCtrl,
                          ),
                        ],
                      ),

                      // ── Contact Information ──
                      _sectionCard(
                        title: "Contact Information",
                        icon: Icons.contact_phone_rounded,
                        children: [
                          _field(
                            label: "Contact Person",
                            hint: "Full operational name",
                            icon: Icons.person_outline,
                            controller: contactCtrl,
                            required: true,
                          ),
                          _gapV(AppSpacing.md + 2),
                          _field(
                            label: "Phone Line",
                            hint: "10-digit number",
                            icon: Icons.phone_outlined,
                            controller: phoneCtrl,
                            required: true,
                            keyboard: TextInputType.phone,
                          ),
                          _gapV(AppSpacing.md + 2),
                          _field(
                            label: "Alternate Line",
                            hint: "Alternate contact",
                            icon: Icons.phone_android_outlined,
                            controller: altPhoneCtrl,
                            keyboard: TextInputType.phone,
                          ),
                          _gapV(AppSpacing.md + 2),
                          _field(
                            label: "Email Address",
                            hint: "office@domain.com",
                            icon: Icons.email_outlined,
                            controller: emailCtrl,
                            keyboard: TextInputType.emailAddress,
                          ),
                        ],
                      ),

                      // ── Tax, Financial & Balance ──
                      _sectionCard(
                        title: "Tax & Financial Details",
                        icon: Icons.credit_card_rounded,
                        children: [
                          _fieldRow(
                            _field(
                              label: "GSTIN Identification",
                              hint: "Unassigned / 15-char ID",
                              icon: Icons.percent,
                              controller: gstCtrl,
                            ),
                            _field(
                              label: "PAN Registry Code",
                              hint: "10-character code",
                              icon: Icons.credit_card_outlined,
                              controller: panCtrl,
                            ),
                          ),
                          _gapV(AppSpacing.md + 2),
                          _field(
                            label: "Opening Balance / Pending Amount",
                            hint: "Enter amount (₹)",
                            icon: Icons.account_balance_wallet_outlined,
                            controller: openingBalanceCtrl,
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),

                      // ── Address ──
                      _sectionCard(
                        title: "Address & Location",
                        icon: Icons.pin_drop_rounded,
                        children: [
                          _field(
                            label: "Street Address",
                            hint: "Street info, warehousing node location",
                            icon: Icons.location_on_outlined,
                            controller: addressCtrl,
                            maxLines: 2,
                          ),
                          _gapV(AppSpacing.md + 2),
                          _fieldRow(
                            _field(
                              label: "City",
                              hint: "City context",
                              icon: Icons.location_city_outlined,
                              controller: cityCtrl,
                            ),
                            _field(
                              label: "State / Territory",
                              hint: "State region",
                              icon: Icons.map_outlined,
                              controller: stateCtrl,
                            ),
                          ),
                          _gapV(AppSpacing.md + 2),
                          _field(
                            label: "Postal PIN Code",
                            hint: "6-digit routing code",
                            icon: Icons.local_post_office_outlined,
                            controller: postalCtrl,
                            keyboard: TextInputType.number,
                          ),
                        ],
                      ),

                      // ── Categories ──
                      _sectionCard(
                        title: "Categories",
                        icon: Icons.category_rounded,
                        children: [_categoryField(availableCategories)],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
          ),
        ),
        padding: EdgeInsets.only(
          left: R.sp(context, AppSpacing.screenPadding + 2),
          right: R.sp(context, AppSpacing.screenPadding + 2),
          top: R.sp(context, AppSpacing.md),
          bottom:
              R.sp(context, AppSpacing.md) +
              MediaQuery.of(context).padding.bottom,
        ),
        child: SizedBox(
          width: double.infinity,
          height: R.btnH(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _isUpdating ? null : AppColors.brandGradient,
              color: _isUpdating ? AppColors.border : null,
              borderRadius: BorderRadius.circular(
                R.radius(context, AppSizes.radiusMd + 2),
              ),
              boxShadow: _isUpdating
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _update,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusMd + 2),
                  ),
                ),
              ),
              child: _isUpdating
                  ? SizedBox(
                      width: R.sp(context, 20),
                      height: R.sp(context, 20),
                      child: const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      "Update Supplier Information",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: R.fs(context, 14),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
