import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
const _bgDark = Color(0xFF09090B);
const _surfaceDark = Color(0xFF141417);
const _cardDark = Color(0xFF18181B);
const _borderDark = Color(0xFF27272A);
const _borderSubtle = Color(0xFF1F1F23);
const _textMuted = Color(0xFF71717A);
const _textSub = Color(0xFFA1A1AA);
const _textMain = Color(0xFFFAFAFA);
const _stockGreen = Color(0xFF22C55E);
const _stockRed = Color(0xFFEF4444);
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _font(double size, FontWeight weight, Color color,
        {double letterSpacing = 0}) =>
    GoogleFonts.quicksand(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing);

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.product!.name;
      final formatter =
          NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
      _priceController.text = formatter.format(widget.product!.price).trim();
      _stockController.text = widget.product!.stock.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    final provider = context.read<ProductProvider>();
    final priceStr = _priceController.text.replaceAll('.', '');
    final price = double.tryParse(priceStr) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;

    bool success;
    if (_isEditing) {
      final updated = widget.product!.copyWith(
        name: _nameController.text.trim(),
        price: price,
        stock: stock,
      );
      success = await provider.updateProduct(updated);
    } else {
      final newProduct = Product(
        name: _nameController.text.trim(),
        price: price,
        stock: stock,
      );
      success = await provider.addProduct(newProduct);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Produk diperbarui!' : 'Produk ditambahkan!',
              style: _font(12, FontWeight.w600, _bgDark),
            ),
            backgroundColor: _textMain,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan produk',
              style: _font(12, FontWeight.w600, _textMain),
            ),
            backgroundColor: _stockRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewCard(),
                        const SizedBox(height: 20),
                        _buildFieldLabel('Nama Produk'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Masukkan Nama Produk',
                          icon: Icons.local_cafe_outlined,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('Harga Jual'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _priceController,
                          hintText: 'Masukkan Nominal Harja Jual',
                          icon: Icons.payments_outlined,
                          prefixText: 'Rp',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _CurrencyInputFormatter(),
                          ],
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Harga tidak boleh kosong';
                            }
                            final priceStr = v.replaceAll('.', '');
                            final price = double.tryParse(priceStr);
                            if (price == null || price <= 0) {
                              return 'Harga harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('Stok Barang'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _stockController,
                          hintText: 'Masukkan Jumlah Stok Barang',
                          icon: Icons.inventory_2_outlined,
                          suffixText: 'pcs',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Stok tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
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
                        color: _stockGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? 'Edit Produk' : 'Tambah Produk',
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
                    _isEditing
                        ? 'Perbarui detail produk & stok'
                        : 'Isi detail produk baru',
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

  // ── Preview Card (live) ────────────────────────────────────────────────────
  Widget _buildPreviewCard() {
    final priceStr = _priceController.text.replaceAll('.', '');
    final price = double.tryParse(priceStr) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final name = _nameController.text.trim();
    final nf =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    final bool isSoldOut = stock <= 0;
    final bool isLowStock = stock > 0 && stock <= 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderDark, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderSubtle),
            ),
            child: const Icon(
              Icons.local_cafe_outlined,
              size: 20,
              color: _textSub,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Nama Produk' : name,
                  style: _font(
                    13,
                    FontWeight.w600,
                    name.isEmpty ? _textMuted : _textMain,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  price > 0 ? nf.format(price) : 'Rp -',
                  style: _font(
                    12,
                    FontWeight.w600,
                    price > 0 ? _textSub : _textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isSoldOut
                  ? _stockRed.withValues(alpha: 0.14)
                  : isLowStock
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.14)
                      : _borderSubtle,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isSoldOut
                  ? 'Habis'
                  : isLowStock
                      ? 'Sisa $stock'
                      : 'Stok $stock',
              style: _font(
                9.5,
                FontWeight.w600,
                isSoldOut
                    ? _stockRed
                    : isLowStock
                        ? const Color(0xFFF59E0B)
                        : _textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: _font(11.5, FontWeight.w600, _textSub),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _textMain,
          foregroundColor: _bgDark,
          disabledBackgroundColor: _cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _bgDark,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditing ? Icons.save_outlined : Icons.add_rounded,
                    size: 16,
                    color: _bgDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? 'Simpan Perubahan' : 'Tambah ke Daftar',
                    style: _font(13, FontWeight.w700, _bgDark),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? prefixText,
    String? suffixText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 44,
      child: TextFormField(
        controller: controller,
        style: _font(13, FontWeight.w500, _textMain),
        cursorColor: _textMain,
        cursorWidth: 1.5,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: _font(12, FontWeight.w400, _textMuted),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _textMuted, size: 16),
                if (prefixText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    prefixText,
                    style: _font(13, FontWeight.w600, _textSub),
                  ),
                ],
              ],
            ),
          ),
          suffixIcon: suffixText != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 1,
                    child: Text(
                      suffixText,
                      style: _font(11.5, FontWeight.w500, _textMuted),
                    ),
                  ),
                )
              : null,
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIconConstraints: const BoxConstraints(minWidth: 0),
          filled: true,
          fillColor: _surfaceDark,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _textMain, width: 1.2),
          ),
        ),
        validator: validator,
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
    final formatter =
        NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
    final String newText = formatter.format(value).trim();

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
