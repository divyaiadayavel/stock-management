import 'package:flutter/material.dart';
import '../../../../core/storage/db_helper.dart';

class ProductSearchSheet extends StatefulWidget {
  final Function(Map<String, dynamic>, int qty) onSelect;

  const ProductSearchSheet({super.key, required this.onSelect});

  @override
  State<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<ProductSearchSheet> {
  List<Map<String, dynamic>> products = [];
  String query = "";

  Map<int, int> qtyMap = {}; // store qty per product

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    final data = await DBHelper.getAllProducts();
    setState(() => products = data);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      return name.contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      height: 500,
      child: Column(
        children: [
          // 🔍 SEARCH
          TextField(
            onChanged: (val) => setState(() => query = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search product...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 📦 PRODUCT LIST
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final p = filtered[i];
                final id = p["id"] ?? 0;

                // Initialize quantity to 1 ONLY if it doesn't exist yet
                if (!qtyMap.containsKey(id)) {
                  qtyMap[id] = 1;
                }

                final qty = qtyMap[id]!;
                final price = (p["selling_price"] as num?)?.toDouble() ?? 0.0;
                final amount = price * qty;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // 🔹 NAME + PRICE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p["name"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              "₹ ${price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🔹 QTY + AMOUNT + ADD
                        Row(
                          children: [
                            // ➖
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (qty > 1) {
                                  setState(() => qtyMap[id] = qty - 1);
                                }
                              },
                            ),

                            Text("$qty", style: const TextStyle(fontSize: 16)),

                            // ➕
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => qtyMap[id] = qty + 1);
                              },
                            ),

                            const Spacer(),

                            // 💰 AMOUNT
                            Text(
                              "₹ ${amount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ✅ ADD BUTTON
                            ElevatedButton(
                              onPressed: () {
                                widget.onSelect(
                                  p,
                                  qty,
                                ); // This triggers the addToCart in BillingScreen
                                Navigator.pop(context); // Closes the sheet
                              },
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
