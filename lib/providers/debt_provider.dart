import 'package:flutter/material.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';
import '../database/database_helper.dart';

class DebtProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Debt> _debts = [];
  List<Debt> _filteredDebts = [];
  bool _isLoading = false;

  String _selectedType = 'all'; // 'all', 'customer', 'supplier'
  String _selectedStatus = 'all'; // 'all', 'unpaid', 'paid', 'overdue'
  String _searchQuery = '';

  List<Debt> get debts => _filteredDebts;
  List<Debt> get allDebts => _debts;
  bool get isLoading => _isLoading;
  String get selectedType => _selectedType;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  DebtProvider() {
    loadDebts();
  }

  // --- Statistics ---
  double get totalCustomerDebt {
    return _debts
        .where((d) => d.type == 'customer')
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  double get totalSupplierDebt {
    return _debts
        .where((d) => d.type == 'supplier')
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  double get totalPaidDebt {
    return _debts.fold(0.0, (sum, d) => sum + d.paidAmount);
  }

  double get totalRemainingDebt {
    return _debts.fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  int get activeDebtorsCount {
    return _debts.where((d) => !d.isFullyPaid).length;
  }

  int get overdueDebtsCount {
    return _debts.where((d) => d.isOverdue).length;
  }

  // --- Data Loading & Filtering ---
  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _debts = await _dbHelper.getAllDebts();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading debts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void filterByType(String type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  void filterByStatus(String status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredDebts = _debts.where((d) {
      // 1. Type filter
      if (_selectedType != 'all' && d.type != _selectedType) {
        return false;
      }

      // 2. Status filter
      if (_selectedStatus == 'unpaid' && d.isFullyPaid) {
        return false;
      }
      if (_selectedStatus == 'paid' && !d.isFullyPaid) {
        return false;
      }
      if (_selectedStatus == 'overdue' && !d.isOverdue) {
        return false;
      }

      // 3. Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = d.personName.toLowerCase().contains(q);
        final phoneMatch = (d.phone ?? '').toLowerCase().contains(q);
        final notesMatch = (d.notes ?? '').toLowerCase().contains(q);
        if (!nameMatch && !phoneMatch && !notesMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // --- CRUD Operations ---
  Future<bool> addDebt(Debt debt) async {
    try {
      await _dbHelper.insertDebt(debt);
      await loadDebts();
      return true;
    } catch (e) {
      debugPrint('Error adding debt: $e');
      return false;
    }
  }

  Future<bool> updateDebt(Debt debt) async {
    try {
      await _dbHelper.updateDebt(debt);
      await loadDebts();
      return true;
    } catch (e) {
      debugPrint('Error updating debt: $e');
      return false;
    }
  }

  Future<bool> deleteDebt(int id) async {
    try {
      await _dbHelper.deleteDebt(id);
      await loadDebts();
      return true;
    } catch (e) {
      debugPrint('Error deleting debt: $e');
      return false;
    }
  }

  Future<bool> addPayment(int debtId, double amount, {String? notes, DateTime? date}) async {
    if (amount <= 0) return false;
    try {
      final payment = DebtPayment(
        debtId: debtId,
        amount: amount,
        date: date ?? DateTime.now(),
        notes: notes,
      );
      await _dbHelper.insertDebtPayment(payment);
      await loadDebts();
      return true;
    } catch (e) {
      debugPrint('Error adding debt payment: $e');
      return false;
    }
  }

  Future<List<DebtPayment>> getPaymentsForDebt(int debtId) async {
    try {
      return await _dbHelper.getPaymentsForDebt(debtId);
    } catch (e) {
      debugPrint('Error getting debt payments: $e');
      return [];
    }
  }

  Future<bool> deletePayment(int paymentId, int debtId, double amount) async {
    try {
      await _dbHelper.deleteDebtPayment(paymentId, debtId, amount);
      await loadDebts();
      return true;
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      return false;
    }
  }
}
