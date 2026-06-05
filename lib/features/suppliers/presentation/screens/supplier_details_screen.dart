import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/storage/db_helper.dart';

class SupplierDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailsScreen> createState() =>
      _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends ConsumerState<SupplierDetailsScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController contactCtrl;

  String? selectedCategory;

  final categories = [
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

  @override
  void initState() {
    super.initState();

    nameCtrl = TextEditingController(text: widget.supplier["supplierName"]);

    contactCtrl = TextEditingController(text: widget.supplier["contactNumber"]);

    selectedCategory = widget.supplier["category"];
  }

  Future<void> updateSupplier() async {
    await DBHelper.updateSupplier(
      id: widget.supplier["id"],
      supplierName: nameCtrl.text.trim(),
      contactNumber: contactCtrl.text.trim(),
      category: selectedCategory ?? "",
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Supplier Updated")));

      Navigator.pop(context, true);
    }
  }

  Future<void> deleteSupplier() async {
    await DBHelper.deleteSupplier(widget.supplier["id"]);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,

        title: const Text(
          "Supplier Details",
          style: TextStyle(color: Colors.white),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),

            onPressed: () async {
              final confirm = await showDialog(
                context: context,

                builder: (_) => AlertDialog(
                  title: const Text("Delete Supplier"),
                  content: const Text("Are you sure?"),

                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text("Cancel"),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                deleteSupplier();
              }
            },
          ),
        ],
      ),

      body: Container(
        color: AppColors.primary,

        child: ClipRRect(
          borderRadius: AppCurve.top(context),

          child: Container(
            color: Colors.grey.shade100,

            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,

                  decoration: const InputDecoration(labelText: "Supplier Name"),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: contactCtrl,

                  decoration: const InputDecoration(
                    labelText: "Contact Number",
                  ),
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: selectedCategory,

                  items: categories.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },

                  decoration: const InputDecoration(labelText: "Category"),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed: updateSupplier,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),

                    child: const Text(
                      "Update Supplier",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
