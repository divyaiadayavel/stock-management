import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../../core/constants/app_curve.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  ConsumerState<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends ConsumerState<AddSupplierScreen> {
  final companyCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  // Multi-select categories
  final List<String> _allCategories = [
    "Electronics",
    "Mobile",
    "Accessories",
    "Fashion",
    "Grocery",
    "Stationery",
    "Food",
    "Beauty",
    "Furniture",
    "Medical",
    "Sports",
    "Hardware",
    "Home Appliances",
    "Books",
    "Toys",
    "Footwear",
    "FMCG",
    "Dairy",
    "Beverages",
    "Lighting",
  ];

  final List<String> _paymentTerms = [
    "Immediate",
    "Net 7",
    "Net 15",
    "Net 30",
    "Net 45",
    "Net 60",
    "Net 90",
  ];

  Set<String> _selectedCategories = {};
  String? _selectedPaymentTerm;

  // ── Text field builder ───────────────────────────────────────
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
          color: AppColors.textSecondary,
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

  // ── Multi-select category picker ─────────────────────────────
  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                          fontWeight: FontWeight.w600,
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
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(
                    height: 300,
                    child: ListView(
                      children: _allCategories.map((cat) {
                        final selected = _selectedCategories.contains(cat);
                        return CheckboxListTile(
                          value: selected,
                          activeColor: AppColors.primary,
                          dense: true,
                          title: Text(
                            cat,
                            style: TextStyle(fontSize: R.fs(context, 14)),
                          ),
                          onChanged: (val) {
                            setModal(() {
                              if (val == true) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
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

  Widget _categoryField() {
    final display = _selectedCategories.isEmpty
        ? null
        : _selectedCategories.join(", ");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Categories"),
        SizedBox(height: R.sp(context, 6)),
        GestureDetector(
          onTap: _showCategoryPicker,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: R.sp(context, 14),
              vertical: R.sp(context, 13),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: R.icon(context, 18),
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: R.sp(context, 8)),
                Expanded(
                  child: Text(
                    display ?? "Select categories",
                    style: TextStyle(
                      fontSize: R.fs(context, 13),
                      color: display != null
                          ? AppColors.textPrimaryDark
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: R.icon(context, 18),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        // Selected chips
        if (_selectedCategories.isNotEmpty) ...[
          SizedBox(height: R.sp(context, 8)),
          Wrap(
            spacing: R.sp(context, 6),
            runSpacing: R.sp(context, 6),
            children: _selectedCategories.map((cat) {
              return Chip(
                label: Text(cat, style: TextStyle(fontSize: R.fs(context, 11))),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  setState(() => _selectedCategories.remove(cat));
                },
                backgroundColor: AppColors.primary.withOpacity(0.08),
                labelStyle: const TextStyle(color: AppColors.primary),
                deleteIconColor: AppColors.primary,
                side: const BorderSide(color: Colors.transparent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(horizontal: R.sp(context, 4)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _paymentTermsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Payment terms"),
        SizedBox(height: R.sp(context, 6)),
        DropdownButtonFormField<String>(
          value: _selectedPaymentTerm,
          isExpanded: true,
          menuMaxHeight: 250,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(
            fontSize: R.fs(context, 13),
            color: AppColors.textPrimaryDark,
          ),
          decoration: _inputDeco(
            hint: "Select terms",
            icon: Icons.receipt_long_outlined,
          ),
          items: _paymentTerms
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: TextStyle(fontSize: R.fs(context, 13))),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedPaymentTerm = v),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (companyCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Company name and phone are required")),
      );
      return;
    }

    await DBHelper.addSupplier(
      supplierName: contactCtrl.text.trim().isNotEmpty
          ? contactCtrl.text.trim()
          : companyCtrl.text.trim(),
      companyName: companyCtrl.text.trim(),
      contactNumber: phoneCtrl.text.trim(),
      email: "",
      category: _selectedCategories.join(", "),
      gst: gstCtrl.text.trim(),
      address: addressCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Supplier added successfully")),
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
                    "Add supplier",
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
            // Company name (full width)
            _field(
              label: "Company name",
              hint: "Enter the Company Name",
              icon: Icons.business_outlined,
              controller: companyCtrl,
              required: true,
            ),

            SizedBox(height: R.sp(context, 16)),

            // Contact + Phone (side by side)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    label: "Contact",
                    hint: "Supplier Name",
                    icon: Icons.person_outline,
                    controller: contactCtrl,
                  ),
                ),
                SizedBox(width: R.sp(context, 12)),
                Expanded(
                  child: _field(
                    label: "Phone",
                    hint: "98xxxxxx21",
                    icon: Icons.phone_outlined,
                    controller: phoneCtrl,
                    required: true,
                    keyboard: TextInputType.phone,
                  ),
                ),
              ],
            ),

            SizedBox(height: R.sp(context, 16)),

            // GSTIN
            _field(
              label: "GSTIN",
              hint: "33ABCDE1234F1Z5",
              icon: Icons.percent,
              controller: gstCtrl,
            ),

            SizedBox(height: R.sp(context, 16)),

            // Categories + Payment terms (side by side)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _categoryField()),
                SizedBox(width: R.sp(context, 12)),
                Expanded(child: _paymentTermsField()),
              ],
            ),

            SizedBox(height: R.sp(context, 16)),

            // Address
            _field(
              label: "Address",
              hint: "Street, city, PIN",
              icon: Icons.location_on_outlined,
              controller: addressCtrl,
              maxLines: 3,
            ),
          ],
        ),
      ),

      // ── Bottom buttons ─────────────────────────────────────
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
                        color: AppColors.textSecondary,
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
                        "Save supplier",
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
