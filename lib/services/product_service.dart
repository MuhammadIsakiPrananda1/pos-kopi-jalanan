import '../database/database_helper.dart';
import '../models/product.dart';

class ProductService {
  final _db = DatabaseHelper.instance;

  Future<List<Product>> getProducts() => _db.getProducts();

  Future<void> addProduct(Product product) => _db.insertProduct(product);

  Future<void> updateProduct(Product product) => _db.updateProduct(product);

  Future<void> deleteProduct(String id) => _db.deleteProduct(id);
}
