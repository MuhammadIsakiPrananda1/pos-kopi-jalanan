import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final _service = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getProducts();
    } catch (e) {
      _error = 'Gagal memuat produk: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      await _service.addProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _error = 'Gagal menambah produk: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _service.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _error = 'Gagal mengubah produk: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _service.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      _error = 'Gagal menghapus produk: $e';
      notifyListeners();
      return false;
    }
  }


  void clearError() {
    _error = null;
    notifyListeners();
  }
}
