import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import 'product_form_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('MANAJEMEN STOK', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Cari kopi...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),

          Expanded(
            child: Consumer<ProductProvider>(
              builder: (_, prod, __) {
                if (prod.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                final products = _searchQuery.isEmpty
                    ? prod.products
                    : prod.products
                        .where(
                            (p) => p.name.toLowerCase().contains(_searchQuery))
                        .toList();

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text('Daftar kopi masih kosong',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => prod.loadProducts(),
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
                    itemCount: products.length,
                    itemBuilder: (_, i) =>
                        _buildProductTile(context, products[i], prod, nf),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => _openForm(context),
          backgroundColor: AppColors.accent,
          elevation: 0,
          highlightElevation: 0,
          hoverElevation: 0,
          focusElevation: 0,
          splashColor: Colors.transparent,
          icon: const Icon(Icons.add_rounded, color: AppColors.background),
          label: Text(
            'TAMBAH PRODUK',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.background,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildProductTile(
    BuildContext context,
    Product product,
    ProductProvider provider,
    NumberFormat nf,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Icon Kecil
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.coffee_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),

          // Info Produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  nf.format(product.price),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stok: ${product.stock}',
                  style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: product.stock < 10
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight: product.stock < 10
                          ? FontWeight.bold
                          : FontWeight.normal),
                ),
              ],
            ),
          ),

          // Aksi Cepat
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary, size: 18),
                onPressed: () => _openForm(context, product: product),
              ),
              const SizedBox(width: 12),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 18),
                onPressed: () => _confirmDelete(context, product, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {Product? product}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  void _confirmDelete(BuildContext context, Product product, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Data?', style: AppTextStyles.titleMedium),
        content: Text('Yakin ingin menghapus "${product.name}"?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteProduct(product.id);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
