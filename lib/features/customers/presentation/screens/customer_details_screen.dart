import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';

class CustomerDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailsScreen> createState() =>
      _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends ConsumerState<CustomerDetailsScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addressCtrl; // Added address controller

  final List<String> _genders = ["Male", "Female", "Other"];
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    nameCtrl = TextEditingController(text: c["name"] ?? "");
    phoneCtrl = TextEditingController(text: c["phone"] ?? "");
    addressCtrl = TextEditingController(
      text: c["address"] ?? "",
    ); // Initialized address text

    String? loadedGender = c["gender"] as String?;
    if (loadedGender != null && !_genders.contains(loadedGender)) {
      loadedGender = null;
    }
    _selectedGender = loadedGender;
  }

  InputDecoration _inputDeco({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: R.fs(context, 12),
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: icon != null
          ? Icon(
              icon,
              size: R.icon(context, 18),
              color: AppColors.textSecondary,
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: EdgeInsets.symmetric(
        horizontal: R.sp(context, 14),
        vertical: R.sp(context, 13),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: R.fs(context, 14),
        color: AppColors.textPrimaryDark,
      ),
      decoration: _inputDeco(label: label, icon: icon),
    );
  }

  Future<void> _update() async {
    final nameText = nameCtrl.text.trim();
    final phoneText = phoneCtrl.text.trim();

    // 1. Separate error message for Customer Name
    if (nameText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer name is required")),
      );
      return;
    }

    // 2. Separate error message for Contact Number missing
    if (phoneText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact number is required")),
      );
      return;
    }

    // 3. Separate error message for invalid 10-digit phone number format
    if (!RegExp(r'^\d{10}$').hasMatch(phoneText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 10-digit phone number")),
      );
      return;
    }

    // 4. Separate error message for missing Gender selection
    if (_selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gender is required")));
      return;
    }

    await DBHelper.updateCustomerFull(
      id: widget.customer["id"],
      name: nameText,
      phone: phoneText,
      gender: _selectedGender!,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Customer updated")));
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Customer",
          style: TextStyle(
            fontSize: R.fs(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this customer?",
          style: TextStyle(fontSize: R.fs(context, 13)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontSize: R.fs(context, 14),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              "Delete",
              style: TextStyle(fontSize: R.fs(context, 14)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.deleteCustomerById(widget.customer["id"]);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.customer["name"] ?? "";
    final parts = name.trim().split(" ");
    final initials = parts.length >= 2
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : "?";

    final int billsCount =
        (widget.customer["billsCount"] as num?)?.toInt() ?? 0;
    final double dueAmount =
        (widget.customer["dueAmount"] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: R
            .hPad(context, base: 18)
            .copyWith(top: R.sp(context, 40), bottom: R.sp(context, 120)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Expanded(
                  child: Text(
                    "Customer Details",
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: R.fs(context, 18),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.red,
                    size: R.icon(context, 22),
                  ),
                  onPressed: _delete,
                ),
              ],
            ),
            SizedBox(height: R.sp(context, 20)),
            // ── Avatar header ──────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: R.fluid(context, 64, 80),
                    height: R.fluid(context, 64, 80),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: R.fs(context, 22),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: R.sp(context, 8)),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: R.fs(context, 16),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    "$billsCount bill${billsCount == 1 ? '' : 's'} · ${dueAmount > 0 ? 'due ₹${dueAmount.toStringAsFixed(0)}' : 'settled'}",
                    style: TextStyle(
                      fontSize: R.fs(context, 12),
                      color: dueAmount > 0 ? AppColors.orange : AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: R.sp(context, 24)),
            _textField(
              controller: nameCtrl,
              label: "Customer name",
              icon: Icons.person_outline,
            ),
            SizedBox(height: R.sp(context, 16)),
            _textField(
              controller: phoneCtrl,
              label: "Contact number",
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),
            SizedBox(height: R.sp(context, 16)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Gender",
                  style: TextStyle(
                    fontSize: R.fs(context, 12),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: R.sp(context, 6)),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  style: TextStyle(
                    fontSize: R.fs(context, 13),
                    color: AppColors.textPrimaryDark,
                  ),
                  decoration: InputDecoration(
                    hintText: "Select gender",
                    hintStyle: TextStyle(
                      fontSize: R.fs(context, 13),
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.wc_outlined,
                      size: R.icon(context, 18),
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 14),
                      vertical: R.sp(context, 13),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: _genders
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(
                            g,
                            style: TextStyle(fontSize: R.fs(context, 13)),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ],
            ),
            SizedBox(height: R.sp(context, 16)),
            // Optional Address field segment included below
            _textField(
              controller: addressCtrl,
              label: "Address",
              icon: Icons.location_on_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: R
              .hPad(context, base: 18)
              .copyWith(top: R.sp(context, 12), bottom: R.sp(context, 12)),
          child: SizedBox(
            width: double.infinity,
            height: R.btnH(context),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(R.radius(context, 10)),
              ),
              child: ElevatedButton(
                onPressed: _update,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  ),
                ),
                child: Text(
                  "Update customer",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: R.fs(context, 14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
