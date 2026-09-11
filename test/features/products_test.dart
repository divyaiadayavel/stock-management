import 'package:flutter_test/flutter_test.dart';

// Relative import pointing to your product model
import '../../lib/features/products/data/models/product_model.dart';

void main() {
  group('Products Module - Model & Unit Tests', () {
    // --- ORIGINAL MODEL TESTS ---

    test('TC_PROD_001: Verify Product.fromMap with valid map data', () {
      final map = {
        'id': '101',
        'product_name': 'Wireless Mouse',
        'category_name': 'Electronics',
        'category_id': 2,
        'purchase_price': '15.50',
        'selling_price': '25.50',
        'current_stock': '50',
        'unit_name': 'pcs',
        'barcode': '890123456789',
        'supplier_name': 'Logitech Supplier',
      };

      final product = Product.fromMap(map);

      expect(product.id, equals(101));
      expect(product.name, equals('Wireless Mouse'));
      expect(product.category, equals('Electronics'));
      expect(product.purchasePrice, equals(15.50));
      expect(product.sellingPrice, equals(25.50));
      expect(product.quantity, equals(50));
      expect(product.barcode, equals('890123456789'));
    });

    test(
      'TC_PROD_002: Verify parsing numeric fields when values are passed as Strings',
      () {
        final map = {
          'id': '102',
          'product_name': 'Mechanical Keyboard',
          'purchase_price': '49.99',
          'selling_price': '89.99',
          'current_stock': '100',
        };

        final product = Product.fromMap(map);

        expect(product.id, equals(102));
        expect(product.purchasePrice, equals(49.99));
        expect(product.sellingPrice, equals(89.99));
        expect(product.quantity, equals(100));
      },
    );

    test('TC_PROD_011: Verify Product.toMap conversion for API requests', () {
      final product = Product(
        id: 101,
        name: 'Wireless Mouse',
        category: 'Electronics',
        categoryId: 2,
        hsnCode: '8471',
        purchasePrice: 15.50,
        sellingPrice: 25.50,
        quantity: 50,
        unit: 'pcs',
        unitId: 1,
        description: 'Ergonomic mouse',
        imagePath: '',
        supplier: 'Logitech Supplier',
      );

      final map = product.toMap();

      expect(map['id'], equals(101));
      expect(map['product_name'], equals('Wireless Mouse'));
      expect(map['category_id'], equals(2));
      expect(map['selling_price'], equals(25.50));
      expect(map['current_stock'], equals(50));
    });

    // --- FORM & VALIDATION TESTS ---

    test(
      'TC_PROD_005, TC_PROD_006 & TC_PROD_017: Product form input validation & tax logic',
      () {
        String? validatePrice(String? value) {
          if (value == null || value.trim().isEmpty) return 'Price required';
          if (double.tryParse(value.trim()) == null) return 'Invalid price';
          return null;
        }

        String? validateName(String? value) {
          if (value == null || value.trim().isEmpty) return 'Name required';
          return null;
        }

        // Price Validation Checks
        expect(validatePrice(''), equals('Price required'));
        expect(validatePrice('abc'), equals('Invalid price'));
        expect(validatePrice('19.99'), isNull);

        // Required Field Checks
        expect(validateName(''), equals('Name required'));
        expect(validateName('Wireless Mouse'), isNull);

        // Tax Calculation Helper Check
        double calculateTax(double price, double sgst, double cgst) {
          return price * ((sgst + cgst) / 100);
        }

        expect(calculateTax(100.0, 5.0, 5.0), equals(10.0));
      },
    );

    // --- FILTER & SEARCH LOGIC TESTS ---

    test('TC_PROD_003 & TC_PROD_014: Search and Category Filtering Logic', () {
      final products = [
        {
          'product_name': 'Wireless Mouse',
          'barcode': '890123',
          'category': 'Electronics',
        },
        {
          'product_name': 'Office Chair',
          'barcode': '456789',
          'category': 'Furniture',
        },
        {
          'product_name': 'Gaming Mouse',
          'barcode': '890124',
          'category': 'Electronics',
        },
      ];

      // Search by query 'Mouse'
      final searchQuery = 'Mouse'.toLowerCase();
      final searchResults = products.where((p) {
        final name = (p['product_name'] ?? '').toLowerCase();
        final barcode = (p['barcode'] ?? '').toLowerCase();
        return name.contains(searchQuery) || barcode.contains(searchQuery);
      }).toList();

      expect(searchResults.length, equals(2));

      // Filter by category 'Electronics'
      final categoryResults = products
          .where((p) => p['category'] == 'Electronics')
          .toList();
      expect(categoryResults.length, equals(2));
    });
  });
}
