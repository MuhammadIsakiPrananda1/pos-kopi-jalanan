import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final DateTime createdAt;

  Product({
    String? id,
    required this.name,
    required this.price,
    this.stock = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Product copyWith({
    String? name,
    double? price,
    int? stock,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'Product(id: $id, name: $name, price: $price, stock: $stock)';
}
