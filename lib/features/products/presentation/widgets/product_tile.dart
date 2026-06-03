import 'dart:io';
import 'package:flutter/material.dart';

class ProductTile extends StatelessWidget {
  final String name;
  final String category;
  final double price;
  final int quantity;
  final String image_Path;

  const ProductTile({
    super.key,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.image_Path,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 📦 IMAGE
          image_Path.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(image_Path),
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2),
                ),

          const SizedBox(width: 12),

          // 📝 NAME + CATEGORY
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(category, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          // 💰 PRICE + STOCK
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹ ${price.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _stockLabel(quantity),
                style: TextStyle(color: _stockColor(quantity), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stockLabel(int qty) {
    if (qty == 0) return "Out of Stock";
    if (qty <= 15) return "Low Stock";
    return "In Stock";
  }

  Color _stockColor(int qty) {
    if (qty == 0) return Colors.red;
    if (qty <= 15) return Colors.orange;
    return Colors.green;
  }
}
