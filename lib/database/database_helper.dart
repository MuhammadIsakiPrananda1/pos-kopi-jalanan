import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/finance_record.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kopi_jalanan_gank.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop all tables and recreate them fresh
    await db.execute('DROP TABLE IF EXISTS transaction_items');
    await db.execute('DROP TABLE IF EXISTS transactions');
    await db.execute('DROP TABLE IF EXISTS finance_records');
    await db.execute('DROP TABLE IF EXISTS products');
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        total REAL NOT NULL,
        cash_received REAL NOT NULL DEFAULT 0,
        change REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL DEFAULT '',
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE finance_records (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Removed dummy products initialization
  }

  // ============ PRODUCTS ============
  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ============ TRANSACTIONS ============
  Future<void> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('transactions', transaction.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in transaction.items) {
        await txn.insert('transaction_items', item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        // KURANGI STOK PRODUK
        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }

  Future<List<Transaction>> getTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (from != null && to != null) {
      where = 'created_at >= ? AND created_at <= ?';
      whereArgs = [from.toIso8601String(), to.toIso8601String()];
    } else if (from != null) {
      where = 'created_at >= ?';
      whereArgs = [from.toIso8601String()];
    }

    final maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final transactions = <Transaction>[];
    for (final map in maps) {
      final items = await getTransactionItems(map['id'] as String);
      transactions.add(Transaction.fromMap(map, items));
    }
    return transactions;
  }

  Future<List<TransactionItem>> getTransactionItems(String transactionId) async {
    final db = await database;
    final maps = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as transaction_count,
        COALESCE(SUM(total), 0) as total_revenue
      FROM transactions
      WHERE date(created_at) = ?
    ''', [dateStr]);

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getTopProducts(int days) async {
    final db = await database;
    final from = DateTime.now().subtract(Duration(days: days));

    return await db.rawQuery('''
      SELECT 
        ti.product_name,
        SUM(ti.quantity) as total_sold,
        SUM(ti.price * ti.quantity) as total_revenue
      FROM transaction_items ti
      INNER JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.created_at >= ?
      GROUP BY ti.product_name
      ORDER BY total_sold DESC
      LIMIT 5
    ''', [from.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> getDailyRevenue(int days) async {
    final db = await database;
    final from = DateTime.now().subtract(Duration(days: days));

    return await db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as transaction_count,
        COALESCE(SUM(total), 0) as total_revenue
      FROM transactions
      WHERE created_at >= ?
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''', [from.toIso8601String()]);
  }

  // ============ FINANCE ============
  Future<void> insertFinanceRecord(FinanceRecord record) async {
    final db = await database;
    await db.insert('finance_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FinanceRecord>> getFinanceRecords({DateTime? date}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      where = 'created_at >= ? AND created_at < ?';
      whereArgs = [startOfDay.toIso8601String(), endOfDay.toIso8601String()];
    }

    final maps = await db.query(
      'finance_records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => FinanceRecord.fromMap(m)).toList();
  }

  Future<void> deleteFinanceRecord(String id) async {
    final db = await database;
    await db.delete('finance_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getFinanceSummary() async {
    final db = await database;
    
    // Ambil total dari transaksi kasir
    final salesResult = await db.rawQuery('SELECT COALESCE(SUM(total), 0) as total_sales FROM transactions');
    final totalSales = (salesResult.first['total_sales'] as num).toDouble();

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as manual_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expense
      FROM finance_records
    ''');

    return {
      'income': (result.first['manual_income'] as num).toDouble() + totalSales,
      'expense': (result.first['total_expense'] as num).toDouble(),
    };
  }
}
