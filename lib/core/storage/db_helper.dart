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
    final path = await getDbPath();

    return await openDatabase(
      path,
      version: 16,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onOpen:
          _onDbOpen, // 👈 Replaced inline closure with named method reference
    );
  }

  // ==========================================================
  // 🔧 DB SELF-HEAL LOGIC (Named method for explicit reuse)
  // ==========================================================
  static Future<void> _onDbOpen(Database db) async {
    // =====================================================
    // 🔧 ADD NEW COLUMNS IF NOT EXISTS (existing installs)
    // =====================================================
    try {
      await db.execute("ALTER TABLE products ADD COLUMN sgst REAL");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE products ADD COLUMN cgst REAL");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE products ADD COLUMN hsn_code TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE products ADD COLUMN expiry_date TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE products ADD COLUMN purchase_price REAL");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE products ADD COLUMN image_path TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE profile ADD COLUMN businessAddress TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE profile ADD COLUMN phoneNumber TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE profile ADD COLUMN emailAddress TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE profile ADD COLUMN gstNumber TEXT");
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE profile ADD COLUMN taxRegistrationType TEXT",
      );
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE users ADD COLUMN phone TEXT");
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE products ADD COLUMN discount REAL DEFAULT 0",
      );
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE products ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP",
      );
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE suppliers ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP",
      );
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE products ADD COLUMN warehouse TEXT DEFAULT 'Main store'",
      );
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE products ADD COLUMN updated_at TEXT DEFAULT CURRENT_TIMESTAMP",
      );
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE suppliers ADD COLUMN paymentTerms TEXT");
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE suppliers ADD COLUMN leadDays INTEGER DEFAULT 0",
      );
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE suppliers ADD COLUMN dueAmount REAL DEFAULT 0",
      );
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE invoices ADD COLUMN balanceDue REAL DEFAULT 0",
      );
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE invoices ADD COLUMN customerId INTEGER");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE invoices ADD COLUMN customerName TEXT");
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE invoices ADD COLUMN status TEXT DEFAULT 'paid'",
      );
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE invoices ADD COLUMN paymentMethod TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE invoices ADD COLUMN createdAt TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE profile ADD COLUMN ownerName TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE profile ADD COLUMN planLabel TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE customers ADD COLUMN gender TEXT");
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          phone TEXT,
          email TEXT,
          address TEXT,
          gender TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS invoice_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoiceId INTEGER,
          cashAmount REAL DEFAULT 0,
          upiAmount REAL DEFAULT 0,
          balanceDue REAL DEFAULT 0,
          customerId INTEGER,
          customerName TEXT,
          paidAt TEXT
        )
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_batches (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          purchase_price REAL NOT NULL,
          selling_price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          remaining_quantity INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(product_id) REFERENCES products(id)
        );
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER,
          type TEXT,
          quantity INTEGER,
          unitCost REAL,
          reason TEXT,
          reference TEXT,
          note TEXT,
          warehouse TEXT,
          date TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplierId INTEGER,
          status TEXT,
          orderedAt TEXT,
          expectedDelivery TEXT,
          receivedAt TEXT
        )
      ''');
    } catch (_) {}
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_order_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          poId INTEGER,
          productId INTEGER,
          name TEXT,
          unit TEXT,
          orderedQty INTEGER,
          unitPrice REAL,
          receivedQty INTEGER DEFAULT 0
        )
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchase_order_issues(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          poId INTEGER,
          note TEXT,
          createdAt TEXT
        )
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS login_branding(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          appName TEXT,
          tagline TEXT,
          logoPath TEXT
        )
      ''');
    } catch (e) {}

    try {
      await _seedTestProducts(db);
    } catch (_) {}
    try {
      await _seedTestSuppliers(db);
    } catch (_) {}
  }

  // ==========================================
  // 🔹 BACKUP & SYNC SUPPORT METHODS
  // ==========================================

  /// Absolute path to the live database file.
  static Future<String> getDbPath() async {
    return join(await getDatabasesPath(), 'stock_new.db');
  }

  /// Closes the active connection so the file isn't locked.
  /// MUST be called before Restore overwrites stock_new.db.
  static Future<void> closeDb() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  /// Reopens the db after Restore replaces the file, running the
  /// same onCreate/onOpen pipeline so ALTER TABLE self-heal logic
  /// applies to the restored file too.
  static Future<Database> reopenDb() async {
    final path = await getDbPath();
    _db = await openDatabase(
      path,
      version: 16,
      onCreate: (db, version) async => await _createTables(db),
      onOpen: _onDbOpen,
    );
    return _db!;
  }

  // =========================
  // 🔹 CREATE TABLES (fresh installs only)
  // =========================
  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        role TEXT,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        sgst REAL,
        cgst REAL,
        hsn_code TEXT,
        supplier TEXT,
        expiry_date TEXT,
        purchase_price REAL,
        selling_price REAL,
        quantity INTEGER,
        lsl INTEGER,
        unit TEXT,
        description TEXT,
        barcode TEXT,
        image_path TEXT,
        discount REAL DEFAULT 0,
        warehouse TEXT DEFAULT 'Main store',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        amount REAL,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierName TEXT,
        companyName TEXT,
        contactNumber TEXT,
        email TEXT,
        category TEXT,
        gst TEXT,
        address TEXT,
        paymentTerms TEXT,
        leadDays INTEGER DEFAULT 0,
        dueAmount REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER,
        type TEXT,
        quantity INTEGER,
        unitCost REAL,
        reason TEXT,
        reference TEXT,
        note TEXT,
        warehouse TEXT,
        date TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER,
        status TEXT,
        orderedAt TEXT,
        expectedDelivery TEXT,
        receivedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poId INTEGER,
        productId INTEGER,
        name TEXT,
        unit TEXT,
        orderedQty INTEGER,
        unitPrice REAL,
        receivedQty INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_order_issues(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poId INTEGER,
        note TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        subtotal REAL,
        discount REAL,
        tax REAL,
        total REAL,
        balanceDue REAL DEFAULT 0,
        customerId INTEGER,
        customerName TEXT,
        status TEXT DEFAULT 'paid',
        paymentMethod TEXT,
        createdAt TEXT
      )
    ''');

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

    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        gender TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER,
        cashAmount REAL DEFAULT 0,
        upiAmount REAL DEFAULT 0,
        balanceDue REAL DEFAULT 0,
        customerId INTEGER,
        customerName TEXT,
        paidAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        value TEXT
      )
    ''');

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
    await db.insert('settings', {'key': 'barcodeEnabled', 'value': 'true'});
    await db.insert('settings', {'key': 'lowStockAlert', 'value': 'true'});
    await db.insert('settings', {'key': 'lowStockLimit', 'value': '5'});
    await db.insert('settings', {'key': 'stockManagement', 'value': 'true'});
    await db.insert('settings', {'key': 'defaultPrinter', 'value': 'Not Set'});
    await db.insert('settings', {'key': 'googleDriveBackup', 'value': 'true'});
    await db.insert('settings', {'key': 'autoBackup', 'value': 'true'});
    await db.insert('settings', {'key': 'notifLowStock', 'value': 'true'});
    await db.insert('settings', {'key': 'notifPayment', 'value': 'true'});
    await db.insert('settings', {'key': 'notifDailySales', 'value': 'true'});
    await db.insert('settings', {'key': 'notifNewOrder', 'value': 'true'});
    await db.insert('settings', {'key': 'notifEmail', 'value': 'false'});
    await db.insert('settings', {'key': 'notifSound', 'value': 'true'});

    await db.execute('''
      CREATE TABLE profile(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        storeName TEXT,
        tagline TEXT,
        logoPath TEXT,
        businessAddress TEXT,
        phoneNumber TEXT,
        emailAddress TEXT,
        gstNumber TEXT,
        taxRegistrationType TEXT,
        ownerName TEXT,
        planLabel TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE login_branding(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appName TEXT,
        tagline TEXT,
        logoPath TEXT
      )
    ''');

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
  // 📦 ADD PRODUCT (FIXED: Returns generated ID as int)
  // =========================
  static Future<int> addProduct({
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
    return await dbClient.insert("products", {
      "name": name,
      "category": category,
      "sgst": sgst,
      "cgst": cgst,
      "hsn_code": hsnCode,
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
      "selling_price": sellingPrice,
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
    return result.isNotEmpty ? result.first : null;
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
    return (res.first["count"] as num? ?? 0).toInt();
  }

  // =========================
  // 📦 STOCK IN (BATCH VERSION)
  // =========================
  static Future<void> addProductBatch({
    required int productId,
    required double purchasePrice,
    required double sellingPrice,
    required int quantity,
  }) async {
    final dbClient = await db;
    await dbClient.rawInsert(
      '''
      INSERT INTO product_batches 
      (product_id, purchase_price, selling_price, quantity, remaining_quantity, created_at) 
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        productId,
        purchasePrice,
        sellingPrice,
        quantity,
        quantity,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  // 🔹 UPDATE BATCH REMAINING QUANTITY (Plus/Minus)
  static Future<int> updateBatchQuantity(int batchId, int changeAmount) async {
    final dbClient = await db;
    return await dbClient.rawUpdate(
      'UPDATE product_batches SET remaining_quantity = remaining_quantity + ? WHERE id = ?',
      [changeAmount, batchId],
    );
  }

  // =========================
  // 🚚 SUPPLIER COUNT
  // =========================
  static Future<int> getSupplierCount() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery(
      "SELECT COUNT(*) as count FROM suppliers",
    );
    return (res.first["count"] as num? ?? 0).toInt();
  }

  // =========================
  // 🚚 ADD SUPPLIER
  // =========================
  static Future<int> addSupplier({
    required String supplierName,
    required String companyName,
    required String contactNumber,
    required String email,
    required String category,
    required String gst,
    required String address,
  }) async {
    final dbClient = await db;
    return await dbClient.insert("suppliers", {
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
    return result.isNotEmpty ? result.first : null;
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

  // Delete Supplier
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
  // 💰 ADD SALE (FIXED: Fixed runtime field matching)
  // =========================
  static Future<void> addSale(int productId, int qty) async {
    final dbClient = await db;
    final product = await dbClient.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (product.isEmpty) return;

    int currentQty = (product.first['quantity'] as num? ?? 0).toInt();
    double price = (product.first['selling_price'] as num? ?? 0.0).toDouble();

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
    return (res.first["count"] as num? ?? 0).toInt();
  }

  static Future<int> getSalesCount() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery(
      "SELECT SUM(total) as totalSales FROM invoices",
    );
    return (res.first["totalSales"] as num?)?.toInt() ?? 0;
  }

  // =========================
  // 📅 TODAY SALES
  // =========================
  static Future<double> getTodaySales() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery('''
      SELECT SUM(total) AS todaySales
      FROM invoices
      WHERE DATE(createdAt) = DATE('now','localtime')
    ''');
    return (res.first["todaySales"] as num?)?.toDouble() ?? 0.0;
  }

  // =========================
  // 💰 RECEIVABLES
  // =========================
  static Future<double> getReceivablesAmount() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery('''
      SELECT SUM(balanceDue) AS receivables
      FROM invoices
      WHERE balanceDue > 0
    ''');
    return (res.first["receivables"] as num?)?.toDouble() ?? 0.0;
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
    return true;
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
      int currentQty = (product.first['quantity'] as num? ?? 0).toInt();
      int newQty = currentQty - soldQty;

      if (newQty < 0) newQty = 0;

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
        int currentQty = (product.first['quantity'] as num? ?? 0).toInt();
        int soldQty = (item['qty'] as num? ?? 0).toInt();
        int newQty = currentQty - soldQty;

        if (newQty < 0) newQty = 0;

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
        'createdAt': DateTime.now().toIso8601String(),
      });

      for (var item in items) {
        double price = (item['price'] as num? ?? 0.0).toDouble();
        int qty = (item['qty'] as num? ?? 0).toInt();

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

  static Future<void> updateInvoiceStatusStatic(int id, String method) async {
    final dbClient = await db;
    await dbClient.update(
      'invoices',
      {'status': 'Paid', 'paymentMethod': method},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

        int currentQty = (product.first['quantity'] as num? ?? 0).toInt();
        int soldQty = (item['qty'] as num? ?? 0).toInt();

        if (currentQty < soldQty) {
          throw Exception("Not enough stock for ${item['name']}");
        }

        double price = (product.first['selling_price'] as num? ?? 0.0)
            .toDouble();
        double total = price * soldQty;

        await txn.rawUpdate(
          "UPDATE products SET quantity = quantity - ? WHERE id = ?",
          [soldQty, item['id']],
        );

        await txn.insert('sales', {
          'productId': item['id'],
          'amount': total,
          'date': _today(),
        });
      }
    });
  }

  static Future<Map<String, dynamic>?> getProductById(int id) async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'products',
      where: "id = ?",
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  static Future<int> updateStock(int id, int changeAmount) async {
    final dbClient = await db;
    return await dbClient.rawUpdate(
      'UPDATE products SET quantity = quantity + ? WHERE id = ?',
      [changeAmount, id],
    );
  }

  static Future<void> deleteProduct(int id) async {
    final dbClient = await db;
    await dbClient.delete('products', where: 'id = ?', whereArgs: [id]);
  }

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
    return res.isNotEmpty ? res.first['value'] as String : null;
  }

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

  static Future<Map<String, dynamic>?> getProfile() async {
    final dbClient = await db;
    final result = await dbClient.query("profile");
    return result.isNotEmpty ? result.first : null;
  }

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

  static Future<Map<String, dynamic>?> getLoginBranding() async {
    final dbClient = await db;
    final res = await dbClient.query('login_branding');
    return res.isNotEmpty ? res.first : null;
  }

  static Future<void> updateProfileField(String field, String value) async {
    final dbClient = await db;
    final existing = await dbClient.query("profile");

    if (existing.isNotEmpty) {
      await dbClient.update(
        'profile',
        {field: value},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await dbClient.insert("profile", {field: value});
    }
  }

  static Future<int> getPastProductCount() async {
    final dbClient = await db;
    final result = await dbClient.rawQuery('''
      SELECT COUNT(*) as count FROM products
      WHERE created_at <= date('now', '-30 days')
    ''');
    return (result.first["count"] as num? ?? 0).toInt();
  }

  static Future<int> getPastSalesCount() async {
    final dbClient = await db;
    final result = await dbClient.rawQuery('''
      SELECT SUM(total) as totalSales FROM invoices
      WHERE date <= date('now', '-30 days')
    ''');
    return (result.first["totalSales"] as num? ?? 0).toInt();
  }

  static Future<int> getPastSupplierCount() async {
    final dbClient = await db;
    final result = await dbClient.rawQuery('''
      SELECT COUNT(*) as count FROM suppliers
      WHERE created_at <= date('now', '-30 days')
    ''');
    return (result.first["count"] as num? ?? 0).toInt();
  }

  static Future<int> getPastLowStockCount() async {
    final dbClient = await db;
    final result = await dbClient.rawQuery('''
      SELECT COUNT(*) as count FROM products
      WHERE quantity <= 5 AND created_at <= date('now', '-30 days')
    ''');
    return (result.first["count"] as num? ?? 0).toInt();
  }

  static Future<Map<String, dynamic>> getInventoryOverview() async {
    final dbClient = await db;

    final result = await dbClient.rawQuery('''
      SELECT
        COUNT(*) AS totalItems,
        COALESCE(SUM(quantity * selling_price), 0) AS totalValue
      FROM products
    ''');

    final row = result.first;
    return {
      'totalItems': (row['totalItems'] as int?) ?? 0,
      'totalValue': (row['totalValue'] as num?)?.toDouble() ?? 0.0,
    };
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final dbClient = await db;
    return await dbClient.query('users', orderBy: 'id ASC');
  }

  static Future<bool> addStaffMember({
    required String name,
    required String role,
    required String email,
    required String password,
    required String phone,
  }) async {
    final dbClient = await db;
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

  static Future<Map<String, int>> getInventorySummary() async {
    final dbClient = await db;
    final all = await dbClient.rawQuery("SELECT COUNT(*) as c FROM products");
    final low = await dbClient.rawQuery(
      "SELECT COUNT(*) as c FROM products WHERE quantity > 0 AND quantity <= lsl",
    );
    final out = await dbClient.rawQuery(
      "SELECT COUNT(*) as c FROM products WHERE quantity <= 0",
    );
    final expiring = await dbClient.rawQuery('''
      SELECT COUNT(*) as c FROM products
      WHERE expiry_date IS NOT NULL
        AND expiry_date != ''
        AND date(expiry_date) <= date('now', '+30 day')
    ''');

    return {
      'all': (all.first['c'] as num? ?? 0).toInt(),
      'low': (low.first['c'] as num? ?? 0).toInt(),
      'out': (out.first['c'] as num? ?? 0).toInt(),
      'expiring': (expiring.first['c'] as num? ?? 0).toInt(),
    };
  }

  static Future<List<Map<String, dynamic>>> getProductsFiltered({
    String filter = 'all',
    String query = '',
    String sortBy = 'name_asc',
  }) async {
    final dbClient = await db;
    String where = '1=1';
    List<dynamic> args = [];

    if (filter == 'low') {
      where += ' AND quantity > 0 AND quantity <= lsl';
    } else if (filter == 'out') {
      where += ' AND quantity <= 0';
    } else if (filter == 'expiring') {
      where +=
          " AND expiry_date IS NOT NULL AND expiry_date != '' AND date(expiry_date) <= date('now', '+30 day')";
    }

    if (query.trim().isNotEmpty) {
      where += ' AND (name LIKE ? OR barcode LIKE ? OR hsn_code LIKE ?)';
      args.addAll(['%$query%', '%$query%', '%$query%']);
    }

    String orderByClause = 'name ASC';
    if (sortBy == 'stock_asc') {
      orderByClause = 'quantity ASC';
    } else if (sortBy == 'value_desc') {
      orderByClause = '(quantity * selling_price) DESC';
    } else {
      orderByClause = 'name ASC';
    }

    return await dbClient.query(
      'products',
      where: where,
      whereArgs: args,
      orderBy: orderByClause,
    );
  }

  static Future<void> stockInTransaction({
    required int productId,
    required int quantity,
    required double unitCost,
    required String reason,
    String reference = '',
    String note = '',
    String warehouse = 'Main store',
  }) async {
    final dbClient = await db;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
        "UPDATE products SET quantity = quantity + ?, purchase_price = ? WHERE id = ?",
        [quantity, unitCost, productId],
      );

      await txn.insert('stock_transactions', {
        'productId': productId,
        'type': 'in',
        'quantity': quantity,
        'unitCost': unitCost,
        'reason': reason,
        'reference': reference,
        'note': note,
        'warehouse': warehouse,
        'date': DateTime.now().toIso8601String(),
      });
    });
  }

  static Future<bool> stockOutTransaction({
    required int productId,
    required int quantity,
    required String reason,
    required String note,
    String warehouse = 'Main store',
  }) async {
    final dbClient = await db;
    final product = await dbClient.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (product.isEmpty) return false;

    final currentQty = (product.first['quantity'] as num? ?? 0).toInt();
    if (currentQty < quantity) return false;

    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
        "UPDATE products SET quantity = quantity - ? WHERE id = ?",
        [quantity, productId],
      );

      await txn.insert('stock_transactions', {
        'productId': productId,
        'type': 'out',
        'quantity': quantity,
        'unitCost': 0,
        'reason': reason,
        'reference': '',
        'note': note,
        'warehouse': warehouse,
        'date': DateTime.now().toIso8601String(),
      });
    });
    return true;
  }

  static Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final dbClient = await db;
    return await dbClient.rawQuery('''
      SELECT *,
        (lsl * 2) - quantity AS suggestedQty
      FROM products
      WHERE quantity <= lsl
      ORDER BY quantity ASC
    ''');
  }

  static Future<double> getLowStockRestockValue() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery('''
      SELECT SUM((lsl * 2 - quantity) * purchase_price) as total
      FROM products
      WHERE quantity <= lsl
    ''');
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<List<Map<String, dynamic>>> searchProductsByName(
    String query,
  ) async {
    final dbClient = await db;
    if (query.trim().isEmpty) return [];

    return await dbClient.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 10,
    );
  }

  static Future<List<Map<String, dynamic>>> getProductMovements(
    int productId,
  ) async {
    final dbClient = await db;
    final rows = await dbClient.rawQuery(
      '''
      SELECT id, type, quantity, unitCost, reason, reference, note, warehouse, date
      FROM stock_transactions
      WHERE productId = ?
      ORDER BY date ASC
    ''',
      [productId],
    );

    final product = await dbClient.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (product.isEmpty) return [];

    int currentQty = (product.first['quantity'] as num? ?? 0).toInt();
    final result = <Map<String, dynamic>>[];
    int runningBalance = currentQty;

    for (int i = rows.length - 1; i >= 0; i--) {
      final row = Map<String, dynamic>.from(rows[i]);
      row['running_balance'] = runningBalance;

      final qty = (row['quantity'] as num? ?? 0).toInt();
      if (row['type'] == 'in') {
        runningBalance -= qty;
      } else {
        runningBalance += qty;
      }
      result.insert(0, row);
    }
    return result.reversed.toList();
  }

  static Future<List<Map<String, dynamic>>> getSuppliersList() async {
    final dbClient = await db;
    return await dbClient.query('suppliers', orderBy: 'supplierName ASC');
  }

  static Future<int> createPurchaseOrder({
    required int supplierId,
    required List<Map<String, dynamic>> items,
    required DateTime expectedDelivery,
    required String status,
  }) async {
    final dbClient = await db;
    return await dbClient.transaction<int>((txn) async {
      final poId = await txn.insert('purchase_orders', {
        'supplierId': supplierId,
        'status': status,
        'orderedAt': DateTime.now().toIso8601String(),
        'expectedDelivery': expectedDelivery.toIso8601String(),
      });

      for (final item in items) {
        await txn.insert('purchase_order_items', {
          'poId': poId,
          'productId': item['productId'],
          'name': item['name'],
          'unit': item['unit'],
          'orderedQty': item['qty'],
          'unitPrice': item['unitPrice'],
          'receivedQty': 0,
        });
      }
      return poId;
    });
  }

  static Future<Map<String, dynamic>> getPurchaseOrderDetail(int poId) async {
    final dbClient = await db;
    final poRows = await dbClient.rawQuery(
      '''
      SELECT po.*, s.supplierName AS supplierName
      FROM purchase_orders po
      LEFT JOIN suppliers s ON s.id = po.supplierId
      WHERE po.id = ?
    ''',
      [poId],
    );

    final items = await dbClient.query(
      'purchase_order_items',
      where: 'poId = ?',
      whereArgs: [poId],
    );

    return {if (poRows.isNotEmpty) ...poRows.first, 'items': items};
  }

  static Future<List<Map<String, dynamic>>> getOpenPurchaseOrders() async {
    final dbClient = await db;
    return await dbClient.rawQuery('''
      SELECT po.*, s.supplierName AS supplierName
      FROM purchase_orders po
      LEFT JOIN suppliers s ON s.id = po.supplierId
      WHERE po.status IN ('sent', 'partial')
      ORDER BY po.orderedAt DESC
    ''');
  }

  static Future<void> reportPurchaseOrderIssue({
    required int poId,
    required String note,
  }) async {
    final dbClient = await db;
    await dbClient.insert('purchase_order_issues', {
      'poId': poId,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> receivePurchaseOrder({
    required int poId,
    required List<Map<String, dynamic>> items,
  }) async {
    final dbClient = await db;
    await dbClient.transaction((txn) async {
      var allFull = true;

      for (final item in items) {
        final receivedQty = (item['receivedQty'] as num? ?? 0).toInt();

        await txn.update(
          'purchase_order_items',
          {'receivedQty': receivedQty},
          where: 'id = ?',
          whereArgs: [item['id']],
        );

        if (item['productId'] != null && receivedQty > 0) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [receivedQty, item['productId']],
          );
        }

        final row = await txn.query(
          'purchase_order_items',
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        final orderedQty = (row.first['orderedQty'] as num? ?? 0).toInt();
        if (receivedQty < orderedQty) allFull = false;
      }

      await txn.update(
        'purchase_orders',
        {
          'status': allFull ? 'received' : 'partial',
          'receivedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [poId],
      );
    });
  }

  static Future<int> updateSupplierFull({
    required int id,
    required String supplierName,
    required String contactNumber,
    required String category,
    String paymentTerms = '',
  }) async {
    final dbClient = await db;
    return await dbClient.update(
      'suppliers',
      {
        'supplierName': supplierName,
        'contactNumber': contactNumber,
        'category': category,
        'paymentTerms': paymentTerms,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getCustomers() async {
    final dbClient = await db;
    return await dbClient.query('customers', orderBy: 'name ASC');
  }

  static Future<int> addCustomer({
    required String name,
    String phone = '',
    String email = '',
    String address = '',
  }) async {
    final dbClient = await db;
    return await dbClient.insert('customers', {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    });
  }

  static Future<void> recordSplitPayment({
    required int invoiceId,
    required double cashAmount,
    required double upiAmount,
    required double balanceDue,
    int? customerId,
    String? customerName,
  }) async {
    final dbClient = await db;
    await dbClient.transaction((txn) async {
      await txn.insert('invoice_payments', {
        'invoiceId': invoiceId,
        'cashAmount': cashAmount,
        'upiAmount': upiAmount,
        'balanceDue': balanceDue,
        'customerId': customerId,
        'customerName': customerName,
        'paidAt': DateTime.now().toIso8601String(),
      });

      await txn.update(
        'invoices',
        {
          'status': balanceDue > 0 ? 'partial' : 'paid',
          'balanceDue': balanceDue,
          'customerId': customerId,
          'customerName': customerName,
          'paymentMethod': cashAmount > 0 && upiAmount > 0
              ? 'Split'
              : (upiAmount > 0 ? 'UPI' : 'Cash'),
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    });
  }

  // ==========================================
  // 🔹 MISSING METHODS FOR MORE & CUSTOMERS
  // ==========================================

  static Future<Map<String, dynamic>?> getStoreProfile() async {
    return await getProfile();
  }

  static Future<double> getSupplierPayableTotal() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery(
      "SELECT SUM(dueAmount) as total FROM suppliers",
    );
    return (res.first["total"] as num?)?.toDouble() ?? 0.0;
  }

  static Future<double> getCustomerDueTotal() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery(
      "SELECT SUM(balanceDue) as total FROM invoices WHERE balanceDue > 0",
    );
    return (res.first["total"] as num?)?.toDouble() ?? 0.0;
  }

  static Future<int> getCustomerCount() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery(
      "SELECT COUNT(*) as count FROM customers",
    );
    return (res.first["count"] as num? ?? 0).toInt();
  }

  static Future<int> getOpenPurchaseOrderCount() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery(
      "SELECT COUNT(*) as count FROM purchase_orders WHERE status IN ('sent', 'partial')",
    );
    return (res.first["count"] as num? ?? 0).toInt();
  }

  static Future<int> getDuePurchaseOrderCount() async {
    final dbClient = await db;
    final res = await dbClient.rawQuery(
      "SELECT COUNT(*) as count FROM purchase_orders WHERE status IN ('sent', 'partial') AND date(expectedDelivery) < date('now')",
    );
    return (res.first["count"] as num? ?? 0).toInt();
  }

  static Future<List<Map<String, dynamic>>> getCustomersWithSummary() async {
    final dbClient = await db;
    return await dbClient.rawQuery('''
      SELECT c.*, COALESCE(SUM(i.balanceDue), 0) as balanceDue
      FROM customers c
      LEFT JOIN invoices i ON c.id = i.customerId
      GROUP BY c.id
      ORDER BY c.name ASC
    ''');
  }

  static Future<double> getTotalCustomerReceivable() async {
    return await getCustomerDueTotal();
  }

  // ==========================================
  // 🔹 FLEXIBLE CUSTOMER METHODS
  // ==========================================

  static Future<int> addCustomerFull({
    required String name,
    String phone = '',
    String email = '',
    String address = '',
    String gender = '',
  }) async {
    final dbClient = await db;
    return await dbClient.insert('customers', {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gender': gender,
    });
  }

  static Future<int> updateCustomerFull({
    required int id,
    required String name,
    String phone = '',
    String email = '',
    String address = '',
    String gender = '',
  }) async {
    final dbClient = await db;
    return await dbClient.update(
      'customers',
      {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'gender': gender,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteCustomerById(int id) async {
    final dbClient = await db;
    return await dbClient.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // 🧪 SEED TEST PRODUCTS (runs once — skips if products already exist)
  // =========================
  static Future<void> _seedTestProducts(Database db) async {
    final existing = await db.rawQuery("SELECT COUNT(*) as c FROM products");
    final count = (existing.first['c'] as num? ?? 0).toInt();
    if (count > 0) return;

    final testProducts = <Map<String, dynamic>>[
      {
        'name': 'Basmati Rice 5kg',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '1006',
        'supplier': 'Divya',
        'expiry_date': '2027-01-15',
        'purchase_price': 320.0,
        'selling_price': 380.0,
        'quantity': 60,
        'lsl': 10,
        'unit': 'kg',
        'description': 'Premium long-grain basmati rice',
        'barcode': '890100000001',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Sunflower Oil 1L',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '1512',
        'supplier': 'Rajesh',
        'expiry_date': '2027-03-10',
        'purchase_price': 140.0,
        'selling_price': 165.0,
        'quantity': 80,
        'lsl': 15,
        'unit': 'ltr',
        'description': 'Refined sunflower cooking oil',
        'barcode': '890100000002',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Toor Dal 1kg',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '0713',
        'supplier': 'Divya',
        'expiry_date': '2026-12-20',
        'purchase_price': 110.0,
        'selling_price': 130.0,
        'quantity': 45,
        'lsl': 10,
        'unit': 'kg',
        'description': 'Unpolished toor dal',
        'barcode': '890100000003',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Wheat Atta 5kg',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '1101',
        'supplier': 'Rajesh',
        'expiry_date': '2027-02-05',
        'purchase_price': 210.0,
        'selling_price': 245.0,
        'quantity': 55,
        'lsl': 10,
        'unit': 'kg',
        'description': 'Chakki fresh atta',
        'barcode': '890100000004',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Refined Sugar 1kg',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '1701',
        'supplier': 'Divya',
        'expiry_date': '2028-01-01',
        'purchase_price': 42.0,
        'selling_price': 50.0,
        'quantity': 90,
        'lsl': 20,
        'unit': 'kg',
        'description': 'Fine refined white sugar',
        'barcode': '890100000005',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Iodised Salt 1kg',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '2501',
        'supplier': 'Vignesh',
        'expiry_date': '2028-06-01',
        'purchase_price': 18.0,
        'selling_price': 22.0,
        'quantity': 100,
        'lsl': 20,
        'unit': 'kg',
        'description': 'Free-flow iodised salt',
        'barcode': '890100000006',
        'image_path': '',
        'discount': 5.0,
      },
      {
        'name': 'Tea Powder 250g',
        'category': 'Food',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '0902',
        'supplier': 'Naveen',
        'expiry_date': '2027-05-10',
        'purchase_price': 95.0,
        'selling_price': 120.0,
        'quantity': 40,
        'lsl': 10,
        'unit': 'pcs',
        'description': 'Strong CTC blend tea',
        'barcode': '890100000007',
        'image_path': '',
        'discount': 10.0,
      },
      {
        'name': 'Filter Coffee Powder 200g',
        'category': 'Food',
        'sgst': 2.5,
        'cgst': 2.5,
        'hsn_code': '0901',
        'supplier': 'Naveen',
        'expiry_date': '2027-04-15',
        'purchase_price': 130.0,
        'selling_price': 160.0,
        'quantity': 35,
        'lsl': 10,
        'unit': 'pcs',
        'description': 'South Indian filter coffee blend',
        'barcode': '890100000008',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Glucose Biscuits Pack',
        'category': 'Food',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '1905',
        'supplier': 'Vignesh',
        'expiry_date': '2026-11-30',
        'purchase_price': 18.0,
        'selling_price': 25.0,
        'quantity': 70,
        'lsl': 15,
        'unit': 'pcs',
        'description': 'Classic glucose biscuits',
        'barcode': '890100000009',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Chocolate Bar 50g',
        'category': 'Food',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '1806',
        'supplier': 'Vignesh',
        'expiry_date': '2026-10-20',
        'purchase_price': 15.0,
        'selling_price': 25.0,
        'quantity': 8,
        'lsl': 20,
        'unit': 'pcs',
        'description': 'Milk chocolate bar',
        'barcode': '890100000010',
        'image_path': '',
        'discount': 15.0,
      },
      {
        'name': 'Bathing Soap',
        'category': 'Beauty',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '3401',
        'supplier': 'Naveen',
        'expiry_date': '2028-02-01',
        'purchase_price': 22.0,
        'selling_price': 30.0,
        'quantity': 6,
        'lsl': 15,
        'unit': 'pcs',
        'description': 'Moisturizing bathing soap',
        'barcode': '890100000011',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Shampoo Sachet Box',
        'category': 'Beauty',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '3305',
        'supplier': 'Naveen',
        'expiry_date': '2027-09-01',
        'purchase_price': 55.0,
        'selling_price': 75.0,
        'quantity': 4,
        'lsl': 10,
        'unit': 'pcs',
        'description': 'Box of 12 shampoo sachets',
        'barcode': '890100000012',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Toothpaste 100g',
        'category': 'Beauty',
        'sgst': 9.0,
        'cgst': 9.0,
        'hsn_code': '3306',
        'supplier': 'Naveen',
        'expiry_date': '2027-08-15',
        'purchase_price': 48.0,
        'selling_price': 62.0,
        'quantity': 5,
        'lsl': 12,
        'unit': 'pcs',
        'description': 'Fluoride toothpaste',
        'barcode': '890100000013',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Detergent Powder 1kg',
        'category': 'Home Appliances',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '3402',
        'supplier': 'Naveen',
        'expiry_date': '2028-03-01',
        'purchase_price': 65.0,
        'selling_price': 85.0,
        'quantity': 3,
        'lsl': 10,
        'unit': 'kg',
        'description': 'Stain-removing detergent powder',
        'barcode': '890100000014',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Spice Mix Combo',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '0910',
        'supplier': 'Vignesh',
        'expiry_date': '2027-01-20',
        'purchase_price': 40.0,
        'selling_price': 55.0,
        'quantity': 2,
        'lsl': 8,
        'unit': 'pcs',
        'description': 'Combo of everyday spices',
        'barcode': '890100000015',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Spice Mix Combo',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '0910',
        'supplier': 'Vignesh',
        'expiry_date': '2027-01-20',
        'purchase_price': 40.0,
        'selling_price': 55.0,
        'quantity': 2,
        'lsl': 8,
        'unit': 'pcs',
        'description': 'Combo of everyday spices',
        'barcode': '890100000015',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Moong Dal 1kg',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '0713',
        'supplier': 'Vignesh',
        'expiry_date': '2026-12-01',
        'purchase_price': 115.0,
        'selling_price': 135.0,
        'quantity': 0,
        'lsl': 10,
        'unit': 'kg',
        'description': 'Split yellow moong dal',
        'barcode': '890100000016',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Rice Bran Oil 1L',
        'category': 'Grocery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '1515',
        'supplier': 'Vignesh',
        'expiry_date': '2027-02-28',
        'purchase_price': 150.0,
        'selling_price': 175.0,
        'quantity': 0,
        'lsl': 12,
        'unit': 'ltr',
        'description': 'Heart-healthy rice bran oil',
        'barcode': '890100000017',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Notebook 200pg',
        'category': 'Stationery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '4820',
        'supplier': 'Rajesh',
        'expiry_date': '',
        'purchase_price': 25.0,
        'selling_price': 35.0,
        'quantity': 0,
        'lsl': 20,
        'unit': 'pcs',
        'description': 'Ruled 200-page notebook',
        'barcode': '890100000018',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Ball Pen Pack of 5',
        'category': 'Stationery',
        'sgst': 0.0,
        'cgst': 0.0,
        'hsn_code': '9608',
        'supplier': 'Rajesh',
        'expiry_date': '',
        'purchase_price': 20.0,
        'selling_price': 30.0,
        'quantity': 0,
        'lsl': 15,
        'unit': 'pcs',
        'description': 'Smooth-writing ball pens, pack of 5',
        'barcode': '890100000019',
        'image_path': '',
        'discount': 0.0,
      },
      {
        'name': 'Milk Powder 500g',
        'category': 'Food',
        'sgst': 6.0,
        'cgst': 6.0,
        'hsn_code': '0402',
        'supplier': 'Rajesh',
        'expiry_date': '2026-09-30',
        'purchase_price': 210.0,
        'selling_price': 250.0,
        'quantity': 0,
        'lsl': 10,
        'unit': 'pcs',
        'description': 'Full cream milk powder',
        'barcode': '890100000020',
        'image_path': '',
        'discount': 0.0,
      },
    ];

    for (final p in testProducts) {
      await db.insert('products', p);
    }
  }

  // =========================================================
  // 🧪 SEED TEST SUPPLIERS (Aligned with UI Fields & Products)
  // =========================================================
  static Future<void> _seedTestSuppliers(Database db) async {
    final existing = await db.rawQuery("SELECT COUNT(*) as c FROM suppliers");
    final count = (existing.first['c'] as num? ?? 0).toInt();
    if (count > 0) return;

    final testSuppliers = <Map<String, dynamic>>[
      {
        'supplierName': 'Vignesh',
        'companyName': 'Vignesh',
        'contactNumber': '7010164362',
        'email': 'vignesh@test.com',
        'category': 'Grocery, Food',
        'gst': '33AAHCC1098Q1Z9',
        'address': 'Salt Pan Road, Tuticorin',
      },
      {
        'supplierName': 'Naveen',
        'companyName': 'Naveen',
        'contactNumber': '9488464414',
        'email': 'naveen@test.com',
        'category': 'Food, Beauty, Home Appliances',
        'gst': '33AAEDD2109N1Z4',
        'address': '78 Distribution Hub, Trichy',
      },
      {
        'supplierName': 'Divya',
        'companyName': 'Divya',
        'contactNumber': '8825853188',
        'email': 'divya@test.com',
        'category': 'Grocery',
        'gst': '33AABCS1234F1Z5',
        'address': 'No. 12, Mount Road, Chennai',
      },
      {
        'supplierName': 'Rajesh',
        'companyName': 'Rajesh',
        'contactNumber': '8667491369',
        'email': 'rajesh@test.com',
        'category': 'Grocery, Stationery, Food',
        'gst': '33AACFG5678K1Z2',
        'address': 'Plot 5, Industrial Estate, Coimbatore',
      },
    ];

    for (final s in testSuppliers) {
      await db.insert('suppliers', s);
    }
  }

  // ==========================================
  // 📥 BULK IMPORT PRODUCTS FROM CSV
  // ==========================================
  static Future<int> importProductsFromCsv(List<List<dynamic>> csvRows) async {
    final dbClient = await db;
    int importedCount = 0;

    if (csvRows.isEmpty) return 0;

    // Optional: If your CSV includes a header row (e.g., Name, Category...),
    // skip index 0 so it doesn't try to parse words as numbers.
    final starterIndex =
        (csvRows.first.first.toString().toLowerCase().contains('name')) ? 1 : 0;

    await dbClient.transaction((txn) async {
      for (int i = starterIndex; i < csvRows.length; i++) {
        final row = csvRows[i];
        if (row.length < 5) continue; // Skip incomplete data lines Safely

        // Map column data structures cleanly with resilient fallbacks
        final String name = row[0]?.toString() ?? 'Unnamed Item';
        final String category = row[1]?.toString() ?? 'General';
        final double purchasePrice =
            double.tryParse(row[2]?.toString() ?? '0') ?? 0.0;
        final double sellingPrice =
            double.tryParse(row[3]?.toString() ?? '0') ?? 0.0;
        final int quantity = int.tryParse(row[4]?.toString() ?? '0') ?? 0;

        // Extended custom table mappings if provided in additional columns
        final String unit = row.length > 5
            ? row[5]?.toString() ?? 'pcs'
            : 'pcs';
        final String barcode = row.length > 6 ? row[6]?.toString() ?? '' : '';
        final String hsnCode = row.length > 7 ? row[7]?.toString() ?? '' : '';
        final double lsl = row.length > 8
            ? double.tryParse(row[8]?.toString() ?? '5') ?? 5.0
            : 5.0;

        // Perform clean INSERT into your exact products data matrix schema
        await txn.insert('products', {
          'name': name,
          'category': category,
          'purchase_price': purchasePrice,
          'selling_price': sellingPrice,
          'quantity': quantity,
          'unit': unit,
          'barcode': barcode,
          'hsn_code': hsnCode,
          'lsl': lsl.toInt(),
          'sgst': 0.0,
          'cgst': 0.0,
          'supplier': '',
          'expiry_date': '',
          'description': 'Imported via CSV',
          'image_path': '',
          'discount': 0.0,
          'warehouse': 'Main store',
        });
        importedCount++;
      }
    });

    return importedCount;
  }
}
