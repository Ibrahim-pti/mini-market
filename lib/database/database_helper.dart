import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/item_model.dart';
import '../models/shift_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mini_market.db');
    return _database!;
  }

  Future<String> getDatabasePathStr() async {
    final dbPath = await getApplicationSupportDirectory();
    return join(dbPath.path, 'mini_market.db');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Flushes the Write-Ahead-Log into the main .db file so a file copy
  /// contains every recent change. Critical for reliable backups.
  Future<void> checkpoint() async {
    try {
      final db = await database;
      await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {
      // Not in WAL mode (or already flushed) — copy of the .db is still complete.
    }
  }

  Future<Database> _initDB(String filePath) async {
    // Ensure ffi is initialized for desktop
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationSupportDirectory();
    final path = join(dbPath.path, filePath);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  barcode TEXT UNIQUE,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  cost_price REAL DEFAULT 0.0,
  quantity INTEGER NOT NULL,
  image_path TEXT,
  expiry_date TEXT,
  wholesale_price REAL DEFAULT 0.0,
  category TEXT,
  unit_type TEXT DEFAULT 'دانە'
)
''');

    await db.execute('''
CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  total_amount REAL NOT NULL,
  date TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE NO ACTION
)
''');

    await db.execute('''
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE shifts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  start_time TEXT NOT NULL,
  end_time TEXT,
  starting_cash REAL NOT NULL,
  expected_ending_cash REAL,
  actual_ending_cash REAL,
  status TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  balance REAL DEFAULT 0.0,
  notes TEXT
)
''');

    await db.execute('''
CREATE TABLE suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  company TEXT,
  balance REAL DEFAULT 0.0
)
''');

    await db.execute('''
CREATE TABLE debts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  personName TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  notes TEXT,
  date TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE employees (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  role TEXT,
  phone TEXT,
  salary REAL DEFAULT 0.0
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  total_amount REAL NOT NULL,
  date TEXT NOT NULL
)
''');
      await db.execute('''
CREATE TABLE sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  price_at_time REAL NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
)
''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE items ADD COLUMN cost_price REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE sale_items ADD COLUMN cost_at_time REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE items ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE items ADD COLUMN expiry_date TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN wholesale_price REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE items ADD COLUMN category TEXT');
      await db.execute('ALTER TABLE items ADD COLUMN unit_type TEXT DEFAULT "دانە"');
    }
    if (oldVersion < 5) {
      await db.execute('''
CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL
)
''');
    }
    if (oldVersion < 6) {
      await db.execute('''
CREATE TABLE shifts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  start_time TEXT NOT NULL,
  end_time TEXT,
  starting_cash REAL NOT NULL,
  expected_ending_cash REAL,
  actual_ending_cash REAL,
  status TEXT NOT NULL
)
''');
    }
    if (oldVersion < 7) {
      await db.execute('''
CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  balance REAL DEFAULT 0.0,
  notes TEXT
)
''');

      await db.execute('''
CREATE TABLE suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  company TEXT,
  balance REAL DEFAULT 0.0
)
''');

      await db.execute('''
CREATE TABLE debts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  personName TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  notes TEXT,
  date TEXT NOT NULL
)
''');

      await db.execute('''
CREATE TABLE employees (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  role TEXT,
  phone TEXT,
  salary REAL DEFAULT 0.0
)
''');
    }
    if (oldVersion < 8) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS shifts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  start_time TEXT NOT NULL,
  end_time TEXT,
  starting_cash REAL NOT NULL,
  expected_ending_cash REAL,
  actual_ending_cash REAL,
  status TEXT NOT NULL
)
''');
    }
  }

  Future<int> insertItem(Item item) async {
    final db = await instance.database;
    return await db.insert('items', item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    final db = await instance.database;
    final result = await db.query('items', orderBy: 'name ASC');
    return result.map((json) => Item.fromMap(json)).toList();
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    final db = await instance.database;
    final result = await db.query(
      'items',
      where: 'barcode = ? COLLATE NOCASE',
      whereArgs: [barcode],
    );

    if (result.isNotEmpty) {
      return Item.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int> updateItem(Item item) async {
    final db = await instance.database;
    return db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===================== SHIFTS =====================
  Future<int> insertShift(Shift shift) async {
    final db = await instance.database;
    return await db.insert('shifts', shift.toMap());
  }

  Future<int> updateShift(Shift shift) async {
    final db = await instance.database;
    return await db.update('shifts', shift.toMap(), where: 'id = ?', whereArgs: [shift.id]);
  }

  Future<Shift?> getOpenShift() async {
    final db = await instance.database;
    final maps = await db.query('shifts', where: 'status = ?', whereArgs: ['open'], limit: 1);
    if (maps.isNotEmpty) {
      return Shift.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Shift>> getAllShifts() async {
    final db = await instance.database;
    final result = await db.query('shifts', orderBy: 'id DESC');
    return result.map((json) => Shift.fromMap(json)).toList();
  }

  // ===================== ITEMS =====================
  Future<int> insertSale(double totalAmount, List<Map<String, dynamic>> saleItems) async {
    final db = await instance.database;
    
    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', {
        'total_amount': totalAmount,
        'date': DateTime.now().toIso8601String(),
      });

      for (var item in saleItems) {
        item['sale_id'] = saleId;
        await txn.insert('sale_items', item);
      }
      return saleId;
    });
  }

  // Backup and Restore Methods
  Future<String> getDatabasePath() async {
    final dbPath = await getApplicationSupportDirectory();
    return join(dbPath.path, 'mini_market.db');
  }
}
