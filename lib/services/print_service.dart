import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrintService {
  PrintService._();
  static final PrintService instance = PrintService._();

  BluetoothInfo? _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  String? get connectedDeviceName => _connectedDevice?.name;

  Future<bool> get isBluetoothEnabled async => 
      await PrintBluetoothThermal.bluetoothEnabled;

  // ============ SCAN & CONNECT ============

  Future<List<BluetoothInfo>> getDevices() async {
    try {
      final bool isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!isEnabled) return [];
      return await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(BluetoothInfo device) async {
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.macAdress,
      );
      if (result) {
        _connectedDevice = device;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_printer_mac', device.macAdress);
        await prefs.setString('last_printer_name', device.name);
      }
      return result;
    } catch (e) {
      _connectedDevice = null;
      return false;
    }
  }

  Future<void> tryAutoConnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mac = prefs.getString('last_printer_mac');
      final name = prefs.getString('last_printer_name');
      
      if (mac != null && name != null) {
        final result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
        if (result) {
          _connectedDevice = BluetoothInfo(name: name, macAdress: mac);
        }
      }
    } catch (_) {}
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _connectedDevice = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_printer_mac');
      await prefs.remove('last_printer_name');
    } catch (_) {}
  }

  // ============ PRINT RECEIPT ============

  Future<bool> printReceipt(Transaction transaction) async {
    try {
      final bool connected = await PrintBluetoothThermal.connectionStatus;
      if (!connected) return false;

      final df = DateFormat('dd/MM/yyyy HH:mm');
      final nf = NumberFormat.currency(
          locale: 'id', symbol: 'Rp ', decimalDigits: 0);

      List<int> bytes = [];

      // Helper untuk ESC/POS manual
      bytes += _textLine('================================');
      bytes += _textLine('    KOPI JALANAN GANK', bold: true, center: true);
      bytes += _textLine('================================');
      bytes += _textLine('Tanggal : ${df.format(transaction.createdAt)}');
      bytes += _textLine('--------------------------------');

      for (final item in transaction.items) {
        bytes += _textLine(item.productName);
        final qtyPrice =
            '  ${item.quantity}x ${nf.format(item.price)}';
        final subtotal = nf.format(item.subtotal);
        bytes += _textLeftRight(qtyPrice, subtotal);
      }

      bytes += _textLine('--------------------------------');
      bytes += _textLeftRight('TOTAL', nf.format(transaction.total), bold: true);
      bytes += _textLeftRight('Tunai', nf.format(transaction.cashReceived));
      bytes += _textLeftRight('Kembalian', nf.format(transaction.change));
      bytes += _textLine('================================');
      bytes += _textLine('  Terima kasih sudah membeli!', center: true);
      bytes += _textLine('================================');
      bytes += _newLines(3);

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      return false;
    }
  }

  // ============ ESC/POS BYTE HELPERS ============

  // ESC/POS commands
  static const List<int> _boldOn = [0x1B, 0x45, 0x01];   // ESC E 1
  static const List<int> _boldOff = [0x1B, 0x45, 0x00];  // ESC E 0
  static const List<int> _centerAlign = [0x1B, 0x61, 0x01]; // ESC a 1
  static const List<int> _leftAlign = [0x1B, 0x61, 0x00];   // ESC a 0
  static const List<int> _newLine = [0x0A];               // LF

  List<int> _textLine(String text,
      {bool bold = false, bool center = false}) {
    List<int> bytes = [];
    if (center) bytes += _centerAlign;
    if (bold) bytes += _boldOn;
    bytes += text.codeUnits;
    bytes += _newLine;
    if (bold) bytes += _boldOff;
    if (center) bytes += _leftAlign;
    return bytes;
  }

  List<int> _textLeftRight(String left, String right,
      {bool bold = false}) {
    const int lineWidth = 32;
    final int spaces = lineWidth - left.length - right.length;
    final String spacer = spaces > 0 ? ' ' * spaces : ' ';
    final String line = '$left$spacer$right';
    return _textLine(line, bold: bold);
  }

  List<int> _newLines(int count) {
    List<int> bytes = [];
    for (int i = 0; i < count; i++) {
      bytes += _newLine;
    }
    return bytes;
  }
}
