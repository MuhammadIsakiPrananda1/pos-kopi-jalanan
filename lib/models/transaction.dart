import 'package:uuid/uuid.dart';
import 'transaction_item.dart';

enum PaymentMethod { cash }

class Transaction {
  final String id;
  final double total;
  final double cashReceived;
  final double change;
  final PaymentMethod paymentMethod;
  final List<TransactionItem> items;
  final DateTime createdAt;

  Transaction({
    String? id,
    required this.total,
    required this.cashReceived,
    required this.change,
    this.paymentMethod = PaymentMethod.cash,
    this.items = const [],
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total': total,
      'cash_received': cashReceived,
      'change': change,
      'payment_method': paymentMethod.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(
    Map<String, dynamic> map,
    List<TransactionItem> items,
  ) {
    return Transaction(
      id: map['id'] as String,
      total: (map['total'] as num).toDouble(),
      cashReceived: (map['cash_received'] as num?)?.toDouble() ?? 0,
      change: (map['change'] as num?)?.toDouble() ?? 0,
      paymentMethod: PaymentMethod.cash,
      items: items,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
