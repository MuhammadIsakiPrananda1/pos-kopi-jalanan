import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Store Settings
  String _storeName = '';
  String _storeAddress = '';
  String _storePhone = '';
  String _storeSlogan = '';

  // Receipt Settings
  String _receiptHeader = '';
  String _receiptFooter = '';
  String _paperSize = '58mm';

  // Getters
  String get storeName => _storeName;
  String get storeAddress => _storeAddress;
  String get storePhone => _storePhone;
  String get storeSlogan => _storeSlogan;
  String get receiptHeader => _receiptHeader;
  String get receiptFooter => _receiptFooter;
  String get paperSize => _paperSize;
  bool get isInitialized => _isInitialized;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    
    _storeName = _normalize(_prefs.getString('store_name'));
    _storeAddress = _normalize(_prefs.getString('store_address'));
    _storePhone = _normalize(_prefs.getString('store_phone'));
    _storeSlogan = _normalize(_prefs.getString('store_slogan'));
    
    _receiptHeader = _normalize(_prefs.getString('receipt_header'));
    _receiptFooter = _normalize(_prefs.getString('receipt_footer'));
    _paperSize = _prefs.getString('paper_size') ?? '58mm';

    _isInitialized = true;
    notifyListeners();
  }

  String _normalize(String? value) {
    if (value == null || value == 'Belum diatur') return '';
    return value;
  }

  Future<void> updateStoreName(String value) async {
    _storeName = value;
    await _prefs.setString('store_name', value);
    notifyListeners();
  }

  Future<void> updateStoreAddress(String value) async {
    _storeAddress = value;
    await _prefs.setString('store_address', value);
    notifyListeners();
  }

  Future<void> updateStorePhone(String value) async {
    _storePhone = value;
    await _prefs.setString('store_phone', value);
    notifyListeners();
  }

  Future<void> updateStoreSlogan(String value) async {
    _storeSlogan = value;
    await _prefs.setString('store_slogan', value);
    notifyListeners();
  }

  Future<void> updateReceiptHeader(String value) async {
    _receiptHeader = value;
    await _prefs.setString('receipt_header', value);
    notifyListeners();
  }

  Future<void> updateReceiptFooter(String value) async {
    _receiptFooter = value;
    await _prefs.setString('receipt_footer', value);
    notifyListeners();
  }

  Future<void> updatePaperSize(String value) async {
    _paperSize = value;
    await _prefs.setString('paper_size', value);
    notifyListeners();
  }
}
