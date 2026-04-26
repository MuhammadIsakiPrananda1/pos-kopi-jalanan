import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../models/transaction.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/audio_service.dart';
import '../../services/print_service.dart';
import '../../widgets/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  final _cashController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isProcessing = false;
  double _cashReceived = 0;
  late AnimationController _successController;
  late Animation<double> _successScale;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _cashController.addListener(() {
      final raw = _cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
      setState(() => _cashReceived = double.tryParse(raw) ?? 0);
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    _focusNode.dispose();
    _successController.dispose();
    super.dispose();
  }

  double get _total => context.read<CartProvider>().total;
  double get _change => (_cashReceived - _total).clamp(0, double.infinity);
  bool get _canPay => _cashReceived >= _total;

  void _setExactAmount() {
    final total = _total;
    final formatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
    _cashController.text = formatter.format(total).trim();
    setState(() => _cashReceived = total);
  }

  void _addQuickAmount(double amount) {
    final current = _cashReceived;
    final total = current + amount;
    final formatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
    _cashController.text = formatter.format(total).trim();
    setState(() => _cashReceived = total);
  }

  Future<void> _processPayment() async {
    if (!_canPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Uang tidak cukup!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = context.read<CartProvider>();
      final txnProv = context.read<TransactionProvider>();

      final transaction = Transaction(
        total: cart.total,
        cashReceived: _cashReceived,
        change: _change,
        items: [],
      );

      final finalTransaction = Transaction(
        id: transaction.id,
        total: transaction.total,
        cashReceived: transaction.cashReceived,
        change: transaction.change,
        items: cart.toTransactionItems(transaction.id),
      );

      await txnProv.saveTransaction(finalTransaction);
      
      // Update stok di UI
      if (mounted) {
        context.read<ProductProvider>().loadProducts();
      }
      await AudioService.instance.playSuccess();

      // Try print
      if (PrintService.instance.isConnected) {
        await PrintService.instance.printReceipt(finalTransaction);
      }

      cart.clear();

      if (mounted) {
        setState(() {
          _showSuccess = true;
          _isProcessing = false;
        });
        _successController.forward();

        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) {
          Navigator.of(context)
              .popUntil((route) => route.isFirst || route.settings.name == '/home');
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('PEMBAYARAN', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                _buildOrderSummary(cart, nf),
                const SizedBox(height: 16),

                // Cash Input Section
                _buildCashInput(nf),
                const SizedBox(height: 12),

                // Change Display
                if (_cashReceived > 0) _buildChangeDisplay(nf),
                const SizedBox(height: 100), // Spasi bawah agar tidak mentok
              ],
            ),
          ),

          // Success overlay
          if (_showSuccess) _buildSuccessOverlay(nf),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Printer Status
            Text(
              PrintService.instance.isConnected
                  ? 'Printer terhubung'
                  : 'Printer tidak terhubung',
              style: AppTextStyles.bodySmall.copyWith(
                color: PrintService.instance.isConnected
                    ? AppColors.success
                    : AppColors.textHint,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            // Centered Small Button
            Center(
              child: SizedBox(
                width: 160,
                child: CustomButton(
                  label: 'BAYAR',
                  icon: Icons.payments_rounded,
                  onPressed: _canPay ? _processPayment : null,
                  isLoading: _isProcessing,
                  backgroundColor:
                      _canPay ? AppColors.accent : AppColors.surfaceLight,
                  textColor:
                      _canPay ? AppColors.background : AppColors.textSecondary,
                  height: 46,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart, NumberFormat nf) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETAIL PESANAN',
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(item.product.name,
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500))),
                    Text('x${item.quantity}',
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Text(nf.format(item.subtotal),
                        style: AppTextStyles.bodyMedium),
                  ],
                ),
              )),
          const Divider(color: AppColors.divider, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: AppTextStyles.titleMedium),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    nf.format(cart.total),
                    style: AppTextStyles.price.copyWith(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashInput(NumberFormat nf) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uang Diterima', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _cashController,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CurrencyInputFormatter(),
          ],
          style: AppTextStyles.price.copyWith(fontSize: 18),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Text(
                'Rp',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            hintText: '0',
            hintStyle: AppTextStyles.price.copyWith(color: AppColors.textHint, fontSize: 18),
          ),
        ),
      ],
    );
  }


  Widget _buildChangeDisplay(NumberFormat nf) {
    return AnimatedContainer(
      duration: AppConstants.animNormal,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: _canPay
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: _canPay
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _canPay ? 'Kembalian' : 'Kurang',
            style: AppTextStyles.titleMedium.copyWith(
              color: _canPay ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                nf.format(_canPay ? _change : _total - _cashReceived),
                style: AppTextStyles.priceLarge.copyWith(
                  color: _canPay ? AppColors.success : AppColors.error,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay(NumberFormat nf) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.9),
      child: Center(
        child: ScaleTransition(
          scale: _successScale,
          child: Container(
            margin: const EdgeInsets.all(AppConstants.paddingXL),
            padding: const EdgeInsets.all(AppConstants.paddingXL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 64),
                const SizedBox(height: 20),
                Text('PEMBAYARAN BERHASIL',
                    style: AppTextStyles.titleLarge.copyWith(letterSpacing: 1)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('KEMBALIAN', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            nf.format(_change),
                            style: AppTextStyles.priceLarge.copyWith(
                                color: AppColors.success, fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Terima kasih atas kunjungan Anda',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final double value = double.parse(newValue.text);
    final formatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
    final String newText = formatter.format(value).trim();

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
