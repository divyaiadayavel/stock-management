import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/storage/db_helper.dart'; // Ensure this path is correct
import 'add_product_screen.dart';

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
      appBar: AppBar(
        title: const Text("Product Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(
            context,
            true,
          ), // Pass true to refresh the list screen
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
                ],
              ),

              child: Stack(
                children: [
                  // DELETE BUTTON
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          await DBHelper.deleteProduct(currentProduct["id"]);

                          Navigator.pop(context, true);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Product deleted successfully"),
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
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 80,
                                  width: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image),
                                ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentProduct["name"],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(currentProduct["category"] ?? ""),

                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _summaryItem(
                                    "Selling Price",
                                    "₹ ${currentProduct["selling_price"]}",
                                  ),
                                  _summaryItem("Stock", "$qty units"),
                                  _summaryItem(
                                    "Status",
                                    status,
                                    color: statusColor,
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
            const SizedBox(height: 16),

            // 🔹 BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // Wait for user to finish editing
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddProductScreen(product: currentProduct),
                        ),
                      );
                      // If edit was successful, refresh this screen
                      if (result == true) {
                        refreshProduct();
                      }
                    },
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showUpdateStockDialog,
                    child: const Text("Update Stock"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔹 INFO SECTION
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Product Information",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _summaryItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _row(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value?.toString() ?? ""),
        ],
      ),
    );
  }
}
