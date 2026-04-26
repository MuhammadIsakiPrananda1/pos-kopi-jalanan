import '../database/database_helper.dart';
import '../models/transaction.dart';

class TransactionService {
  final _db = DatabaseHelper.instance;

  Future<void> saveTransaction(Transaction transaction) =>
      _db.insertTransaction(transaction);

  Future<List<Transaction>> getTransactions({DateTime? from, DateTime? to}) async {
    return await _db.getTransactions(from: from, to: to);
  }

  Future<Map<String, dynamic>> getDailySummary(DateTime date) =>
      _db.getDailySummary(date);

  Future<List<Map<String, dynamic>>> getTopProducts(int days) =>
      _db.getTopProducts(days);

  Future<List<Map<String, dynamic>>> getDailyRevenue(int days) =>
      _db.getDailyRevenue(days);
}
