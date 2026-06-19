import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart'; // Ensure this matches your file paths

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
        iconTheme: IconThemeData(
          color: Colors.white,
          size: R.icon(context, 24),
        ),
        title: Text(
          "Supplier Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: R.fs(context, 20),
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Colors.white,
              size: R.icon(context, 24),
            ),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(
                    "Delete Supplier",
                    style: TextStyle(
                      fontSize: R.fs(context, 18),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  content: Text(
                    "Are you sure?",
                    style: TextStyle(fontSize: R.fs(context, 14)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(fontSize: R.fs(context, 14)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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
            child: R.maxW(
              Padding(
                padding: R.hPad(context, base: 20.0),
                child: Column(
                  children: [
                    SizedBox(height: R.sp(context, 20)),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(fontSize: R.fs(context, 14)),
                      decoration: InputDecoration(
                        labelText: "Supplier Name",
                        labelStyle: TextStyle(fontSize: R.fs(context, 14)),
                      ),
                    ),
                    SizedBox(height: R.sp(context, 20)),
                    TextField(
                      controller: contactCtrl,
                      style: TextStyle(fontSize: R.fs(context, 14)),
                      decoration: InputDecoration(
                        labelText: "Contact Number",
                        labelStyle: TextStyle(fontSize: R.fs(context, 14)),
                      ),
                    ),
                    SizedBox(height: R.sp(context, 20)),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      style: TextStyle(
                        fontSize: R.fs(context, 14),
                        color: Colors.black,
                      ),
                      items: categories.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: TextStyle(fontSize: R.fs(context, 14)),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Category",
                        labelStyle: TextStyle(fontSize: R.fs(context, 14)),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: R.btnH(context),
                      child: ElevatedButton(
                        onPressed: updateSupplier,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              R.radius(context, 10),
                            ),
                          ),
                        ),
                        child: Text(
                          "Update Supplier",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: R.fs(context, 16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: R.sp(context, 20)),
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
