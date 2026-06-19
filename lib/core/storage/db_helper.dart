import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  // =========================
  // 🔹 DB INSTANCE
  // =========================
  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  // =========================
  // 🔹 INIT DATABASE
  // =========================
  static Future<Database> initDb() async {
    final path = join(await getDatabasesPath(), 'stock_new.db');

    return await openDatabase(
      path,
      version: 14,

      onCreate: (db, version) async {
        await _createTables(db);
      },

      onOpen: (db) async {
        // ADD NEW COLUMNS IF NOT EXISTS

        try {
          await db.execute("ALTER TABLE products ADD COLUMN sgst REAL");
        } catch (e) {}

        try {
          await db.execute("ALTER TABLE products ADD COLUMN cgst REAL");
        } catch (e) {}

        try {
          await db.execute("ALTER TABLE products ADD COLUMN hsn_code TEXT");
        } catch (e) {}

        try {
          await db.execute("ALTER TABLE products ADD COLUMN expiry_date TEXT");
        } catch (e) {}

        try {
          await db.execute(
            "ALTER TABLE products ADD COLUMN purchase_price REAL",
          );
        } catch (e) {}

        try {
          await db.execute("ALTER TABLE products ADD COLUMN image_path TEXT");
        } catch (e) {}

        // 👇 ADD THESE NEW LINES FOR THE PROFILE TABLE 👇
        try {
          await db.execute(
            "ALTER TABLE profile ADD COLUMN businessAddress TEXT",
          );
        } catch (e) {}
        try {
          await db.execute("ALTER TABLE profile ADD COLUMN phoneNumber TEXT");
        } catch (e) {}
        try {
          await db.execute("ALTER TABLE profile ADD COLUMN emailAddress TEXT");
        } catch (e) {}
        try {
          await db.execute("ALTER TABLE profile ADD COLUMN gstNumber TEXT");
        } catch (e) {}
        try {
          await db.execute("ALTER TABLE products ADD COLUMN image_path TEXT");
        } catch (e) {}
        try {
          await db.execute(
            "ALTER TABLE profile ADD COLUMN taxRegistrationType TEXT",
          );
        } catch (e) {}
        // --- NEW USER COLUMN ---
        try {
          await db.execute("ALTER TABLE users ADD COLUMN phone TEXT");
        } catch (e) {}
        try {
          await db.execute(
            "ALTER TABLE products ADD COLUMN discount REAL DEFAULT 0",
          );
        } catch (e) {}
        // --- ADDED FOR HISTORICAL DASHBOARD ---
        try {
          await db.execute(
            "ALTER TABLE products ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP",
          );
        } catch (e) {}
        try {
          await db.execute(
            "ALTER TABLE suppliers ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP",
          );
        } catch (e) {}
      },
    );
  }

  // =========================
  // 🔹 CREATE TABLES
  // =========================
  static Future<void> _createTables(Database db) async {
    // =========================
    // 👤 USERS
    // =========================
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        role TEXT
      )
    ''');

    // =========================
    // 📦 PRODUCTS
    // =========================
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        sgst REAL, 
        cgst REAL,
        hsn_code TEXT,         -- Changed from hsnCode
        supplier TEXT,
        expiry_date TEXT,      -- Changed from expiryDate
        purchase_price REAL,   -- Changed from purchasePrice
        selling_price REAL,    -- Changed from sellingPrice
        quantity INTEGER,
        lsl INTEGER,
        unit TEXT,
        description TEXT,
        barcode TEXT,
        image_path TEXT,
       discount REAL DEFAULT 0    -- Changed from imagePath
      )
    ''');
    // =========================
    // 💰 SALES
    // =========================
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        amount REAL,
        date TEXT
      )
    ''');

    // =========================
    // 🚚 SUPPLIERS
    // =========================
    await db.execute('''
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierName TEXT,
        companyName TEXT,
        contactNumber TEXT,
        email TEXT,
        category TEXT,
        gst TEXT,
        address TEXT
      )
    ''');

    // =========================
    // 🧾 INVOICES
    // =========================
    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        subtotal REAL,
        discount REAL,
        tax REAL,
        total REAL
      )
    ''');

    // =========================
    // 🧾 INVOICE ITEMS
    // =========================
    await db.execute('''
      CREATE TABLE invoice_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER,
        productId INTEGER,
        name TEXT,
        price REAL,
        qty INTEGER,
        amount REAL
      )
    ''');

    // =========================
    // ⚙️ SETTINGS
    // =========================
    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        value TEXT
      )
    ''');

    // 👇 PASTE THE CODE EXACTLY HERE 👇
    // Default Invoice & Tax Settings
    await db.insert('settings', {'key': 'invoicePrefix', 'value': 'INV'});
    await db.insert('settings', {'key': 'invoiceFormat', 'value': 'INV-0001'});
    await db.insert('settings', {
      'key': 'nextInvoiceNumber',
      'value': 'INV-000123',
    });
    await db.insert('settings', {'key': 'defaultDueDate', 'value': '15 Days'});
    await db.insert('settings', {'key': 'showGst', 'value': 'true'});
    await db.insert('settings', {'key': 'showDiscount', 'value': 'true'});
    await db.insert('settings', {
      'key': 'invoiceFooter',
      'value': 'Thanks for your business!',
    });
    await db.insert('settings', {
      'key': 'termsConditions',
      'value': 'No return without permission.',
    });
    // Default Customize Settings
    await db.insert('settings', {'key': 'barcodeEnabled', 'value': 'true'});
    await db.insert('settings', {'key': 'lowStockAlert', 'value': 'true'});
    await db.insert('settings', {'key': 'lowStockLimit', 'value': '5'});
    await db.insert('settings', {'key': 'stockManagement', 'value': 'true'});

    // Default Hardware Settings (For UI Placeholders)
    await db.insert('settings', {'key': 'defaultPrinter', 'value': 'Not Set'});
    // Default Backup & Sync Settings
    await db.insert('settings', {'key': 'googleDriveBackup', 'value': 'true'});
    await db.insert('settings', {'key': 'autoBackup', 'value': 'true'});

    // Default Notification Settings
    await db.insert('settings', {'key': 'notifLowStock', 'value': 'true'});
    await db.insert('settings', {'key': 'notifPayment', 'value': 'true'});
    await db.insert('settings', {'key': 'notifDailySales', 'value': 'true'});
    await db.insert('settings', {'key': 'notifNewOrder', 'value': 'true'});
    await db.insert('settings', {'key': 'notifEmail', 'value': 'false'});
    await db.insert('settings', {'key': 'notifSound', 'value': 'true'});

    // =========================
    // 👤 PROFILE
    // =========================
    await db.execute('''
      CREATE TABLE profile(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        storeName TEXT,
        tagline TEXT,
        logoPath TEXT,
        businessAddress TEXT,       -- NEW FIELD
        phoneNumber TEXT,           -- NEW FIELD
        emailAddress TEXT,          -- NEW FIELD
        gstNumber TEXT,             -- NEW FIELD
        taxRegistrationType TEXT    -- NEW FIELD
      )
    ''');
    // =========================
    // 🔐 LOGIN BRANDING
    // =========================
    await db.execute('''
      CREATE TABLE login_branding(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appName TEXT,
        tagline TEXT,
        logoPath TEXT
      )
    ''');

    // =========================
    // 👉 DEFAULT ADMIN
    // =========================
    await db.insert('users', {
      'name': 'Admin',
      'email': 'divyabharathi@catalystack.com',
      'password': 'Rdivya@0108',
      'role': 'admin',
    });
  }

  // =========================
  // 🔐 LOGIN
  // =========================
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final dbClient = await db;

    final res = await dbClient.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    return res.isNotEmpty ? res.first : null;
  }

  // =========================
  // 📝 REGISTER
  // =========================
  static Future<bool> registerUser(
    String name,
    String email,
    String password,
  ) async {
    final dbClient = await db;

    final existing = await dbClient.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty) return false;

    await dbClient.insert('users', {
      'name': name,
      'email': email,
      'password': password,
      'role': 'admin',
    });

    return true;
  }

  // =========================
  // 🔑 RESET PASSWORD
  // =========================
  static Future<bool> updatePassword(String email, String newPassword) async {
    final dbClient = await db;

    final res = await dbClient.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );

    return res > 0;
  }

  // =========================
  // 📦 ADD PRODUCT
  // =========================
  static Future<void> addProduct({
    required String name,
    required String category,

    required double sgst,
    required double cgst,
    required String hsnCode,

    required String supplier,
    required String expiryDate,

    required double purchasePrice,
    required double sellingPrice,

    required int quantity,
    required int lsl,

    required String unit,
    required String description,
    required String barcode,
    required String imagePath,
    required double discount,
  }) async {
    final dbClient = await db;

    await dbClient.insert("products", {
      "name": name,
      "category": category,

      // GST
      "sgst": sgst,
      "cgst": cgst,
      "hsn_code": hsnCode,

      // Other Details
      "supplier": supplier,
      "expiry_date": expiryDate,

      "purchase_price": purchasePrice,
      "selling_price": sellingPrice,

      "quantity": quantity,
      "lsl": lsl,

      "unit": unit,
      "description": description,
      "barcode": barcode,
      "image_path": imagePath,
      "discount": discount,
    });
  }

  static Future<int> updateProduct({
    required int id,
    required String name,
    required String category,
    required double sgst,
    required double cgst,
    required String hsnCode,
    required String supplier,
    required String expiryDate,
    required double purchasePrice,
    required double sellingPrice,
    required int quantity,
    required int lsl,
    required String unit,
    required String description,
    required String barcode,
    required String imagePath,
    required double discount,
  }) async {
    final dbClient = await db;

    final data = {
      "name": name,
      "category": category,
      "sgst": sgst,
      "cgst": cgst,
      "hsn_code": hsnCode,
      "supplier": supplier,
      "expiry_date": expiryDate,
      "purchase_price": purchasePrice,
      "selling_price": sellingPrice, // 🔹 Ensure this is selling_price
      "quantity": quantity,
      "lsl": lsl,
      "unit": unit,
      "description": description,
      "barcode": barcode,
      "image_path": imagePath,
      "discount": discount,
    };

    return await dbClient.update(
      "products",
      data,
      where: "id = ?",
      whereArgs: [id],
    );
  }
  // =========================
  // 🔍 GET PRODUCT BY BARCODE
  // =========================

  static Future<Map<String, dynamic>?> getProductByBarcode(
    String barcode,
  ) async {
    final dbClient = await db;

    final result = await dbClient.query(
      "products",

      where: "barcode = ?",
      whereArgs: [barcode],
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  // =========================
  // 📦 GET ALL PRODUCTS
  // =========================
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final dbClient = await db;
    return await dbClient.query('products', orderBy: 'id DESC');
  }

  // =========================
  // 📦 STOCK IN
  // =========================
  static Future<void> stockIn(int productId, int qty) async {
    final dbClient = await db;

    await dbClient.rawUpdate(
      "UPDATE products SET quantity = quantity + ? WHERE id = ?",
      [qty, productId],
    );
  }

  // 🔹 UPDATE STOCK QUANTITY (Plus/Minus)
  static Future<int> updateStockQuantity(int id, int changeAmount) async {
    final dbClient = await db;

    // This SQL adds the changeAmount (can be negative) to the existing quantity
    return await dbClient.rawUpdate(
      'UPDATE products SET quantity = quantity + ? WHERE id = ?',
      [changeAmount, id],
    );
  }

  // =========================
  // 📉 LOW STOCK COUNT
  // =========================
  static Future<int> getLowStockCount() async {
    final dbClient = await db;

    final res = await dbClient.rawQuery(
      "SELECT COUNT(*) as count FROM products WHERE quantity <= 5",
    );

    return (res.first["count"] as num).toInt();
  }

  // =========================
  // 🚚 SUPPLIER COUNT
  // =========================
  static Future<int> getSupplierCount() async {
    final dbClient = await db;

    final res = await dbClient.rawQuery(
      "SELECT COUNT(*) as count FROM suppliers",
    );

    return (res.first["count"] as num).toInt();
  }

  // =========================
  // 🚚 ADD SUPPLIER
  // =========================
  static Future<void> addSupplier({
    required String supplierName,
    required String companyName,
    required String contactNumber,
    required String email,
    required String category,
    required String gst,
    required String address,
  }) async {
    final dbClient = await db;

    await dbClient.insert("suppliers", {
      "supplierName": supplierName,
      "companyName": companyName,
      "contactNumber": contactNumber,
      "email": email,
      "category": category,
      "gst": gst,
      "address": address,
    });
  }

  // =========================
  // 🚚 GET ALL SUPPLIERS
  // =========================
  static Future<List<Map<String, dynamic>>> getSuppliers() async {
    final dbClient = await db;

    return await dbClient.query("suppliers", orderBy: "id DESC");
  }

  // =========================
  // 🚚 GET SUPPLIER BY ID
  // =========================
  static Future<Map<String, dynamic>?> getSupplierById(int id) async {
    final dbClient = await db;

    final result = await dbClient.query(
      "suppliers",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  // =========================
  // 🚚 UPDATE SUPPLIER
  // =========================
  static Future<int> updateSupplier({
    required int id,
    required String supplierName,
    required String contactNumber,
    required String category,
  }) async {
    final dbClient = await db;

    return await dbClient.update(
      "suppliers",
      {
        "supplierName": supplierName,
        "contactNumber": contactNumber,
        "category": category,
      },
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // delete supplier//
  static Future<int> deleteSupplier(int id) async {
    final dbClient = await db;

    return await dbClient.delete("suppliers", where: "id = ?", whereArgs: [id]);
  }

  // =========================
  // 💰 TOTAL PURCHASE VALUE
  // =========================
  static Future<double> getTotalPurchaseAmount() async {
    final dbClient = await db;

    final result = await dbClient.rawQuery('''
    SELECT SUM(purchase_price * quantity) as total
    FROM products
  ''');

    return (result.first["total"] as num?)?.toDouble() ?? 0.0;
  }

  // =========================
  // 💰 ADD SALE
  // =========================
  static Future<void> addSale(int productId, int qty) async {
    final dbClient = await db;

    final product = await dbClient.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (product.isEmpty) return;

    int currentQty = product.first['quantity'] as int;
    double price = (product.first['sellingPrice'] as num).toDouble();

    if (currentQty < qty) {
      throw Exception("Not enough stock");
    }

    double total = price * qty;

    await dbClient.rawUpdate(
      "UPDATE products SET quantity = quantity - ? WHERE id = ?",
      [qty, productId],
    );

    await dbClient.insert('sales', {
      'productId': productId,
      'amount': total,
      'date': _today(),
    });
  }

  // =========================
  // 📊 COUNTS
  // =========================
  static Future<int> getProductCount() async {
    final dbClient = await db;

    final res = await dbClient.rawQuery(
      "SELECT COUNT(*) as count FROM products",
    );

    return (res.first["count"] as num).toInt();
  }

  static Future<int> getSalesCount() async {
    final dbClient = await db;

    final res = await dbClient.rawQuery(
      "SELECT SUM(total) as totalSales FROM invoices",
    );

    return (res.first["totalSales"] as num?)?.toInt() ?? 0;
  }

  // =========================
  // 📊 LAST 7 DAYS SALES
  // =========================
  static Future<List<double>> getLast7DaysSales() async {
    final dbClient = await db;

    List<double> data = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final formatted = _formatDate(date);

      final res = await dbClient.rawQuery(
        "SELECT SUM(total) as total FROM invoices WHERE date = ?",
        [formatted],
      );

      data[i] = (res.first["total"] as num?)?.toDouble() ?? 0.0;
    }

    return data;
  }

  // =========================
  // 📊 LAST 7 WEEKS SALES
  // =========================
  static Future<List<double>> getLast7WeeksSales() async {
    final dbClient = await db;

    List<double> data = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final startDate = DateTime.now().subtract(Duration(days: (6 - i) * 7));

      final endDate = startDate.add(const Duration(days: 6));

      final start =
          "${startDate.year}-${_two(startDate.month)}-${_two(startDate.day)}";

      final end = "${endDate.year}-${_two(endDate.month)}-${_two(endDate.day)}";

      final res = await dbClient.rawQuery(
        '''
      SELECT SUM(total) as total
      FROM invoices
      WHERE date BETWEEN ? AND ?
      ''',
        [start, end],
      );

      data[i] = (res.first["total"] as num?)?.toDouble() ?? 0.0;
    }

    return data;
  }

  // =========================
  // 📊 LAST 7 MONTHS SALES
  // =========================
  static Future<List<double>> getLast7MonthsSales() async {
    final dbClient = await db;

    List<double> data = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final date = DateTime(
        DateTime.now().year,
        DateTime.now().month - (6 - i),
      );

      final month = "${date.year}-${_two(date.month)}";

      final res = await dbClient.rawQuery(
        '''
      SELECT SUM(total) as total
      FROM invoices
      WHERE substr(date,1,7) = ?
      ''',
        [month],
      );

      data[i] = (res.first["total"] as num?)?.toDouble() ?? 0.0;
    }

    return data;
  }

  // =========================
  // 📊 LAST 7 YEARS SALES
  // =========================
  static Future<List<double>> getLast7YearsSales() async {
    final dbClient = await db;

    List<double> data = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final year = "${DateTime.now().year - (6 - i)}";

      final res = await dbClient.rawQuery(
        '''
      SELECT SUM(total) as total
      FROM invoices
      WHERE substr(date,1,4) = ?
      ''',
        [year],
      );

      data[i] = (res.first["total"] as num?)?.toDouble() ?? 0.0;
    }

    return data;
  }

  // =========================
  // 🔹 SAVE GRAPH VISIBILITY
  // =========================
  static Future<void> saveGraphVisibility(bool value) async {
    final dbClient = await db;

    await dbClient.insert('settings', {
      'key': 'showGraph',
      'value': value ? 'true' : 'false',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // =========================
  // 🔹 GET GRAPH VISIBILITY
  // =========================
  static Future<bool> getGraphVisibility() async {
    final dbClient = await db;

    final res = await dbClient.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['showGraph'],
    );

    if (res.isNotEmpty) {
      return res.first['value'] == 'true';
    }

    return true; // default ON
  }

  // =========================
  // 📅 DATE FORMAT
  // =========================
  static String _today() {
    return _formatDate(DateTime.now());
  }

  static String _formatDate(DateTime date) {
    return "${date.year}-${_two(date.month)}-${_two(date.day)}";
  }

  static String _two(int n) {
    return n.toString().padLeft(2, '0');
  }

  static Future<void> reduceProductStock(int productId, int soldQty) async {
    final dbClient = await db;

    final product = await dbClient.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (product.isNotEmpty) {
      int currentQty = product.first['quantity'] as int;

      int newQty = currentQty - soldQty;

      if (newQty < 0) {
        newQty = 0;
      }

      await dbClient.update(
        'products',
        {'quantity': newQty},
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
  }

  static Future<void> updateStockAfterSale(
    List<Map<String, dynamic>> items,
  ) async {
    final dbClient = await db;

    for (var item in items) {
      final product = await dbClient.query(
        'products',
        where: 'id = ?',
        whereArgs: [item['id']],
      );

      if (product.isNotEmpty) {
        int currentQty = product.first['quantity'] as int;

        int soldQty = item['qty'] as int;

        int newQty = currentQty - soldQty;

        if (newQty < 0) {
          newQty = 0;
        }

        await dbClient.update(
          'products',
          {'quantity': newQty},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }
    }
  }

  // =========================
  // 🧾 CREATE INVOICE
  // =========================
  static Future<int> createInvoice({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
  }) async {
    final dbClient = await db;

    return await dbClient.transaction((txn) async {
      int invoiceId = await txn.insert('invoices', {
        'date': _today(),
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
      });

      for (var item in items) {
        double price = item['price'];
        int qty = item['qty'];

        await txn.insert('invoice_items', {
          'invoiceId': invoiceId,
          'productId': item['id'],
          'name': item['name'],
          'price': price,
          'qty': qty,
          'amount': price * qty,
        });

        await txn.rawUpdate(
          "UPDATE products SET quantity = quantity - ? WHERE id = ?",
          [qty, item['id']],
        );
      }

      return invoiceId;
    });
  }

  static Future<void> addInvoiceItem({
    required int invoiceId,
    required int productId,
    required String name,
    required double price,
    required int qty,
    required double amount,
  }) async {
    final dbClient = await db;

    await dbClient.insert("invoice_items", {
      "invoiceId": invoiceId,
      "productId": productId,
      "name": name,
      "price": price,
      "qty": qty,
      "amount": amount,
    });
  }
  // =========================
  // 🧾 BILLING SUPPORT METHODS
  // =========================

  // 🔹 UPDATE PRODUCT QUANTITY DIRECTLY (USED IN BILLING)
  static Future<void> updateProductQuantity(int id, int newQty) async {
    final dbClient = await db;

    await dbClient.update(
      'products',
      {'quantity': newQty},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateInvoiceStatus(int id, String method) async {
    final dbClient = await DBHelper.db;
    await dbClient.update(
      'invoices',
      {'status': 'Paid', 'paymentMethod': method},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔹 PROCESS FULL BILL (MULTIPLE PRODUCTS)
  static Future<void> processBill(List<Map<String, dynamic>> cartItems) async {
    final dbClient = await db;

    await dbClient.transaction((txn) async {
      for (var item in cartItems) {
        final product = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item['id']],
        );

        if (product.isEmpty) continue;

        int currentQty = product.first['quantity'] as int;
        int soldQty = item['qty'];

        if (currentQty < soldQty) {
          throw Exception("Not enough stock for ${item['name']}");
        }

        double price = (product.first['sellingPrice'] as num).toDouble();
        double total = price * soldQty;

        // 🔻 Reduce stock
        await txn.rawUpdate(
          "UPDATE products SET quantity = quantity - ? WHERE id = ?",
          [soldQty, item['id']],
        );

        // 💰 Add sale entry
        await txn.insert('sales', {
          'productId': item['id'],
          'amount': total,
          'date': _today(),
        });
      }
    });
  }

  // 1. To get a single product after editing
  static Future<Map<String, dynamic>?> getProductById(int id) async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'products',
      where: "id = ?",
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // 2. To update just the stock quantity
  static Future<int> updateStock(int id, int changeAmount) async {
    final dbClient = await db;
    return await dbClient.rawUpdate(
      'UPDATE products SET quantity = quantity + ? WHERE id = ?',
      [changeAmount, id],
    );
  }

  // 🔹 DELETE PRODUCT (OPTIONAL FEATURE)
  static Future<void> deleteProduct(int id) async {
    final dbClient = await db;

    await dbClient.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // SAVE SETTING
  static Future<void> saveSetting(String key, String value) async {
    final dbClient = await db;

    await dbClient.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getSetting(String key) async {
    final dbClient = await db;

    final res = await dbClient.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (res.isNotEmpty) return res.first['value'] as String;
    return null;
  }

  // 🔹 CREATE PROFILE TABLE
  static Future<void> createProfileTable(Database db) async {
    await db.execute('''
    CREATE TABLE profile(
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     storeName TEXT,
     tagline TEXT,
     logoPath TEXT
    )
  ''');
  }

  // =========================
  // SAVE PROFILE
  // =========================

  static Future<void> saveProfile({
    required String storeName,
    required String tagline,
    required String logoPath,
  }) async {
    final dbClient = await db;

    final existing = await dbClient.query("profile");

    if (existing.isNotEmpty) {
      await dbClient.update(
        "profile",

        {"storeName": storeName, "tagline": tagline, "logoPath": logoPath},

        where: "id = ?",
        whereArgs: [1],
      );
    } else {
      await dbClient.insert("profile", {
        "id": 1,
        "storeName": storeName,
        "tagline": tagline,
        "logoPath": logoPath,
      });
    }
  }
  // =========================
  // GET PROFILE
  // =========================

  static Future<Map<String, dynamic>?> getProfile() async {
    final dbClient = await db;

    final result = await dbClient.query("profile");

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  // =========================
  // 🔹 SAVE LOGIN BRANDING
  // =========================
  static Future<void> saveLoginBranding({
    required String appName,
    required String tagline,
    required String logoPath,
  }) async {
    final dbClient = await db;

    final res = await dbClient.query('login_branding');

    if (res.isEmpty) {
      await dbClient.insert('login_branding', {
        'appName': appName,
        'tagline': tagline,
        'logoPath': logoPath,
      });
    } else {
      await dbClient.update(
        'login_branding',
        {'appName': appName, 'tagline': tagline, 'logoPath': logoPath},
        where: 'id = ?',
        whereArgs: [res.first['id']],
      );
    }
  }

  // =========================
  // 🔹 GET LOGIN BRANDING
  // =========================
  static Future<Map<String, dynamic>?> getLoginBranding() async {
    final dbClient = await db;

    final res = await dbClient.query('login_branding');

    return res.isNotEmpty ? res.first : null;
  }

  // =========================
  // 🔹 UPDATE SINGLE PROFILE FIELD
  // =========================
  static Future<void> updateProfileField(String field, String value) async {
    final dbClient = await db;

    // Check if a profile exists first
    final existing = await dbClient.query("profile");

    if (existing.isNotEmpty) {
      // Update the specific field
      await dbClient.update(
        'profile',
        {field: value},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // If no profile exists at all, create one with this field
      await dbClient.insert("profile", {field: value});
    }
  }
  // =====================================================
  // 🔹 HISTORICAL DASHBOARD QUERIES (30 Days Ago)
  // =====================================================

  static Future<int> getPastProductCount() async {
    final dbClient = await db;
    final result = await dbClient.rawQuery('''
      SELECT COUNT(*) as count FROM products 
      WHERE created_at <= date('now', '-30 days')
    ''');
    return (result.first["count"] as num?)?.toInt() ?? 0;
  }

  static Future<int> getPastSalesCount() async {
    final dbClient = await db;
    // Uses the 'date' column in your invoices table to match your getSalesCount logic
    final result = await dbClient.rawQuery('''
      SELECT SUM(total) as totalSales FROM invoices 
      WHERE date <= date('now', '-30 days')
    ''');
    return (result.first["totalSales"] as num?)?.toInt() ?? 0;
  }

  static Future<int> getPastSupplierCount() async {
    final dbClient = await db;
    final result = await dbClient.rawQuery('''
      SELECT COUNT(*) as count FROM suppliers 
      WHERE created_at <= date('now', '-30 days')
    ''');
    return (result.first["count"] as num?)?.toInt() ?? 0;
  }

  static Future<int> getPastLowStockCount() async {
    final dbClient = await db;
    // Uses quantity <= 5 to match your existing getLowStockCount logic
    final result = await dbClient.rawQuery('''
      SELECT COUNT(*) as count FROM products 
      WHERE quantity <= 5 AND created_at <= date('now', '-30 days')
    ''');
    return (result.first["count"] as num?)?.toInt() ?? 0;
  }

  // =========================
  // 👥 GET ALL USERS (ROLES)
  // =========================
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final dbClient = await db;
    return await dbClient.query('users', orderBy: 'id ASC');
  }

  // =========================
  // ➕ ADD NEW STAFF / ROLE
  // =========================
  static Future<bool> addStaffMember({
    required String name,
    required String role,
    required String email,
    required String password,
    required String phone,
  }) async {
    final dbClient = await db;

    // Check if email already exists
    final existing = await dbClient.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (existing.isNotEmpty) return false;

    await dbClient.insert('users', {
      'name': name,
      'role': role,
      'email': email,
      'password': password,
      'phone': phone,
    });
    return true;
  }
}
