import 'package:uuid/uuid.dart';

enum FinanceType { income, expense }

class FinanceRecord {
  final String id;
  final FinanceType type;
  final double amount;
  final String description;
  final DateTime createdAt;

  FinanceRecord({
    String? id,
    required this.type,
    required this.amount,
    required this.description,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isIncome => type == FinanceType.income;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FinanceRecord.fromMap(Map<String, dynamic> map) {
    return FinanceRecord(
      id: map['id'] as String,
      type: FinanceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FinanceType.income,
      ),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
