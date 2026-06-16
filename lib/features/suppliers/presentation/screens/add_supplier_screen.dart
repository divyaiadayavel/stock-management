import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart'; // Ensure this path matches your directory structure
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/add_supplier_provider.dart';
import '../../../../core/constants/app_curve.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  ConsumerState<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends ConsumerState<AddSupplierScreen> {
  final supplierCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  final List<String> categories = [
    "Groceries",
    "Beverages",
    "Snacks",
    "Personal Care",
    "Stationery",
    "Electronics",
    "Dairy",
    "Bakery",
    "Vegetables",
    "Fruits",
  ];

  // =========================
  // 🔹 INPUT FIELD
  // =========================
  Widget buildField({
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: title,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: R.fs(context, 13),
            ),
            children: requiredField
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),

        SizedBox(height: R.sp(context, 8)),

        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: TextStyle(fontSize: R.fs(context, 14)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: R.fs(context, 13)),

            prefixIcon: Icon(
              icon,
              color: Colors.grey.shade500,
              size: R.icon(context, 20),
            ),

            filled: true,
            fillColor: Colors.white,

            contentPadding: EdgeInsets.symmetric(
              horizontal: R.fluid(context, 14, 18),
              vertical: R.fluid(context, 14, 18),
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // 🔹 CATEGORY DROPDOWN
  // =========================
  Widget buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: "Product Category",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: R.fs(context, 13),
            ),
            children: const [
              TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        SizedBox(height: R.sp(context, 8)),

        DropdownButtonFormField<String>(
          value: ref.watch(selectedSupplierCategoryProvider),
          style: TextStyle(fontSize: R.fs(context, 14), color: Colors.black),
          decoration: InputDecoration(
            hintText: "Select category",
            hintStyle: TextStyle(fontSize: R.fs(context, 13)),

            prefixIcon: Icon(
              Icons.category_outlined,
              color: Colors.grey.shade500,
              size: R.icon(context, 20),
            ),

            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 10)),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),

          items: categories.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e, style: TextStyle(fontSize: R.fs(context, 14))),
            );
          }).toList(),

          onChanged: (value) {
            ref.read(selectedSupplierCategoryProvider.notifier).state = value;
          },
        ),
      ],
    );
  }

  // =========================
  // 🔹 SAVE SUPPLIER
  // =========================
  Future<void> saveSupplier() async {
    final selectedCategory = ref.read(selectedSupplierCategoryProvider);
    if (supplierCtrl.text.trim().isEmpty ||
        contactCtrl.text.trim().isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Supplier name, contact number and category are required",
          ),
        ),
      );
      return;
    }

    await DBHelper.addSupplier(
      supplierName: supplierCtrl.text.trim(),
      companyName: companyCtrl.text.trim(),
      contactNumber: contactCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      category: selectedCategory,
      gst: gstCtrl.text.trim(),
      address: addressCtrl.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Supplier Added Successfully")),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
          size: R.icon(context, 24),
        ),
        title: Text(
          "Add New Suppliers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: R.fs(context, 20),
          ),
        ),
      ),
      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              padding: R.hPad(context, base: 18.0),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: R.sp(context, 18)),
                padding: EdgeInsets.all(R.sp(context, 18)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(R.radius(context, 18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================
                    // SUPPLIER NAME
                    // =========================
                    buildField(
                      title: "Supplier Name",
                      hint: "Enter supplier name",
                      icon: Icons.person_outline,
                      controller: supplierCtrl,
                      requiredField: true,
                    ),

                    SizedBox(height: R.sp(context, 18)),

                    // =========================
                    // EMAIL
                    // =========================
                    buildField(
                      title: "Email Address",
                      hint: "Enter email address",
                      icon: Icons.email_outlined,
                      controller: emailCtrl,
                      keyboard: TextInputType.emailAddress,
                    ),

                    SizedBox(height: R.sp(context, 18)),

                    // =========================
                    // COMPANY NAME
                    // =========================
                    buildField(
                      title: "Company Name",
                      hint: "Enter company name",
                      icon: Icons.business_outlined,
                      controller: companyCtrl,
                    ),

                    SizedBox(height: R.sp(context, 18)),

                    // =========================
                    // GST
                    // =========================
                    buildField(
                      title: "GST Number (Optional)",
                      hint: "Enter GST number",
                      icon: Icons.percent,
                      controller: gstCtrl,
                    ),

                    SizedBox(height: R.sp(context, 18)),

                    // =========================
                    // CONTACT NUMBER
                    // =========================
                    buildField(
                      title: "Contact Number",
                      hint: "Enter contact number",
                      icon: Icons.phone_outlined,
                      controller: contactCtrl,
                      requiredField: true,
                      keyboard: TextInputType.phone,
                    ),

                    SizedBox(height: R.sp(context, 18)),

                    // =========================
                    // ADDRESS
                    // =========================
                    buildField(
                      title: "Address (Optional)",
                      hint: "Enter address",
                      icon: Icons.location_on_outlined,
                      controller: addressCtrl,
                      maxLines: 3,
                    ),

                    SizedBox(height: R.sp(context, 18)),

                    // =========================
                    // CATEGORY
                    // =========================
                    buildCategoryDropdown(),

                    SizedBox(height: R.sp(context, 28)),

                    // =========================
                    // BUTTONS
                    // =========================
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: R.btnH(context),
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(context, 10),
                                  ),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: R.fs(context, 14),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: R.sp(context, 16)),

                        Expanded(
                          child: SizedBox(
                            height: R.btnH(context),
                            child: ElevatedButton.icon(
                              onPressed: saveSupplier,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    R.radius(context, 10),
                                  ),
                                ),
                              ),
                              icon: Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                                size: R.icon(context, 18),
                              ),
                              label: Text(
                                "Save Supplier",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: R.fs(context, 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
