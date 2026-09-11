import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../data/models/customer_model.dart';
import '../provider/customer_provider.dart';

class CustomerDetailsScreen extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailsScreen> createState() =>
      _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends ConsumerState<CustomerDetailsScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController altPhoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController gstCtrl;
  late TextEditingController addressCtrl;
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final postalCtrl = TextEditingController();
  final currentBalanceCtrl = TextEditingController();
  final loyaltyCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String _selectedStatus = "ACTIVE";

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    nameCtrl = TextEditingController(
      text: _capitalizeFirstLetter(c.customerName),
    );
    phoneCtrl = TextEditingController(text: c.phone);
    altPhoneCtrl = TextEditingController(text: c.alternatePhone);
    emailCtrl = TextEditingController(text: c.email);
    gstCtrl = TextEditingController(text: c.gstNumber);
    addressCtrl = TextEditingController(text: c.address);
    cityCtrl.text = c.city;
    stateCtrl.text = c.state;
    countryCtrl.text = c.country;
    postalCtrl.text = c.postalCode;
    // Reflects live authoritative balance from backend sales & invoice splits
    currentBalanceCtrl.text = c.currentBalance.toStringAsFixed(2);
    loyaltyCtrl.text = c.loyaltyPoints.toString();
    notesCtrl.text = c.notes;
    _selectedStatus = c.status;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    altPhoneCtrl.dispose();
    emailCtrl.dispose();
    gstCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    countryCtrl.dispose();
    postalCtrl.dispose();
    currentBalanceCtrl.dispose();
    loyaltyCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
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

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool required = false,
    bool readOnly = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
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
        ),
        SizedBox(height: R.sp(context, AppSpacing.xs + 2)),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: R.fs(context, 14),
            color: readOnly
                ? AppColors.textSecondary
                : AppColors.textPrimaryDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: R.fs(context, 13),
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(
              icon,
              size: R.icon(context, AppSizes.iconSm + 2),
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade50 : AppColors.card,
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
              borderSide: BorderSide(
                color: readOnly ? AppColors.border : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _update() async {
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;

    final updatedModel = CustomerModel(
      id: widget.customer.id,
      customerCode: widget.customer.customerCode,
      customerName: _capitalizeFirstLetter(nameCtrl.text.trim()),
      phone: phoneCtrl.text.trim(),
      alternatePhone: altPhoneCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      gstNumber: gstCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      state: stateCtrl.text.trim(),
      country: countryCtrl.text.trim(),
      postalCode: postalCtrl.text.trim(),
      openingBalance: widget.customer.openingBalance,
      // Maintain backend ledger current balance truth from invoice/payment state
      currentBalance: widget.customer.currentBalance,
      loyaltyPoints:
          int.tryParse(loyaltyCtrl.text.trim()) ??
          widget.customer.loyaltyPoints,
      notes: notesCtrl.text.trim(),
      status: _selectedStatus,
    );

    final success = await ref
        .read(customerOperationsProvider.notifier)
        .modifyCustomer(updatedModel);
    if (success && mounted) {
      ref.invalidate(rawCustomersProvider);
      ref.invalidate(customerDashboardSummaryProvider);
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(
          "Delete Account",
          style: TextStyle(
            fontSize: R.fs(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this profile?",
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
    if (confirm == true && widget.customer.id != null) {
      final ok = await ref
          .read(customerOperationsProvider.notifier)
          .deleteCustomer(widget.customer.id!);
      if (ok && mounted) {
        ref.invalidate(rawCustomersProvider);
        ref.invalidate(customerDashboardSummaryProvider);
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: R
                  .hPad(context, base: AppSpacing.screenPadding)
                  .copyWith(
                    top: R.sp(context, AppSpacing.lg),
                    bottom: R.sp(context, AppSpacing.md),
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
                      "Customer Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                        fontSize: R.fs(context, 18),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.textPrimaryDark,
                      size: R.icon(context, 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: R
                    .hPad(context, base: AppSpacing.screenPadding)
                    .copyWith(bottom: R.sp(context, AppSpacing.lg)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionCard(
                      title: "Personal Details",
                      icon: Icons.person_rounded,
                      children: [
                        _field(
                          label: "Customer Name",
                          hint: "Enter name",
                          icon: Icons.person_outline,
                          controller: nameCtrl,
                          required: true,
                        ),
                        _gapV(AppSpacing.md + 2),
                        _field(
                          label: "Contact Number",
                          hint: "98xxxxxx21",
                          icon: Icons.phone_outlined,
                          controller: phoneCtrl,
                          required: true,
                          keyboard: TextInputType.phone,
                        ),
                        _gapV(AppSpacing.md + 2),
                        _field(
                          label: "Alternate Contact",
                          hint: "Enter secondary contact number",
                          icon: Icons.phone_iphone,
                          controller: altPhoneCtrl,
                          keyboard: TextInputType.phone,
                        ),
                        _gapV(AppSpacing.md + 2),
                        _field(
                          label: "Email Address",
                          hint: "example@mail.com",
                          icon: Icons.mail_outline,
                          controller: emailCtrl,
                          keyboard: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                    _sectionCard(
                      title: "Business & Financial",
                      icon: Icons.account_balance_wallet_rounded,
                      children: [
                        _field(
                          label: "GSTIN",
                          hint: "Enter valid GSTIN",
                          icon: Icons.assignment_ind_outlined,
                          controller: gstCtrl,
                        ),
                        _gapV(AppSpacing.md + 2),
                        _fieldRow(
                          _field(
                            label: "Current Balance (Due)",
                            hint: "0.00",
                            icon: Icons.account_balance,
                            controller: currentBalanceCtrl,
                            readOnly:
                                true, // Managed by invoice split/payments backend
                            keyboard: TextInputType.number,
                          ),
                          _field(
                            label: "Loyalty Points",
                            hint: "0",
                            icon: Icons.star_border,
                            controller: loyaltyCtrl,
                            keyboard: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _sectionCard(
                      title: "Address",
                      icon: Icons.pin_drop_rounded,
                      children: [
                        _field(
                          label: "Address Line",
                          hint:
                              "Enter full address (street, city, state, country, PIN)",
                          icon: Icons.location_on_outlined,
                          controller: addressCtrl,
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
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(
                R.radius(context, AppSizes.radiusMd + 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    R.radius(context, AppSizes.radiusMd + 2),
                  ),
                ),
              ),
              child: Text(
                "Update Customer Details",
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
