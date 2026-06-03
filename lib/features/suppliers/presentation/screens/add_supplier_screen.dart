import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/add_supplier_provider.dart';

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
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 13,
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

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,

          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13),

            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),

            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
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
          text: const TextSpan(
            text: "Product Category",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            children: [
              TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: ref.watch(selectedSupplierCategoryProvider),

          decoration: InputDecoration(
            hintText: "Select category",

            prefixIcon: Icon(
              Icons.category_outlined,
              color: Colors.grey.shade500,
              size: 20,
            ),

            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),

          items: categories.map((e) {
            return DropdownMenuItem(value: e, child: Text(e));
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
      category: selectedCategory ?? "",
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
    final selectedCategory = ref.watch(selectedSupplierCategoryProvider);
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Add New Suppliers",

          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),

          child: Column(
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

              const SizedBox(height: 18),

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

              const SizedBox(height: 18),

              // =========================
              // COMPANY NAME
              // =========================
              buildField(
                title: "Company Name",
                hint: "Enter company name",
                icon: Icons.business_outlined,
                controller: companyCtrl,
              ),

              const SizedBox(height: 18),

              // =========================
              // GST
              // =========================
              buildField(
                title: "GST Number (Optional)",
                hint: "Enter GST number",
                icon: Icons.percent,
                controller: gstCtrl,
              ),

              const SizedBox(height: 18),

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

              const SizedBox(height: 18),

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

              const SizedBox(height: 18),

              // =========================
              // CATEGORY
              // =========================
              buildCategoryDropdown(),

              const SizedBox(height: 28),

              // =========================
              // BUTTONS
              // =========================
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,

                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),

                          side: BorderSide(color: Colors.grey.shade300),
                        ),

                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: SizedBox(
                      height: 52,

                      child: ElevatedButton.icon(
                        onPressed: saveSupplier,

                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.primary,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        icon: const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 18,
                        ),

                        label: const Text(
                          "Save Supplier",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
