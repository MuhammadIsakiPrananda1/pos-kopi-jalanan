import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/printer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../../services/receipt_service.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
const _bgDark       = Color(0xFF09090B);
const _surfaceDark  = Color(0xFF141417);
const _cardDark     = Color(0xFF18181B);
const _borderDark   = Color(0xFF27272A);
const _textMuted    = Color(0xFF71717A);
const _textSub      = Color(0xFFA1A1AA);
const _textMain     = Color(0xFFFAFAFA);
const _greenSuccess = Color(0xFF22C55E);
const _redError     = Color(0xFFEF4444);
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _font(double size, FontWeight weight, Color color, {double letterSpacing = 0}) =>
    GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _showSuccess = false;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  Transaction? _savedTransaction;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final cart = context.read<CartProvider>();
      final txnProvider = context.read<TransactionProvider>();
      final total = cart.total;

      final String txnId = const Uuid().v4();
      final transaction = Transaction(
        id: txnId,
        total: total,
        cashReceived: total,
        change: 0,
        items: cart.toTransactionItems(txnId),
      );

      _savedTransaction = transaction;
      await txnProvider.saveTransaction(transaction);

      if (mounted) {
        context.read<ProductProvider>().loadProducts();
        context.read<FinanceProvider>().loadRecords();
        context.read<TransactionProvider>().loadDailySummary();
        context.read<TransactionProvider>().loadReportData(30);
      }

      await AudioService.instance.playSuccess();

      if (mounted) {
        cart.clear();
        setState(() {
          _isProcessing = false;
          _showSuccess = true;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $e', style: _font(12, FontWeight.w500, _textMain)),
            backgroundColor: _cardDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: _redError),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handlePrintReceipt() async {
    if (_savedTransaction == null) return;

    final printer = context.read<PrinterProvider>();
    final settings = context.read<SettingsProvider>();

    if (!printer.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printer belum terhubung. Silakan atur di menu Printer.',
              style: _font(12, FontWeight.w500, _textMain)),
          backgroundColor: _cardDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      final bytes = await ReceiptService.generateReceiptBytes(
        orderId: _savedTransaction!.id.substring(0, 8).toUpperCase(),
        items: _savedTransaction!.items,
        subtotal: _savedTransaction!.total,
        discount: 0,
        total: _savedTransaction!.total,
        cash: _savedTransaction!.cashReceived,
        change: _savedTransaction!.change,
        storeName: settings.storeName == 'Belum diatur' ? '' : settings.storeName,
        storeAddress: settings.storeAddress == 'Belum diatur' ? '' : settings.storeAddress,
        storePhone: settings.storePhone == 'Belum diatur' ? '' : settings.storePhone,
        storeSlogan: settings.storeSlogan == 'Belum diatur' ? '' : settings.storeSlogan,
        receiptHeader: settings.receiptHeader == 'Belum diatur' ? '' : settings.receiptHeader,
        receiptFooter: settings.receiptFooter == 'Belum diatur' ? '' : settings.receiptFooter,
        paperSizeStr: settings.paperSize,
      );
      await printer.printReceipt(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak struk: $e', style: _font(12, FontWeight.w500, _textMain)),
            backgroundColor: _cardDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(cart),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildReceiptCard(cart, nf),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom Action Bar
            if (!_showSuccess)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  decoration: const BoxDecoration(
                    color: _surfaceDark,
                    border: Border(top: BorderSide(color: _borderDark, width: 1)),
                  ),
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isProcessing || cart.isEmpty ? null : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _textMain,
                        foregroundColor: _bgDark,
                        disabledBackgroundColor: _cardDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _bgDark,
                              ),
                            )
                          : Text(
                              'Selesaikan Pembayaran',
                              style: _font(13, FontWeight.w700, _bgDark),
                            ),
                    ),
                  ),
                ),
              ),

            // Success Overlay
            if (_showSuccess) _buildSuccessOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Header (konsisten dengan Dashboard, Stok, & Kasir POS) ─────────────────
  Widget _buildHeader(CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textSub,
              size: 18,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _greenSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Konfirmasi Bayar',
                      style: _font(
                        15,
                        FontWeight.w700,
                        _textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '${cart.itemCount} item • periksa pesanan sebelum dibayar',
                    style: _font(10, FontWeight.w500, _textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(CartProvider cart, NumberFormat nf) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id').format(now);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ringkasan Transaksi', style: _font(13.5, FontWeight.w700, _textMain)),
              Text(dateStr, style: _font(10, FontWeight.w400, _textMuted)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _borderDark),
          const SizedBox(height: 14),

          // Items
          ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: _font(12, FontWeight.w500, _textMain),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${item.quantity} x ${nf.format(item.product.price)}',
                            style: _font(10, FontWeight.w400, _textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      nf.format(item.subtotal),
                      style: _font(12, FontWeight.w600, _textMain),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 8),
          const Divider(height: 1, color: _borderDark),
          const SizedBox(height: 14),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Tagihan', style: _font(12, FontWeight.w500, _textSub)),
              Text(
                nf.format(cart.total),
                style: _font(17, FontWeight.w800, _textMain, letterSpacing: -0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            decoration: BoxDecoration(
              color: _surfaceDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderDark, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clean check icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _greenSuccess.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _greenSuccess.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: _greenSuccess,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Transaksi Berhasil',
                  style: _font(15, FontWeight.w700, _textMain),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pesanan telah dicatat dalam laporan kasir.',
                  textAlign: TextAlign.center,
                  style: _font(11.5, FontWeight.w400, _textSub),
                ),
                const SizedBox(height: 22),
                const Divider(height: 1, color: _borderDark),
                const SizedBox(height: 18),

                // Print receipt button
                Consumer<PrinterProvider>(
                  builder: (context, printer, _) => SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _handlePrintReceipt,
                      icon: Icon(
                        printer.isConnected ? Icons.print_rounded : Icons.print_disabled_outlined,
                        size: 15,
                      ),
                      label: Text(
                        printer.isConnected ? 'Cetak Struk' : 'Printer Tidak Terhubung',
                        style: _font(12, FontWeight.w600, printer.isConnected ? _bgDark : _textMuted),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: printer.isConnected ? _textMain : _cardDark,
                        foregroundColor: printer.isConnected ? _bgDark : _textMuted,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: printer.isConnected ? _textMain : _borderDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Back / New order button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil(
                        (route) => route.isFirst || route.settings.name == '/home',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textMain,
                      side: const BorderSide(color: _borderDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Kembali ke Kasir',
                      style: _font(12, FontWeight.w600, _textMain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
