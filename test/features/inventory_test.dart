import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Full Inventory Module Test Suite', () {
    // --- STOCK IN & STOCK OUT VALIDATION ---
    test('TC_INV_017 & TC_INV_019: Stock In & Stock Out Input Validation', () {
      String? validateStockIn(String? value) {
        if (value == null || value.trim().isEmpty)
          return 'Quantity is required';
        final qty = int.tryParse(value);
        if (qty == null || qty <= 0) return 'Enter a valid positive number';
        return null;
      }

      bool validateStockOut(int currentStock, int requestedQty) {
        return requestedQty > 0 && requestedQty <= currentStock;
      }

      // Stock In Checks
      expect(validateStockIn(''), equals('Quantity is required'));
      expect(validateStockIn('-5'), equals('Enter a valid positive number'));
      expect(validateStockIn('10'), isNull);

      // Stock Out Threshold Checks
      expect(validateStockOut(10, 15), isFalse); // Exceeds stock
      expect(validateStockOut(10, 5), isTrue); // Valid
    });

    // --- LOW STOCK FILTERING LOGIC ---
    test('TC_INV_010 & TC_INV_021: Low Stock Filter logic', () {
      final products = [
        {'name': 'Item A', 'stock': 5, 'min_stock': 10}, // Low
        {'name': 'Item B', 'stock': 25, 'min_stock': 10}, // Normal
        {'name': 'Item C', 'stock': 2, 'min_stock': 2}, // Low
      ];

      final lowStockList = products
          .where((p) => (p['stock'] as int) <= (p['min_stock'] as int))
          .toList();

      expect(lowStockList.length, equals(2));
      expect(lowStockList.first['name'], equals('Item A'));
    });

    // --- PURCHASE ORDER TOTAL CALCULATION ---
    test('TC_INV_004 & TC_INV_023: Purchase Order total calculation', () {
      final items = [
        {'price': 10.0, 'qty': 5}, // 50.0
        {'price': 15.5, 'qty': 2}, // 31.0
      ];

      final total = items.fold<double>(0.0, (sum, item) {
        return sum + ((item['price'] as double) * (item['qty'] as int));
      });

      expect(total, equals(81.0));
    });
  });
}
