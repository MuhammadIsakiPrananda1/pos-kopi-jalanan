import 'package:flutter/foundation.dart';
import '../models/finance_record.dart';
import '../services/finance_service.dart';

class FinanceProvider extends ChangeNotifier {
  final _service = FinanceService();

  List<FinanceRecord> _records = [];
  Map<String, double> _summary = {'income': 0, 'expense': 0};
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  List<FinanceRecord> get records => _records;
  Map<String, double> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  double get totalIncome => _summary['income'] ?? 0;
  double get totalExpense => _summary['expense'] ?? 0;
  double get balance => totalIncome - totalExpense;

  Future<void> loadRecords({DateTime? date}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _records = await _service.getRecords(date: date ?? _selectedDate);
      _summary = await _service.getSummary();
    } catch (e) {
      _error = 'Gagal memuat catatan keuangan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRecord(FinanceRecord record) async {
    try {
      await _service.addRecord(record);
      await loadRecords();
      return true;
    } catch (e) {
      _error = 'Gagal menyimpan catatan: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      await _service.deleteRecord(id);
      await loadRecords();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus catatan: $e';
      notifyListeners();
      return false;
    }
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    loadRecords(date: date);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
