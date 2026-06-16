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
                      fontWeight: FontWeight.bold,
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,

        title: const Text(
          "Product Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            color: const Color(0xFFF5F6FA),
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
                          R.radius(context, 24),
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
                          // DELETE BUTTON
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Delete Product"),
                                      content: Text(
                                        "Are you sure you want to delete ${currentProduct["name"]}?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text("Cancel"),
                                        ),

                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context, true);
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

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Product deleted successfully",
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),

                          // CARD CONTENT
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child:
                                      currentProduct["image_path"] != null &&
                                          currentProduct["image_path"] != ""
                                      ? Image.file(
                                          File(currentProduct["image_path"]),
                                          height: R.imgSize(context, 0.18),
                                          width: R.imgSize(context, 0.18),
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: R.imgSize(context, 0.18),
                                          width: R.imgSize(context, 0.18),
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image),
                                        ),
                                ),

                                SizedBox(width: R.sp(context, 12)),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentProduct["name"],
                                        style: TextStyle(
                                          fontSize: R.fs(context, 16),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Text(currentProduct["category"] ?? ""),
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                      ),

                                      const SizedBox(height: 18),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: _compactStat(
                                              "Selling Price",
                                              "₹ ${currentProduct["selling_price"]}",
                                              Colors.black,
                                            ),
                                          ),

                                          Expanded(
                                            child: _compactStat(
                                              "Stock",
                                              "$qty units",
                                              Colors.black,
                                            ),
                                          ),

                                          Expanded(
                                            child: _compactStat(
                                              "Status",
                                              status,
                                              statusColor,
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
                        ],
                      ),
                    ),
                    SizedBox(height: R.sp(context, 16)),

                    // 🔹 BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit_outlined),

                              label: Text(
                                "Edit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: R.fs(context, 18),
                                ),
                              ),

                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,

                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),

                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddProductScreen(
                                      product: currentProduct,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  refreshProduct();
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.inventory_2_outlined),

                              label: const Text(
                                "Update Stock",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,

                                foregroundColor: Colors.white,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),

                              onPressed: _showUpdateStockDialog,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: R.sp(context, 20)),

                    // 🔹 INFO SECTION
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Product Information",
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _row("Category", currentProduct["category"]),
                          _row("HSN Code", currentProduct["hsn_code"]),
                          _row("Product Code", currentProduct["barcode"]),
                          _row(
                            "Purchase Price",
                            "₹ ${currentProduct["purchase_price"]}",
                          ),
                          _row("Quantity", "$qty"),
                          _row("Unit", currentProduct["unit"]),
                          _row("Expiry Date", currentProduct["expiry_date"]),
                          _row("Description", currentProduct["description"]),
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
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _row(String title, dynamic value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: R.fs(context, 16),
                  color: Colors.grey,
                ),
              ),

              Flexible(
                child: Text(
                  value?.toString() ?? "",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),
      ],
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
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
