import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController(); // Added address controller

  final List<String> _genders = ["Male", "Female", "Other"];
  String? _selectedGender;

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
        _label(label, required: required),
        SizedBox(height: R.sp(context, 6)),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: R.fs(context, 14),
            color: AppColors.textPrimaryDark,
          ),
          decoration: _inputDeco(hint: hint, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: R.fs(context, 13),
        color: AppColors.textSecondary,
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

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: R.fs(context, 12),
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
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

  Widget _genderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Gender", required: true),
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
          decoration: _inputDeco(
            hint: "Select gender",
            icon: Icons.wc_outlined,
          ),
          items: _genders
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(g, style: TextStyle(fontSize: R.fs(context, 13))),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedGender = v),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final nameText = nameCtrl.text.trim();
    final phoneText = phoneCtrl.text.trim();

    // 1. Separate error message for Customer Name
    if (nameText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer name is required")),
      );
      return;
    }

    // 2. Separate error message for Contact Number
    if (phoneText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact number is required")),
      );
      return;
    }

    // 3. Separate error message for invalid 10-digit phone number structure
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

    // Note: If your local DB layer does not accept the dynamic address argument yet,
    // you can pass addressCtrl.text.trim() here if the model supports it.
    await DBHelper.addCustomerFull(
      name: nameText,
      phone: phoneText,
      gender: _selectedGender!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer added successfully")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: R
            .hPad(context, base: 18)
            .copyWith(top: R.sp(context, 40), bottom: R.sp(context, 120)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ROW ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.transparent,
                    // 1. Force the left padding to zero
                    padding: EdgeInsets.only(
                      left: 0,
                      right: R.sp(context, 12),
                      top: R.sp(context, 8),
                      bottom: R.sp(context, 8),
                    ),
                    // 2. Wrap the Icon in Transform.translate
                    child: Transform.translate(
                      offset: const Offset(-8.0, 0),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimaryDark,
                        size: R.icon(context, 22),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    "Add customer",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryDark,
                      fontSize: R.fs(context, 18),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: R.sp(context, 20)),
            _field(
              label: "Customer name",
              hint: "Enter customer name",
              icon: Icons.person_outline,
              controller: nameCtrl,
              required: true,
            ),
            SizedBox(height: R.sp(context, 16)),
            _field(
              label: "Contact number",
              hint: "98xxxxxx21",
              icon: Icons.phone_outlined,
              controller: phoneCtrl,
              required: true,
              keyboard: TextInputType.phone,
            ),
            SizedBox(height: R.sp(context, 16)),
            _genderField(),
            SizedBox(height: R.sp(context, 16)),
            // Optional Address field component added here
            _field(
              label: "Address",
              hint: "Street, city, PIN",
              icon: Icons.location_on_outlined,
              controller: addressCtrl,
              maxLines: 3,
              required: false,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: R
              .hPad(context, base: 18)
              .copyWith(top: R.sp(context, 12), bottom: R.sp(context, 12)),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: R.btnH(context),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 10),
                        ),
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                        fontSize: R.fs(context, 14),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: R.sp(context, 12)),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: R.btnH(context),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(
                        R.radius(context, 10),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            R.radius(context, 10),
                          ),
                        ),
                      ),
                      child: Text(
                        "Save customer",
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
            ],
          ),
        ),
      ),
    );
  }
}
