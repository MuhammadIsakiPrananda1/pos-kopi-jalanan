import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';

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
      final formatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
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
            content:
                Text(_isEditing ? 'Produk diperbarui!' : 'Produk ditambahkan!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal menyimpan produk'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        title: Text(
          _isEditing ? 'EDIT PRODUK' : 'TAMBAH PRODUK',
          style: AppTextStyles.appBarTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Nama Produk'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'Nama Produk',
                icon: Icons.coffee_rounded,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nama tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 24),
              _buildFieldLabel('Harga Jual'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hintText: 'Harga',
                icon: Icons.payments_rounded,
                prefixText: 'Rp ',
                alwaysShowPrefix: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CurrencyInputFormatter(),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Harga tidak boleh kosong';
                  final priceStr = v.replaceAll('.', '');
                  final price = double.tryParse(priceStr);
                  if (price == null || price <= 0)
                    return 'Harga harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildFieldLabel('Stok Barang'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _stockController,
                hintText: 'Jumlah Stok',
                icon: Icons.inventory_2_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Stok tidak boleh kosong';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              CustomButton(
                label: _isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH KE DAFTAR',
                icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                onPressed: _save,
                isLoading: _isLoading,
                height: 56,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? prefixText,
    bool alwaysShowPrefix = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: AppTextStyles.bodyLarge,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              if (prefixText != null) ...[
                const SizedBox(width: 8),
                Text(
                  prefixText.trim(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      validator: validator,
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
