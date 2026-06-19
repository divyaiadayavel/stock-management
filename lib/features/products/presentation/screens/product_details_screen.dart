import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/storage/db_helper.dart'; // Ensure this path is correct
import 'add_product_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_curve.dart';
import '../../../../core/utils/responsive_helper.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // We use a local variable to hold the product data so we can update it
  late Map<String, dynamic> currentProduct;

  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
  }

  // 🔹 REFRESH LOGIC: Fetches the latest data from the DB
  Future<void> refreshProduct() async {
    final updatedData = await DBHelper.getProductById(currentProduct['id']);
    if (updatedData != null) {
      setState(() {
        currentProduct = updatedData;
      });
    }
  }

  // 🔹 UPDATE STOCK POPUP
  void _showUpdateStockDialog() {
    final TextEditingController stockController = TextEditingController(
      text: "1",
    );
    bool isAdding = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Update Stock"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Current Stock: ${currentProduct['quantity']}"),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus Button
                      IconButton(
                        onPressed: () => setDialogState(() => isAdding = false),
                        icon: Icon(
                          Icons.remove_circle,
                          color: !isAdding ? Colors.red : Colors.grey,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Input Field
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Plus Button
                      IconButton(
                        onPressed: () => setDialogState(() => isAdding = true),
                        icon: Icon(
                          Icons.add_circle,
                          color: isAdding ? Colors.green : Colors.grey,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAdding
                        ? "Action: Add to Stock"
                        : "Action: Remove from Stock",
                    style: TextStyle(
                      color: isAdding ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    int amount = int.tryParse(stockController.text) ?? 0;
                    if (amount > 0) {
                      int finalChange = isAdding ? amount : -amount;
                      await DBHelper.updateStockQuantity(
                        currentProduct['id'],
                        finalChange,
                      );
                      await refreshProduct(); // Refresh screen in real-time
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Stock Updated Successfully"),
                        ),
                      );
                    }
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final qty = currentProduct["quantity"] ?? 0;

    String status = qty == 0
        ? "Out of Stock"
        : qty <= 15
        ? "Low Stock"
        : "In Stock";
    Color statusColor = qty == 0
        ? Colors.red
        : qty <= 15
        ? Colors.orange
        : Colors.green;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,

        title: const Text(
          "Product Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),

        centerTitle: true,

        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ),
      ),
      body: Container(
        color: AppColors.primary,
        child: ClipRRect(
          borderRadius: AppCurve.top(context),
          child: Container(
            color: Colors.white,
            child: R.maxW(
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  R.sp(context, 20),
                  R.sp(context, 20),
                  R.sp(context, 20),
                  R.sp(context, 30),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 12),
                        ),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // CARD CONTENT
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child:
                                        currentProduct["image_path"] != null &&
                                            currentProduct["image_path"] != ""
                                        ? Image.file(
                                            File(currentProduct["image_path"]),
                                            height: R.fluid(context, 180, 320),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: R.fluid(context, 180, 320),
                                            width: double.infinity,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.image,
                                              size: 50,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                _rowItem(
                                  "Product Name",
                                  currentProduct["name"],
                                ),
                                _rowItem(
                                  "Category",
                                  currentProduct["category"],
                                ),
                                _rowItem(
                                  "Selling Price",
                                  "₹ ${currentProduct["selling_price"]}",
                                ),
                                _rowItem("Stock", "$qty Units"),
                                _rowItem("Status", status),

                                const SizedBox(height: 25),

                                Row(
                                  children: [
                                    // EDIT
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddProductScreen(
                                                    product: currentProduct,
                                                  ),
                                            ),
                                          );

                                          if (result == true) {
                                            refreshProduct();
                                          }
                                        },
                                        icon: Icon(
                                          Icons.edit,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                        label: Text(
                                          "Edit",
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: R.fs(context, 15),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          foregroundColor: AppColors.primary,
                                          elevation: 0,
                                          minimumSize: const Size.fromHeight(
                                            45,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              R.radius(context, 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // UPDATE STOCK
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _showUpdateStockDialog,
                                        icon: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                        label: Text(
                                          "Update",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                            fontSize: R.fs(context, 15),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green
                                              .withOpacity(0.1),
                                          foregroundColor: Colors.green,
                                          elevation: 0,
                                          minimumSize: const Size.fromHeight(
                                            45,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              R.radius(context, 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // DELETE
                                    SizedBox(
                                      width: 45,
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                  "Delete Product",
                                                ),
                                                content: Text(
                                                  "Are you sure you want to delete ${currentProduct["name"]}?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      );
                                                    },
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      );
                                                    },
                                                    child: const Text(
                                                      "Delete",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm == true) {
                                            await DBHelper.deleteProduct(
                                              currentProduct["id"],
                                            );
                                            Navigator.pop(context, true);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red
                                              .withOpacity(0.1),
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              R.radius(context, 12),
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: R.sp(context, 16)),

                    // INFO SECTION
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 12),
                        ),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Product Information",
                            style: TextStyle(
                              fontSize: R.fs(context, 18),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: R.sp(context, 20)),

                          _infoRow("Category", currentProduct["category"]),
                          _infoRow("HSN Code", currentProduct["hsn_code"]),
                          _infoRow("Product Code", currentProduct["barcode"]),
                          _infoRow(
                            "Purchase Price",
                            "₹ ${currentProduct["purchase_price"]}",
                          ),
                          _infoRow("Quantity", "$qty"),
                          _infoRow("Unit", currentProduct["unit"]),
                          _infoRow(
                            "Expiry Date",
                            currentProduct["expiry_date"],
                          ),
                          _infoRow(
                            "Description",
                            currentProduct["description"],
                          ),
                        ],
                      ),
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

  Widget _summaryItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: R.fs(context, 12), color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }

  Widget _rowItem(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? "",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                fontSize: R.fs(context, 15),
                color: Colors.grey.shade700,
              ),
            ),
          ),

          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? "-",
              style: TextStyle(
                fontSize: R.fs(context, 16),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactStat(String title, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),

        const SizedBox(height: 4),

        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
