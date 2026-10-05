import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterProvider extends ChangeNotifier {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _devices = [];
  bool _isLoading = false;
  bool _isConnected = false;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothDevice> get devices => _devices;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;

  PrinterProvider() {
    _init();
  }

  Future<void> _init() async {
    _isConnected = await bluetooth.isConnected ?? false;
    if (_isConnected) {
      // Try to recover connected device info if possible
      // Note: blue_thermal_printer doesn't easily store the device object, 
      // but we can check connection status.
    }
    notifyListeners();
  }

  Future<void> getDevices() async {
    _isLoading = true;
    notifyListeners();
    try {
      _devices = await bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint('Error getting devices: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    _isLoading = true;
    notifyListeners();
    try {
      await bluetooth.connect(device);
      _connectedDevice = device;
      _isConnected = true;
      
      // Save last connected device address
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_printer_address', device.address ?? '');
    } catch (e) {
      debugPrint('Error connecting: $e');
      _isConnected = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
    _connectedDevice = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<void> printReceipt(List<int> bytes) async {
    if (_isConnected) {
      await bluetooth.writeBytes(Uint8List.fromList(bytes));
    }
  }
}
