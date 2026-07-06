import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart';

class SupplierDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailsScreen> createState() =>
      _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends ConsumerState<SupplierDetailsScreen> {
  late TextEditingController companyCtrl;
  late TextEditingController contactCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController gstCtrl;
  late TextEditingController addressCtrl;

  Set<String> _selectedCategories = {};
  String? _selectedPaymentTerm;

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

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    companyCtrl = TextEditingController(
      text: s["companyName"] ?? s["supplierName"] ?? "",
    );
    contactCtrl = TextEditingController(text: s["supplierName"] ?? "");
    phoneCtrl = TextEditingController(text: s["contactNumber"] ?? "");
    gstCtrl = TextEditingController(text: s["gst"] ?? "");
    addressCtrl = TextEditingController(text: s["address"] ?? "");

    // Parse stored multi-category string
    final catStr = (s["category"] as String?) ?? "";
    if (catStr.isNotEmpty) {
      _selectedCategories = catStr.split(",").map((c) => c.trim()).toSet();
    }

    // ✅ THE FIX IS HERE
    String? loadedPaymentTerm = s["paymentTerms"] as String?;

    // If it's an empty string or a value that doesn't exist in our list, make it null
    if (loadedPaymentTerm != null &&
        !_paymentTerms.contains(loadedPaymentTerm)) {
      loadedPaymentTerm = null;
    }

    _selectedPaymentTerm = loadedPaymentTerm;
  }

  // ── helpers ─────────────────────────────────────────────────
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
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.brandGradient.createShader(bounds),
                          child: const Text(
                            "Done",
                            style: TextStyle(color: AppColors.primary),
                          ),
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
        Text(
          "Categories",
          style: TextStyle(
            fontSize: R.fs(context, 12),
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
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
        if (_selectedCategories.isNotEmpty) ...[
          SizedBox(height: R.sp(context, 8)),
          Wrap(
            spacing: R.sp(context, 6),
            runSpacing: R.sp(context, 6),
            children: _selectedCategories.map((cat) {
              return Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, 12),
                    vertical: R.sp(context, 6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: R.fs(context, 11),
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: R.sp(context, 6)),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategories.remove(cat)),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _update() async {
    // 🆕  uses updateSupplierFull instead of updateSupplier
    //      so paymentTerms is persisted to the DB
    await DBHelper.updateSupplierFull(
      id: widget.supplier["id"],
      supplierName: contactCtrl.text.trim().isNotEmpty
          ? contactCtrl.text.trim()
          : companyCtrl.text.trim(),
      contactNumber: phoneCtrl.text.trim(),
      category: _selectedCategories.join(", "),
      paymentTerms: _selectedPaymentTerm ?? '',
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Supplier updated")));
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Supplier",
          style: TextStyle(
            fontSize: R.fs(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this supplier?",
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
      await DBHelper.deleteSupplier(widget.supplier["id"]);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.supplier["supplierName"] ?? "";
    final parts = name.trim().split(" ");
    final initials = parts.length >= 2
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : name.isNotEmpty
        ? name[0].toUpperCase()
        : "?";

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
                    "Supplier Details",
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
                  if (_selectedCategories.isNotEmpty)
                    Text(
                      _selectedCategories.join(", "),
                      style: TextStyle(
                        fontSize: R.fs(context, 12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: R.sp(context, 24)),

            // Company name
            _textField(
              controller: companyCtrl,
              label: "Company name",
              icon: Icons.business_outlined,
            ),

            SizedBox(height: R.sp(context, 16)),

            // Contact + Phone
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _textField(
                    controller: contactCtrl,
                    label: "Contact",
                    icon: Icons.person_outline,
                  ),
                ),
                SizedBox(width: R.sp(context, 12)),
                Expanded(
                  child: _textField(
                    controller: phoneCtrl,
                    label: "Phone",
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                ),
              ],
            ),

            SizedBox(height: R.sp(context, 16)),

            // GSTIN
            _textField(
              controller: gstCtrl,
              label: "GSTIN",
              icon: Icons.percent,
            ),

            SizedBox(height: R.sp(context, 16)),

            // Categories + Payment terms
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _categoryField()),
                SizedBox(width: R.sp(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment terms",
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
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
                        decoration: InputDecoration(
                          hintText: "Select terms",
                          hintStyle: TextStyle(
                            fontSize: R.fs(context, 13),
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.receipt_long_outlined,
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
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              R.radius(context, 10),
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
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
                        items: _paymentTerms
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t,
                                  style: TextStyle(fontSize: R.fs(context, 13)),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedPaymentTerm = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: R.sp(context, 16)),

            // Address
            _textField(
              controller: addressCtrl,
              label: "Address",
              icon: Icons.location_on_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),

      // ── Bottom button ─────────────────────────────────────
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
                  "Update supplier",
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
