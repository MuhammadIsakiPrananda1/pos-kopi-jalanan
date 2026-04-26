import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final _service = TransactionService();

  List<Transaction> _transactions = [];
  Map<String, dynamic> _dailySummary = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _dailyRevenue = [];

  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  Map<String, dynamic> get dailySummary => _dailySummary;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get dailyRevenue => _dailyRevenue;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get todayTransactionCount =>
      (_dailySummary['transaction_count'] as int?) ?? 0;
  double get todayRevenue =>
      (_dailySummary['total_revenue'] as num?)?.toDouble() ?? 0;

  Future<void> saveTransaction(Transaction transaction) async {
    try {
      await _service.saveTransaction(transaction);
      await loadDailySummary();
      await loadReportData(7); // Refresh charts and top products
    } catch (e) {
      _error = 'Gagal menyimpan transaksi: $e';
      notifyListeners();
    }
  }

  Future<void> loadTransactions({DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _service.getTransactions(from: from, to: to);
    } catch (e) {
      _error = 'Gagal memuat transaksi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDailySummary() async {
    try {
      _dailySummary = await _service.getDailySummary(DateTime.now());
      notifyListeners();
    } catch (e) {
      _error = 'Gagal memuat summary: $e';
    }
  }

  Future<void> loadReportData(int days) async {
    _isLoading = true;
    notifyListeners();
    try {
      _topProducts = await _service.getTopProducts(days);
      _dailyRevenue = await _service.getDailyRevenue(days);
    } catch (e) {
      _error = 'Gagal memuat laporan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
