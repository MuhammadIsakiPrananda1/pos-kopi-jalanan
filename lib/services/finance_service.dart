import '../database/database_helper.dart';
import '../models/finance_record.dart';

class FinanceService {
  final _db = DatabaseHelper.instance;

  Future<void> addRecord(FinanceRecord record) =>
      _db.insertFinanceRecord(record);

  Future<List<FinanceRecord>> getRecords({DateTime? date}) =>
      _db.getFinanceRecords(date: date);

  Future<void> deleteRecord(String id) => _db.deleteFinanceRecord(id);

  Future<Map<String, double>> getSummary() => _db.getFinanceSummary();
}
