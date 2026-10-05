import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import 'product_form_screen.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
const _bgDark      = Color(0xFF09090B);
const _surfaceDark = Color(0xFF141417);
const _cardDark    = Color(0xFF18181B);
const _borderDark  = Color(0xFF27272A);
const _borderSubtle= Color(0xFF1F1F23);
const _textMuted   = Color(0xFF71717A);
const _textSub     = Color(0xFFA1A1AA);
const _textMain    = Color(0xFFFAFAFA);
const _stockGreen  = Color(0xFF22C55E);
const _stockAmber  = Color(0xFFF59E0B);
const _stockRed    = Color(0xFFEF4444);
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _font(double size, FontWeight weight, Color color, {double letterSpacing = 0}) =>
    GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _bulkDelete() async {
    final provider = context.read<ProductProvider>();
    final count = _selectedIds.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderDark),
        ),
        title: Text(
          'Hapus $count produk?',
          style: _font(14, FontWeight.w700, _textMain),
        ),
        content: Text(
          'Produk yang dihapus tidak dapat dikembalikan.',
          style: _font(12, FontWeight.w400, _textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: _font(12, FontWeight.w600, _textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: _font(12, FontWeight.w700, _stockRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      for (final id in _selectedIds) {
        await provider.deleteProduct(id);
      }
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Consumer<ProductProvider>(
            builder: (_, prod, __) {
              final products = prod.products
                  .where((p) => p.name.toLowerCase().contains(_searchQuery))
                  .toList()
                ..sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));

              return Column(
                children: [
                  _buildHeader(),
                  _buildSummaryStrip(prod),
                  _buildSearchField(),
                  Expanded(child: _buildBody(prod, products, nf)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton(
                heroTag: 'fab_products',
                onPressed: () => _openForm(context),
                backgroundColor: _textMain,
                foregroundColor: _bgDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_rounded, size: 26),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    if (_isSelectionMode) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: _clearSelection,
              icon: const Icon(Icons.close_rounded, color: _textSub, size: 20),
            ),
            Text(
              '${_selectedIds.length} dipilih',
              style: _font(14, FontWeight.w700, _textMain),
            ),
            const Spacer(),
            IconButton(
              onPressed: _bulkDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: _stockRed,
                size: 20,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
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
                      'Manajemen Stok',
                      style: _font(
                        15,
                        FontWeight.w700,
                        _textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Kelola produk & persediaan kopi',
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

  // ── Ringkasan Stok ─────────────────────────────────────────────────────────
  Widget _buildSummaryStrip(ProductProvider prod) {
    final total = prod.products.length;
    final low = prod.products.where((p) => p.stock > 0 && p.stock <= 5).length;
    final out = prod.products.where((p) => p.stock <= 0).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.inventory_2_outlined,
            value: '$total',
            label: 'Total Produk',
            color: _textMain,
            iconColor: _textSub,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.warning_amber_rounded,
            value: '$low',
            label: 'Stok Menipis',
            color: low > 0 ? _stockAmber : _textMain,
            iconColor: low > 0 ? _stockAmber : _textSub,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.remove_circle_outline_rounded,
            value: '$out',
            label: 'Stok Habis',
            color: out > 0 ? _stockRed : _textMain,
            iconColor: out > 0 ? _stockRed : _textSub,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderDark, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(height: 6),
            Text(value, style: _font(15, FontWeight.w700, color)),
            const SizedBox(height: 1),
            Text(
              label,
              style: _font(9.5, FontWeight.w500, _textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: _searchController,
          onChanged: (v) =>
              setState(() => _searchQuery = v.toLowerCase().trim()),
          style: _font(12.5, FontWeight.w400, _textMain),
          cursorColor: _textMain,
          cursorWidth: 1.5,
          decoration: InputDecoration(
            hintText: 'Cari produk...',
            hintStyle: _font(12, FontWeight.w400, _textMuted),
            prefixIcon:
                const Icon(Icons.search_rounded, color: _textMuted, size: 16),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: _textMuted,
                      size: 14,
                    ),
                  )
                : null,
            filled: true,
            fillColor: _surfaceDark,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderDark, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderDark, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _textMain, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(
    ProductProvider prod,
    List<Product> products,
    NumberFormat nf,
  ) {
    if (prod.isLoading && prod.products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _textMain, strokeWidth: 2),
      );
    }

    if (products.isEmpty) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
        child: _buildEmptyState(),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 150),
      itemCount: products.length,
      itemBuilder: (_, i) => _buildProductTile(products[i], nf),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderDark, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: _borderSubtle),
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 24,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'Produk tidak ditemukan' : 'Belum ada produk',
            style: _font(13, FontWeight.w600, _textMain),
          ),
          const SizedBox(height: 3),
          Text(
            isSearching
                ? 'Coba kata kunci lain'
                : 'Tap tombol + untuk menambah produk',
            textAlign: TextAlign.center,
            style: _font(11, FontWeight.w400, _textSub),
          ),
        ],
      ),
    );
  }

  // ── Product Tile ───────────────────────────────────────────────────────────
  Widget _buildProductTile(Product product, NumberFormat nf) {
    final isSelected = _selectedIds.contains(product.id);
    final isSoldOut = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected ? _cardDark : _surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _textMain.withValues(alpha: 0.3)
                : _borderDark,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onLongPress: () => _toggleSelection(product.id),
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(product.id);
              } else {
                _openForm(context, product: product);
              }
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: _textMain.withValues(alpha: 0.04),
            highlightColor: _textMain.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (_isSelectionMode) ...[
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? _textMain : _textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Icon produk
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _borderSubtle),
                    ),
                    child: Icon(
                      Icons.local_cafe_outlined,
                      size: 16,
                      color: isSoldOut ? _textMuted : _textSub,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info produk
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: _font(
                            12.5,
                            FontWeight.w600,
                            isSoldOut ? _textMuted : _textMain,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              nf.format(product.price),
                              style: _font(11, FontWeight.w600, _textSub),
                            ),
                            const SizedBox(width: 8),
                            _buildStockBadge(
                              isSoldOut: isSoldOut,
                              isLowStock: isLowStock,
                              stock: product.stock,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!_isSelectionMode)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _textMuted,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge({
    required bool isSoldOut,
    required bool isLowStock,
    required int stock,
  }) {
    final Color color;
    final Color background;
    final String label;

    if (isSoldOut) {
      color = _stockRed;
      background = _stockRed.withValues(alpha: 0.14);
      label = 'Habis';
    } else if (isLowStock) {
      color = _stockAmber;
      background = _stockAmber.withValues(alpha: 0.14);
      label = 'Sisa $stock';
    } else {
      color = _textMuted;
      background = _borderSubtle;
      label = 'Stok $stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: _font(9.5, FontWeight.w600, color)),
    );
  }

  void _openForm(BuildContext context, {Product? product}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }
}
