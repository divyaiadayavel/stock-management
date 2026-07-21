import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../data/models/customer_model.dart';
import '../provider/customer_provider.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

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
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final countryCtrl = TextEditingController(text: "India");
  final postalCtrl = TextEditingController();
  final openBalanceCtrl = TextEditingController(text: "0");
  final notesCtrl = TextEditingController();

  final List<String> statuses = ["ACTIVE", "INACTIVE"];
  String _selectedStatus = "ACTIVE";

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
    openBalanceCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  // ── Section header used inside a card ──
  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(R.sp(context, AppSpacing.xs + 2)),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusSm + 4)),
          ),
          child: Icon(icon, size: R.icon(context, AppSizes.iconSm), color: AppColors.primary),
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

  // ── Card wrapper that groups related fields with consistent spacing ──
  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: R.sp(context, AppSpacing.lg)),
      padding: EdgeInsets.all(R.sp(context, AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusLg)),
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

  Widget _gapV([double size = AppSpacing.md]) => SizedBox(height: R.sp(context, size));

  // Consistent two-column row with even spacing
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
            children: required ? const [TextSpan(text: " *", style: TextStyle(color: AppColors.red))] : [],
          ),
        ),
        SizedBox(height: R.sp(context, AppSpacing.xs + 2)),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: TextStyle(fontSize: R.fs(context, 14), color: AppColors.textPrimaryDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: R.fs(context, 13), color: AppColors.textSecondary.withValues(alpha: 0.7)),
            prefixIcon: Icon(icon, size: R.icon(context, AppSizes.iconSm + 2), color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: EdgeInsets.symmetric(
              horizontal: R.sp(context, AppSpacing.md + 2),
              vertical: R.sp(context, AppSpacing.md),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer name is required")));
      return;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact number is required")));
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phoneCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a valid 10-digit phone number")));
      return;
    }

    final double openingBal = double.tryParse(openBalanceCtrl.text.trim()) ?? 0.00;

    final customerData = CustomerModel(
      customerCode: "",
      customerName: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      alternatePhone: altPhoneCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      gstNumber: gstCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      state: stateCtrl.text.trim(),
      country: countryCtrl.text.trim(),
      postalCode: postalCtrl.text.trim(),
      openingBalance: openingBal,
      currentBalance: openingBal,
      loyaltyPoints: 0,
      notes: notesCtrl.text.trim(),
      status: _selectedStatus,
    );

    final success = await ref.read(customerOperationsProvider.notifier).addCustomer(customerData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer profile created successfully.")));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: R.hPad(context, base: AppSpacing.screenPadding).copyWith(
            top: R.sp(context, AppSpacing.lg),
            bottom: R.sp(context, 120),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──
              Row(
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
                      "Add Customer",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                        fontSize: R.fs(context, 18),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: R.sp(context, AppSpacing.xl)),

              // ── Personal Details ──
              _sectionCard(
                title: "Personal Details",
                icon: Icons.person_rounded,
                children: [
                  _field(label: "Customer Name", hint: "Enter name", icon: Icons.person_outline, controller: nameCtrl, required: true),
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
                    label: "Alternate Phone",
                    hint: "Enter secondary contact number",
                    icon: Icons.phone_android_outlined,
                    controller: altPhoneCtrl,
                    keyboard: TextInputType.phone,
                  ),
                  _gapV(AppSpacing.md + 2),
                  _field(
                    label: "Email Address",
                    hint: "example@mail.com",
                    icon: Icons.email_outlined,
                    controller: emailCtrl,
                    keyboard: TextInputType.emailAddress,
                  ),
                ],
              ),

              // ── Business & Financial ──
              _sectionCard(
                title: "Business & Financial",
                icon: Icons.account_balance_wallet_rounded,
                children: [
                  _field(label: "GST Number", hint: "Enter valid GSTIN", icon: Icons.receipt_long_outlined, controller: gstCtrl),
                  _gapV(AppSpacing.md + 2),
                  _field(
                    label: "Opening Balance",
                    hint: "0.00",
                    icon: Icons.account_balance_wallet_outlined,
                    controller: openBalanceCtrl,
                    keyboard: TextInputType.number,
                  ),
                ],
              ),

              // ── Address ──
              _sectionCard(
                title: "Address",
                icon: Icons.pin_drop_rounded,
                children: [
                  _field(label: "Address Line", hint: "Street details", icon: Icons.location_on_outlined, controller: addressCtrl, maxLines: 2),
                  _gapV(AppSpacing.md + 2),
                  _fieldRow(
                    _field(label: "City", hint: "City", icon: Icons.location_city, controller: cityCtrl),
                    _field(label: "State", hint: "State", icon: Icons.map_outlined, controller: stateCtrl),
                  ),
                  _gapV(AppSpacing.md + 2),
                  _fieldRow(
                    _field(label: "Country", hint: "Country", icon: Icons.public, controller: countryCtrl),
                    _field(label: "Postal Code", hint: "PIN", icon: Icons.pin_drop_outlined, controller: postalCtrl, keyboard: TextInputType.number),
                  ),
                ],
              ),

              // ── Notes & Status ──
              _sectionCard(
                title: "Notes & Status",
                icon: Icons.fact_check_rounded,
                children: [
                  _field(label: "Internal Notes", hint: "Add comments...", icon: Icons.note_alt_outlined, controller: notesCtrl, maxLines: 3),
                  _gapV(AppSpacing.md + 2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Account Status",
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryDark.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(height: R.sp(context, AppSpacing.xs + 2)),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        isExpanded: true,
                        dropdownColor: AppColors.card,
                        borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                        style: TextStyle(fontSize: R.fs(context, 13), color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          hintText: "Select status",
                          hintStyle: TextStyle(fontSize: R.fs(context, 13), color: AppColors.textSecondary.withValues(alpha: 0.7)),
                          prefixIcon: Icon(Icons.shield_outlined, size: R.icon(context, AppSizes.iconSm + 2), color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: R.sp(context, AppSpacing.md + 2),
                            vertical: R.sp(context, AppSpacing.md),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        items: statuses
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, style: TextStyle(fontSize: R.fs(context, 13), fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedStatus = val!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
        ),
        padding: EdgeInsets.only(
          left: R.sp(context, AppSpacing.screenPadding + 2),
          right: R.sp(context, AppSpacing.screenPadding + 2),
          top: R.sp(context, AppSpacing.md),
          bottom: R.sp(context, AppSpacing.md) + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: R.btnH(context),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd + 2))),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: R.fs(context, 14)),
                  ),
                ),
              ),
            ),
            SizedBox(width: R.sp(context, AppSpacing.md)),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: R.btnH(context),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd + 2)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd + 2))),
                    ),
                    child: Text(
                      "Save Customer",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: R.fs(context, 14)),
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