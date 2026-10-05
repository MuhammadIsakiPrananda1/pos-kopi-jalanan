import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<List<int>> generateReceiptBytes({
    required String orderId,
    required List<dynamic> items,
    required double subtotal,
    required double discount,
    required double total,
    required double cash,
    required double change,
    // Settings parameters
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String storeSlogan,
    required String receiptHeader,
    required String receiptFooter,
    required String paperSizeStr,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperSizeStr == '80mm' ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    final nf = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
    final df = DateFormat('dd/MM/yyyy HH:mm', 'id');

    // HEADER - STORE INFO
    bytes += generator.text(storeName.isEmpty ? 'KOPI JALANAN GANK' : storeName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    
    if (storeSlogan.isNotEmpty) {
      bytes += generator.text(storeSlogan, styles: const PosStyles(align: PosAlign.center));
    }
    
    if (storeAddress.isNotEmpty) {
      bytes += generator.text(storeAddress, styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    }
    
    if (storePhone.isNotEmpty) {
      bytes += generator.text('Telp: $storePhone', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    }

    bytes += generator.feed(1);
    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
    
    if (receiptHeader.isNotEmpty) {
      bytes += generator.text(receiptHeader, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
    }

    // ORDER INFO
    bytes += generator.row([
      PosColumn(text: 'No: $orderId', width: 6, styles: const PosStyles(fontType: PosFontType.fontB)),
      PosColumn(text: df.format(DateTime.now()), width: 6, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB)),
    ]);
    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

    // ITEMS
    for (var item in items) {
      bytes += generator.text(item.product.name.toUpperCase(), styles: const PosStyles(bold: true));
      bytes += generator.row([
        PosColumn(text: '  ${item.quantity} x ${nf.format(item.product.price).trim()}', width: 7, styles: const PosStyles(fontType: PosFontType.fontB)),
        PosColumn(text: nf.format(item.quantity * item.product.price).trim(), width: 5, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB)),
      ]);
    }
    
    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

    // SUMMARY
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 7),
      PosColumn(text: nf.format(subtotal).trim(), width: 5, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Diskon', width: 7),
        PosColumn(text: '-${nf.format(discount).trim()}', width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.feed(1);
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size1, width: PosTextSize.size1)),
      PosColumn(text: 'Rp ${nf.format(total).trim()}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size1, width: PosTextSize.size1)),
    ]);
    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

    // PAYMENT
    bytes += generator.row([
      PosColumn(text: 'Bayar (Tunai)', width: 7, styles: const PosStyles(fontType: PosFontType.fontB)),
      PosColumn(text: nf.format(cash).trim(), width: 5, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Kembali', width: 7, styles: const PosStyles(fontType: PosFontType.fontB)),
      PosColumn(text: nf.format(change).trim(), width: 5, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB)),
    ]);

    // FOOTER
    bytes += generator.feed(1);
    bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(receiptFooter.isEmpty ? 'Terima Kasih Atas Kunjungan Anda' : receiptFooter, 
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    bytes += generator.text('*** LAYANAN KASIR DIGITAL ***', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    
    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }
}
