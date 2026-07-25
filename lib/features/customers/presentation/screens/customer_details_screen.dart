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
  ConsumerState<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
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

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    nameCtrl = TextEditingController(text: c.customerName);
    phoneCtrl = TextEditingController(text: c.phone);
    altPhoneCtrl = TextEditingController(text: c.alternatePhone);
    emailCtrl = TextEditingController(text: c.email);
    gstCtrl = TextEditingController(text: c.gstNumber);
    addressCtrl = TextEditingController(text: c.address);
    cityCtrl.text = c.city;
    stateCtrl.text = c.state;
    countryCtrl.text = c.country;
    postalCtrl.text = c.postalCode;
    currentBalanceCtrl.text = c.currentBalance.toStringAsFixed(0);
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType k = TextInputType.text,
    int lines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: k,
      maxLines: lines,
      style: TextStyle(fontSize: R.fs(context, 14), color: AppColors.textPrimaryDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: R.fs(context, 12), color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, size: R.icon(context, AppSizes.iconSm + 2), color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.card,
        floatingLabelBehavior: FloatingLabelBehavior.always,
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
    );
  }

  Future<void> _update() async {
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;

    final updatedModel = CustomerModel(
      id: widget.customer.id,
      customerCode: widget.customer.customerCode,
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
      openingBalance: widget.customer.openingBalance,
      currentBalance: double.tryParse(currentBalanceCtrl.text.trim()) ?? widget.customer.currentBalance,
      loyaltyPoints: int.tryParse(loyaltyCtrl.text.trim()) ?? widget.customer.loyaltyPoints,
      notes: notesCtrl.text.trim(),
      status: _selectedStatus,
    );

    final success = await ref.read(customerOperationsProvider.notifier).modifyCustomer(updatedModel);
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        title: Text(
          "Delete Account",
          style: TextStyle(fontSize: R.fs(context, 16), fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete this profile?",
          style: TextStyle(fontSize: R.fs(context, 13), color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(fontSize: R.fs(context, 14), color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ),
            child: Text("Delete", style: TextStyle(fontSize: R.fs(context, 14), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true && widget.customer.id != null) {
      final ok = await ref.read(customerOperationsProvider.notifier).deleteCustomer(widget.customer.id!);
      if (ok && mounted) Navigator.pop(context, true);
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
                      "Customer Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                        fontSize: R.fs(context, 18),
                      ),
                    ),
                  ),
                  // ── Delete: plain black outlined icon, no red badge ──
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
              SizedBox(height: R.sp(context, AppSpacing.xl)),

              // ── Personal Details ──
              _sectionCard(
                title: "Personal Details",
                icon: Icons.person_rounded,
                children: [
                  _textField(controller: nameCtrl, label: "Customer Name", icon: Icons.person_outline),
                  _gapV(AppSpacing.md + 2),
                  _textField(controller: phoneCtrl, label: "Contact Number", icon: Icons.phone_outlined, k: TextInputType.phone),
                  _gapV(AppSpacing.md + 2),
                  _textField(controller: altPhoneCtrl, label: "Alternate Contact", icon: Icons.phone_iphone, k: TextInputType.phone),
                  _gapV(AppSpacing.md + 2),
                  _textField(controller: emailCtrl, label: "Email Address", icon: Icons.mail_outline, k: TextInputType.emailAddress),
                ],
              ),

              // ── Business & Financial ──
              _sectionCard(
                title: "Business & Financial",
                icon: Icons.account_balance_wallet_rounded,
                children: [
                  _textField(controller: gstCtrl, label: "GSTIN", icon: Icons.assignment_ind_outlined),
                  _gapV(AppSpacing.md + 2),
                  _fieldRow(
                    _textField(controller: currentBalanceCtrl, label: "Current Balance", icon: Icons.account_balance, k: TextInputType.number),
                    _textField(controller: loyaltyCtrl, label: "Loyalty Points", icon: Icons.star_border, k: TextInputType.number),
                  ),
                ],
              ),

              // ── Address ──
              _sectionCard(
                title: "Address",
                icon: Icons.pin_drop_rounded,
                children: [
                  _textField(controller: addressCtrl, label: "Address Line", icon: Icons.location_on_outlined, lines: 2),
                  _gapV(AppSpacing.md + 2),
                  _fieldRow(
                    _textField(controller: cityCtrl, label: "City", icon: Icons.location_city),
                    _textField(controller: stateCtrl, label: "State", icon: Icons.map_outlined),
                  ),
                ],
              ),

              // ── Notes & Status ──
              _sectionCard(
                title: "Notes & Status",
                icon: Icons.fact_check_rounded,
                children: [
                  _textField(controller: notesCtrl, label: "Internal Notes", icon: Icons.edit_note, lines: 3),
                  _gapV(AppSpacing.md + 2),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    isExpanded: true,
                    dropdownColor: AppColors.card,
                    borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd)),
                    style: TextStyle(fontSize: R.fs(context, 13), color: AppColors.textPrimaryDark),
                    decoration: InputDecoration(
                      labelText: "Status",
                      labelStyle: TextStyle(fontSize: R.fs(context, 12), color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      prefixIcon: Icon(Icons.check_circle_outline, size: R.icon(context, AppSizes.iconSm + 2), color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.card,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
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
                    items: ["ACTIVE", "INACTIVE"]
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
        child: SizedBox(
          width: double.infinity,
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
              onPressed: _update,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.radius(context, AppSizes.radiusMd + 2))),
              ),
              child: Text(
                "Update Customer Details",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: R.fs(context, 14)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}