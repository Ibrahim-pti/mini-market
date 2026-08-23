import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../models/cart_item.dart';
import '../models/sale_model.dart';
import '../models/expense_model.dart';
import '../models/shift_model.dart';
import '../models/daily_report.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';
import '../database/database_helper.dart';
import '../services/backup_service.dart';
import '../utils/barcode_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryProvider with ChangeNotifier {
  List<Item> _items = [];
  List<Item> _searchResults = [];
  bool _isLoading = false;
  Shift? _currentShift;

  double _dollarRate = 1500.0;
  Timer? _dollarApiTimer;

  List<Item> get items => _items;
  List<Item> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  Shift? get currentShift => _currentShift;
  double get dollarRate => _dollarRate;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Timer? _autoBackupTimer;

  InventoryProvider() {
    loadItems();
    loadCurrentShift();
    loadDollarRate().then((_) {
      _startDollarApiTimer();
    });
    _startAutoBackup();
  }

  @override
  void dispose() {
    _dollarApiTimer?.cancel();
    _autoBackupTimer?.cancel();
    super.dispose();
  }

  /// Runs an automatic backup on launch, then checks every 30 minutes so the
  /// second daily (evening) snapshot is captured even if the app stays open.
  void _startAutoBackup() {
    BackupService.instance.runAutoBackupIfDue();
    _autoBackupTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      BackupService.instance.runAutoBackupIfDue();
    });
  }

  void _startDollarApiTimer() {
    fetchDollarRateFromApi();
    // Update every 2 minutes
    _dollarApiTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      fetchDollarRateFromApi();
    });
  }

  Future<void> fetchDollarRateFromApi() async {
    try {
      final response =
          await http.get(Uri.parse('https://amro.tech/exchangerate'));
      if (response.statusCode == 200) {
        final body = response.body;
        double? newRate;

        // Since this is an HTML page, we extract the rate using Regex.
        // Looking for &quot;usDollar&quot;:155250 or "usDollar":155250
        final regex =
            RegExp(r'(?:&quot;|")usDollar(?:&quot;|")\s*:\s*([\d\.]+)');
        final match = regex.firstMatch(body);

        if (match != null && match.groupCount >= 1) {
          newRate = double.tryParse(match.group(1)!);
        } else {
          // Fallback to IQD key
          final regexIqd =
              RegExp(r'(?:&quot;|")IQD(?:&quot;|")\s*:\s*([\d\.]+)');
          final matchIqd = regexIqd.firstMatch(body);
          if (matchIqd != null && matchIqd.groupCount >= 1) {
            newRate = double.tryParse(matchIqd.group(1)!);
          }
        }

        if (newRate != null && newRate > 0) {
          if (_dollarRate != newRate) {
            await updateDollarRate(newRate);
            print('Dollar rate updated from amro.tech: $newRate');
          }
        }
      }
    } catch (e) {
      print('Error fetching dollar rate from amro.tech: $e');
    }
  }

  Future<void> loadDollarRate() async {
    final prefs = await SharedPreferences.getInstance();
    _dollarRate = prefs.getDouble('dollarRate') ?? 1500.0;
    notifyListeners();
  }

  Future<void> updateDollarRate(double newRate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dollarRate', newRate);
    _dollarRate = newRate;
    notifyListeners();
  }

  Future<void> loadCurrentShift() async {
    _currentShift = await _dbHelper.getOpenShift();
    notifyListeners();
  }

  /// Wipes every table in the database and reloads the provider state.
  Future<void> resetAllData() async {
    await _dbHelper.resetAllData();
    _items = [];
    _searchResults = [];
    _currentShift = null;
    notifyListeners();
  }

  Future<void> openShift(double startingCash) async {
    final shift = Shift(
      startTime: DateTime.now().toIso8601String(),
      startingCash: startingCash,
    );
    await _dbHelper.insertShift(shift);
    await loadCurrentShift();
  }

  Future<void> closeShift(double actualCash) async {
    if (_currentShift == null) return;
    final db = await _dbHelper.database;
    final start = _currentShift!.startTime;

    final salesRes = await db.rawQuery(
        'SELECT SUM(total_amount) as sum FROM sales WHERE date >= ?', [start]);
    double totalSales = (salesRes.isNotEmpty && salesRes.first['sum'] != null)
        ? salesRes.first['sum'] as double
        : 0.0;

    final expRes = await db.rawQuery(
        'SELECT SUM(amount) as sum FROM expenses WHERE date >= ?', [start]);
    double totalExp = (expRes.isNotEmpty && expRes.first['sum'] != null)
        ? expRes.first['sum'] as double
        : 0.0;

    _currentShift!.endTime = DateTime.now().toIso8601String();
    _currentShift!.expectedEndingCash =
        _currentShift!.startingCash + totalSales - totalExp;
    _currentShift!.actualEndingCash = actualCash;
    _currentShift!.status = 'closed';

    await _dbHelper.updateShift(_currentShift!);
    await loadCurrentShift();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _items = await _dbHelper.getAllItems();
    _searchResults = _items;

    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      _searchResults = _items;
    } else {
      final normalizedQuery = normalizeBarcode(query);
      _searchResults = _items
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              normalizeBarcode(item.barcode).contains(normalizedQuery))
          .toList();
    }
    notifyListeners();
  }

  Future<bool> addItem(Item item) async {
    try {
      final existingItem = await _dbHelper.getItemByBarcode(item.barcode);
      if (existingItem != null) {
        // Item exists, maybe just add quantity?
        // Let's return false indicating it already exists if we use this for strictly new items.
        return false;
      }
      await _dbHelper.insertItem(item);
      await loadItems();
      return true;
    } catch (e) {
      print("Error adding item: \$e");
      return false;
    }
  }

  Future<void> addItems(List<Item> newItems) async {
    for (var item in newItems) {
      final existingItem = await _dbHelper.getItemByBarcode(item.barcode);
      if (existingItem == null) {
        await _dbHelper.insertItem(item);
      }
    }
    await loadItems();
  }

  Future<void> updateItem(Item item) async {
    await _dbHelper.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await _dbHelper.deleteItem(id);
    await loadItems();
  }

  Future<void> increaseQuantity(Item item, {int amount = 1}) async {
    final updatedItem = item.copyWith(quantity: item.quantity + amount);
    await updateItem(updatedItem);
  }

  Future<void> decreaseQuantity(Item item, {int amount = 1}) async {
    if (item.quantity >= amount) {
      final updatedItem = item.copyWith(quantity: item.quantity - amount);
      await updateItem(updatedItem);
    }
  }

  // POS Scanner Method
  Future<Item?> scanItemForPOS(String barcode) async {
    return await _dbHelper.getItemByBarcode(barcode);
  }

  // Checkout process
  Future<int?> checkoutCart(List<CartItem> cart) async {
    if (cart.isEmpty) return null;

    double totalAmount = 0;
    List<Map<String, dynamic>> saleItems = [];

    for (var cartItem in cart) {
      totalAmount += cartItem.totalPrice;
      saleItems.add({
        'item_id': cartItem.item.id,
        'quantity': cartItem.quantity,
        'price': cartItem.item.price,
        'price_at_time': cartItem.item.price,
        'cost_price': cartItem.item.costPrice,
        'cost_at_time': cartItem.item.costPrice,
      });
      // Deduct inventory
      await decreaseQuantity(cartItem.item, amount: cartItem.quantity);
    }

    int saleId = await _dbHelper.insertSale(totalAmount, saleItems);
    await loadItems(); // Refresh inventory
    return saleId;
  }

  // Dashboard Stats
  Future<double> getTodayRevenue() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM sales WHERE date >= ?',
      [startOfDay],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  Future<int> getTodaySalesCount() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sales WHERE date >= ?',
      [startOfDay],
    );

    if (result.isNotEmpty && result.first['count'] != null) {
      return result.first['count'] as int;
    }
    return 0;
  }

  Future<double> getTodayProfit() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    // Profit = SUM( (price - cost_price) * quantity )
    try {
      final result = await db.rawQuery('''
        SELECT SUM((COALESCE(sale_items.price, sale_items.price_at_time, 0.0) - COALESCE(sale_items.cost_price, sale_items.cost_at_time, items.cost_price, 0.0)) * sale_items.quantity) as profit 
        FROM sale_items 
        INNER JOIN sales ON sales.id = sale_items.sale_id 
        LEFT JOIN items ON items.id = sale_items.item_id
        WHERE sales.date >= ?
      ''', [startOfDay]);

      if (result.isNotEmpty && result.first['profit'] != null) {
        return (result.first['profit'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Error getting today profit: $e');
    }
    return 0.0;
  }

  Future<double> getTodayExpenses() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date >= ?',
      [startOfDay],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as double;
    }
    return 0.0;
  }

  Future<List<Expense>> getTodayExpenseList() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await db.rawQuery(
      'SELECT * FROM expenses WHERE date >= ? ORDER BY date DESC',
      [startOfDay],
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    final db = await _dbHelper.database;
    await db.insert('expenses', expense.toMap());
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  List<Item> getLowStockItems() {
    return _items.where((item) => item.quantity < 5).toList();
  }

  Future<List<Map<String, dynamic>>> getTopSellingItems({int limit = 5}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT items.name, COALESCE(sale_items.price, sale_items.price_at_time, items.price) as price, SUM(sale_items.quantity) as total_sold
      FROM sale_items
      INNER JOIN items ON items.id = sale_items.item_id
      GROUP BY items.id
      ORDER BY total_sold DESC
      LIMIT ?
    ''', [limit]);
    return result;
  }

  Future<List<Sale>> getRecentSales({int limit = 5}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      orderBy: 'date DESC',
      limit: limit,
    );
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  Future<List<Sale>> getTodaySales() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    final result = await db.query(
      'sales',
      where: 'date >= ?',
      whereArgs: [startOfDay],
      orderBy: 'date DESC',
    );
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  /// Sales and debts grouped by day (newest first): revenue, profit, debt given & collected.
  Future<List<DailySalesReport>> getDailySalesReport() async {
    final db = await _dbHelper.database;

    try {
      // 1. Revenue + invoice count per day.
      final salesRows = await db.rawQuery('''
        SELECT substr(date, 1, 10) as day,
               COUNT(*) as count,
               SUM(total_amount) as total
        FROM sales
        WHERE date IS NOT NULL AND date != ''
        GROUP BY day
        ORDER BY day DESC
      ''');

      // 2. Profit per day (joins line items and items to get cost_price).
      final profitRows = await db.rawQuery('''
        SELECT substr(s.date, 1, 10) as day,
               SUM((COALESCE(si.price, si.price_at_time, 0.0) - COALESCE(si.cost_price, si.cost_at_time, items.cost_price, 0.0)) * si.quantity) as profit
        FROM sale_items si
        INNER JOIN sales s ON s.id = si.sale_id
        LEFT JOIN items ON items.id = si.item_id
        WHERE s.date IS NOT NULL AND s.date != ''
        GROUP BY day
      ''');

      // 3. Customer debts given per day.
      final debtRows = await db.rawQuery('''
        SELECT substr(date, 1, 10) as day,
               COUNT(*) as count,
               SUM(amount) as total
        FROM debts
        WHERE date IS NOT NULL AND date != '' AND type = 'customer'
        GROUP BY day
      ''');

      // 4. Debt payments collected per day.
      final paymentRows = await db.rawQuery('''
        SELECT substr(date, 1, 10) as day,
               SUM(amount) as total
        FROM debt_payments
        WHERE date IS NOT NULL AND date != ''
        GROUP BY day
      ''');

      final salesByDay = <String, Map<String, dynamic>>{
        for (final r in salesRows)
          if (r['day'] != null && r['day'].toString().isNotEmpty)
            r['day'].toString(): {
              'count': (r['count'] as num?)?.toInt() ?? 0,
              'total': (r['total'] as num?)?.toDouble() ?? 0.0,
            }
      };

      final profitByDay = <String, double>{
        for (final r in profitRows)
          if (r['day'] != null)
            (r['day'].toString()): (r['profit'] as num?)?.toDouble() ?? 0.0,
      };

      final debtByDay = <String, Map<String, dynamic>>{
        for (final r in debtRows)
          if (r['day'] != null && r['day'].toString().isNotEmpty)
            r['day'].toString(): {
              'count': (r['count'] as num?)?.toInt() ?? 0,
              'total': (r['total'] as num?)?.toDouble() ?? 0.0,
            }
      };

      final paymentByDay = <String, double>{
        for (final r in paymentRows)
          if (r['day'] != null)
            (r['day'].toString()): (r['total'] as num?)?.toDouble() ?? 0.0,
      };

      // Union of all unique days
      final allDays = <String>{
        ...salesByDay.keys,
        ...debtByDay.keys,
        ...paymentByDay.keys,
      }.toList()
        ..sort((a, b) => b.compareTo(a));

      return allDays.map((day) {
        final saleData = salesByDay[day];
        final debtData = debtByDay[day];
        return DailySalesReport(
          day: day,
          invoiceCount: saleData?['count'] ?? 0,
          total: saleData?['total'] ?? 0.0,
          profit: profitByDay[day] ?? 0.0,
          debtGiven: debtData?['total'] ?? 0.0,
          debtCount: debtData?['count'] ?? 0,
          debtCollected: paymentByDay[day] ?? 0.0,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting daily sales report: $e');
      return [];
    }
  }

  /// All customer debts recorded on a specific day ('YYYY-MM-DD').
  Future<List<Debt>> getDebtsForDay(String day) async {
    final db = await _dbHelper.database;
    try {
      final result = await db.rawQuery(
        'SELECT * FROM debts WHERE substr(date, 1, 10) = ? AND type = ? ORDER BY id DESC',
        [day, 'customer'],
      );
      return result.map((json) => Debt.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error getting debts for day: $e');
      return [];
    }
  }

  /// All debt payments collected on a specific day ('YYYY-MM-DD').
  Future<List<Map<String, dynamic>>> getDebtPaymentsForDay(String day) async {
    final db = await _dbHelper.database;
    try {
      final rows = await db.rawQuery('''
        SELECT dp.*, debts.personName as person_name, debts.phone as phone
        FROM debt_payments dp
        LEFT JOIN debts ON debts.id = dp.debt_id
        WHERE substr(dp.date, 1, 10) = ?
        ORDER BY dp.id DESC
      ''', [day]);
      return rows;
    } catch (e) {
      debugPrint('Error getting debt payments for day: $e');
      return [];
    }
  }

  /// All invoices (sales) recorded on a specific day ('YYYY-MM-DD').
  Future<List<Sale>> getSalesForDay(String day) async {
    final db = await _dbHelper.database;
    try {
      final result = await db.rawQuery(
        'SELECT * FROM sales WHERE substr(date, 1, 10) = ? ORDER BY date DESC',
        [day],
      );
      return result.map((json) => Sale.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error getting sales for day: $e');
      return [];
    }
  }

  /// The line items (products) of a single invoice.
  Future<List<SaleLineItem>> getSaleLineItems(int saleId) async {
    final db = await _dbHelper.database;
    try {
      final rows = await db.rawQuery('''
        SELECT items.name as name,
               sale_items.quantity as quantity,
               COALESCE(sale_items.price, sale_items.price_at_time, 0.0) as price
        FROM sale_items
        LEFT JOIN items ON items.id = sale_items.item_id
        WHERE sale_items.sale_id = ?
      ''', [saleId]);

      return rows
          .map((r) => SaleLineItem(
                name: (r['name'] as String?) ?? 'کاڵای سڕاوە',
                quantity: (r['quantity'] as num?)?.toInt() ?? 0,
                price: (r['price'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting sale line items: $e');
      return [];
    }
  }

  /// All product lines sold across every invoice of a single day (flat list,
  /// newest first). Used by the Reports screen to show a day's sold items
  /// directly without drilling into each invoice.
  Future<List<SaleLineItem>> getLineItemsForDay(String day) async {
    final db = await _dbHelper.database;
    try {
      final rows = await db.rawQuery('''
        SELECT items.name as name,
               sale_items.quantity as quantity,
               COALESCE(sale_items.price, sale_items.price_at_time, 0.0) as price
        FROM sale_items
        JOIN sales ON sales.id = sale_items.sale_id
        LEFT JOIN items ON items.id = sale_items.item_id
        WHERE substr(sales.date, 1, 10) = ?
        ORDER BY sales.date DESC
      ''', [day]);

      return rows
          .map((r) => SaleLineItem(
                name: (r['name'] as String?) ?? 'کاڵای سڕاوە',
                quantity: (r['quantity'] as num?)?.toInt() ?? 0,
                price: (r['price'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error getting line items for day: $e');
      return [];
    }
  }

  Future<List<double>> getWeeklyRevenue() async {
    final db = await _dbHelper.database;
    List<double> weeklyData = List.filled(7, 0.0);

    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final targetDate = today.subtract(Duration(days: 6 - i));
      final startOfDay =
          DateTime(targetDate.year, targetDate.month, targetDate.day)
              .toIso8601String();
      final endOfDay = DateTime(
              targetDate.year, targetDate.month, targetDate.day, 23, 59, 59)
          .toIso8601String();

      final result = await db.rawQuery(
        'SELECT SUM(total_amount) as total FROM sales WHERE date >= ? AND date <= ?',
        [startOfDay, endOfDay],
      );

      if (result.isNotEmpty && result.first['total'] != null) {
        weeklyData[i] = result.first['total'] as double;
      }
    }
    return weeklyData;
  }

  // Backup and Restore

  /// Auto backups available to restore from (newest first).
  Future<List<BackupInfo>> getAutoBackups() =>
      BackupService.instance.listAutoBackups();

  /// Manual export: copies a WAL-safe snapshot to a user-chosen folder.
  Future<bool> backupDatabase() async {
    try {
      String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null) {
        return false; // User canceled
      }
      await BackupService.instance.backupToDirectory(selectedDirectory);
      return true;
    } catch (e) {
      print("Backup error: $e");
      return false;
    }
  }

  /// Lets the user pick a backup file and restores from it.
  Future<bool> restoreDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any, // extensions vary across platforms
      );
      if (result == null || result.files.single.path == null) {
        return false; // User canceled
      }
      return await restoreFromFile(result.files.single.path!);
    } catch (e) {
      print("Restore error: $e");
      return false;
    }
  }

  /// Restores the database from [backupPath]. Validates the file is a real
  /// SQLite database and clears stale journal files so the result is intact.
  Future<bool> restoreFromFile(String backupPath) async {
    try {
      File backupFile = File(backupPath);
      if (!await backupFile.exists()) return false;
      if (!await _isSqliteFile(backupFile)) return false;

      String dbPath = await _dbHelper.getDatabasePath();

      // Release any locks before swapping the file.
      await _dbHelper.closeDatabase();

      // Remove current db together with its journal/WAL side-files.
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        final f = File('$dbPath$suffix');
        if (await f.exists()) {
          await f.delete();
        }
      }

      await backupFile.copy(dbPath);

      // Reopen and refresh state.
      await loadItems();
      await loadCurrentShift();
      return true;
    } catch (e) {
      print("Restore error: $e");
      return false;
    }
  }

  /// Confirms a file really is a SQLite database by checking its header.
  Future<bool> _isSqliteFile(File f) async {
    RandomAccessFile? raf;
    try {
      raf = await f.open();
      final header = await raf.read(16);
      return String.fromCharCodes(header).startsWith('SQLite format 3');
    } catch (_) {
      return false;
    } finally {
      await raf?.close();
    }
  }
}
