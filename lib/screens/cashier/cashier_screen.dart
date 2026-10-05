import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import 'payment_screen.dart';

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

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  late final AnimationController _pulseController;
  int _prevItemCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _pulseController.reverse();
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerHaptic(int count) {
    if (count > _prevItemCount) {
      _pulseController.forward();
      HapticFeedback.lightImpact();
    }
    _prevItemCount = count;
  }

  List<Product> _filterProducts(List<Product> all) {
    var list = all.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
    if (_selectedCategory != 'Semua') {
      list = list.where((p) =>
          p.name.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: isWide ? _buildWideLayout(nf) : _buildNarrowLayout(nf),
        ),
      ),
    );
  }

  // ── Wide Layout (Tablet / Landscape) ───────────────────────────────────────
  Widget _buildWideLayout(NumberFormat nf) => Row(
    children: [
      Expanded(
        flex: 60,
        child: Column(
          children: [
            const _CashierHeader(showBagButton: false),
            _SearchField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
            ),
            _CategoryDropdown(
              selected: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            Expanded(
              child: _ProductGrid(
                nf: nf,
                filter: _filterProducts,
                onStockExceeded: _showStockSnackbar,
                bottomPadding: 32,
              ),
            ),
          ],
        ),
      ),
      Container(width: 1, color: _borderDark),
      SizedBox(
        width: 300,
        child: _WideOrderPanel(nf: nf),
      ),
    ],
  );

  // ── Narrow Layout (Phone / Portrait) ──────────────────────────────────────
  Widget _buildNarrowLayout(NumberFormat nf) {
    return Stack(
      children: [
        Column(
          children: [
            _CashierHeader(
              showBagButton: true,
              onBagTap: () => _openCartSheet(nf),
            ),
            _SearchField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
            ),
            _CategoryDropdown(
              selected: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            Expanded(
              child: _ProductGrid(
                nf: nf,
                filter: _filterProducts,
                onStockExceeded: _showStockSnackbar,
                bottomPadding: 160.0,
              ),
            ),
          ],
        ),

        // Floating Cart Dock placed above the bottom navigation dock
        Consumer<CartProvider>(
          builder: (_, cart, __) {
            _triggerHaptic(cart.itemCount);
            if (cart.isEmpty) return const SizedBox.shrink();
            return Positioned(
              left: 16,
              right: 16,
              bottom: 86, // Ample clearance above the floating navigation dock (bottom 18, height 60)
              child: _FloatingCartBar(
                cart: cart,
                nf: nf,
                onTap: () => _openCartSheet(nf),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openCartSheet(NumberFormat nf) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartModalSheet(nf: nf),
    );
  }

  void _showStockSnackbar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: _stockAmber, size: 16),
            const SizedBox(width: 8),
            Text('Stok produk tidak mencukupi', style: _font(12, FontWeight.w500, _textMain)),
          ],
        ),
        backgroundColor: _cardDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _borderDark),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER BAR
// ══════════════════════════════════════════════════════════════════════════════
class _CashierHeader extends StatelessWidget {
  final bool showBagButton;
  final VoidCallback? onBagTap;

  const _CashierHeader({
    required this.showBagButton,
    this.onBagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                      'Kasir POS',
                      style: _font(15, FontWeight.w700, _textMain, letterSpacing: -0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Catat pesanan pelanggan',
                    style: _font(10, FontWeight.w500, _textMuted),
                  ),
                ),
              ],
            ),
          ),
          const _DigitalClock(),

          // Cart bag trigger
          if (showBagButton) ...[
            const SizedBox(width: 10),
            Consumer<CartProvider>(
              builder: (_, cart, __) {
                final hasItems = !cart.isEmpty;
                return GestureDetector(
                  onTap: hasItems ? onBagTap : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasItems ? _textMain : _cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasItems ? _textMain : _borderDark,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 14,
                          color: hasItems ? _bgDark : _textSub,
                        ),
                        if (hasItems) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${cart.itemCount}',
                            style: _font(11, FontWeight.w700, _bgDark),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEARCH FIELD (SLEEK & COMPACT)
// ══════════════════════════════════════════════════════════════════════════════
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: _font(13, FontWeight.w400, _textMain),
          cursorColor: _textMain,
          cursorWidth: 1.5,
          decoration: InputDecoration(
            hintText: 'Cari nama produk...',
            hintStyle: _font(12, FontWeight.w400, _textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: _textMuted, size: 16),
            suffixIcon: controller.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: const Icon(Icons.close_rounded, color: _textMuted, size: 14),
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
              borderSide: const BorderSide(color: _textSub, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CATEGORY DROPDOWN (MINIMALIST)
// ══════════════════════════════════════════════════════════════════════════════
class _CategoryDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  static const _categories = AppConstants.defaultCategories;

  const _CategoryDropdown({
    required this.selected,
    required this.onSelected,
  });

  Future<void> _showCategoryMenu(BuildContext chipContext) async {
    final button = chipContext.findRenderObject() as RenderBox?;
    final overlay = Navigator.of(chipContext)
        .overlay
        ?.context
        .findRenderObject() as RenderBox?;
    if (button == null || overlay == null || !button.hasSize) return;

    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = button.localToGlobal(
      Offset(button.size.width, button.size.height + 6),
      ancestor: overlay,
    );

    final result = await showMenu<String>(
      context: chipContext,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      color: _surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _borderDark, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      menuPadding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 176, maxWidth: 220),
      items: [
        for (final cat in _categories)
          PopupMenuItem<String>(
            value: cat,
            height: 36,
            padding: EdgeInsets.zero,
            child: _DropdownItem(
              label: cat,
              isSelected: selected == cat,
            ),
          ),
      ],
    );

    if (!chipContext.mounted) return;
    if (result != null && result != selected) {
      HapticFeedback.selectionClick();
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: 38,
          child: Builder(
            builder: (chipContext) => Material(
              color: _surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: _borderDark, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showCategoryMenu(chipContext),
                splashColor: _textMain.withValues(alpha: 0.06),
                highlightColor: _textMain.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 13,
                        color: _textMuted,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        selected,
                        style: _font(11.5, FontWeight.w600, _textMain),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: _textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _DropdownItem({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? _textMain.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: _font(
                11.5,
                isSelected ? FontWeight.w700 : FontWeight.w500,
                isSelected ? _textMain : _textSub,
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_rounded, size: 14, color: _textMain),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PRODUCT GRID (COMPACT & SLEEK)
// ══════════════════════════════════════════════════════════════════════════════
class _ProductGrid extends StatelessWidget {
  final NumberFormat nf;
  final List<Product> Function(List<Product>) filter;
  final VoidCallback onStockExceeded;
  final double bottomPadding;

  const _ProductGrid({
    required this.nf,
    required this.filter,
    required this.onStockExceeded,
    this.bottomPadding = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, CartProvider>(
      builder: (_, prodProvider, cartProvider, __) {
        if (prodProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _textMuted, strokeWidth: 1.5),
          );
        }

        final products = filter(prodProvider.products);

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: _surfaceDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off_rounded, size: 24, color: _textMuted),
                ),
                const SizedBox(height: 10),
                Text('Menu tidak ditemukan', style: _font(13, FontWeight.w500, _textSub)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 155,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.88,
          ),
          itemCount: products.length,
          itemBuilder: (_, index) {
            final product = products[index];
            final cartItem = cartProvider.items
                .cast<CartItem?>()
                .firstWhere((x) => x?.product.id == product.id, orElse: () => null);
            final qty = cartItem?.quantity ?? 0;

            return _CompactProductTile(
              product: product,
              quantity: qty,
              nf: nf,
              onAdd: () {
                if (product.stock > qty) {
                  cartProvider.addProduct(product);
                } else {
                  onStockExceeded();
                }
              },
              onRemove: () => cartProvider.removeProduct(product.id),
            );
          },
        );
      },
    );
  }
}

// ── Compact Product Tile ─────────────────────────────────────────────────────
class _CompactProductTile extends StatelessWidget {
  final Product product;
  final int quantity;
  final NumberFormat nf;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CompactProductTile({
    required this.product,
    required this.quantity,
    required this.nf,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;
    final isSoldOut = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: inCart ? _cardDark : _surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: inCart ? _textMain.withValues(alpha: 0.25) : _borderDark,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isSoldOut ? null : onAdd,
          borderRadius: BorderRadius.circular(10),
          splashColor: _textMain.withValues(alpha: 0.04),
          highlightColor: _textMain.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: minimal icon + stock indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _borderSubtle),
                      ),
                      child: Icon(
                        Icons.local_cafe_outlined,
                        size: 13,
                        color: inCart ? _textMain : _textMuted,
                      ),
                    ),
                    _buildStockIndicator(isSoldOut, isLowStock),
                  ],
                ),
                const Spacer(),
                // Product Name
                Text(
                  product.name,
                  style: _font(
                    11.5,
                    FontWeight.w600,
                    isSoldOut ? _textMuted : _textMain,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Price
                Text(
                  nf.format(product.price),
                  style: _font(
                    10.5,
                    FontWeight.w600,
                    inCart ? _textMain : _textSub,
                  ),
                ),
                const SizedBox(height: 6),
                // Action: Add / Stepper / Sold out
                if (isSoldOut)
                  _buildSoldOutBadge()
                else if (inCart)
                  _buildStepper()
                else
                  _buildAddButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator(bool isSoldOut, bool isLowStock) {
    if (isSoldOut) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: _stockRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Habis',
          style: _font(8.5, FontWeight.w600, _stockRed),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLowStock ? _stockAmber : _stockGreen,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '${product.stock}',
          style: _font(9, FontWeight.w500, isLowStock ? _stockAmber : _textMuted),
        ),
      ],
    );
  }

  Widget _buildSoldOutBadge() => Container(
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _borderSubtle,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text('Habis', style: _font(9, FontWeight.w600, _textMuted)),
  );

  Widget _buildAddButton() => Container(
    height: 24,
    decoration: BoxDecoration(
      color: _cardDark,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _borderDark),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_rounded, size: 11, color: _textSub),
        const SizedBox(width: 3),
        Text('Tambah', style: _font(9.5, FontWeight.w600, _textSub)),
      ],
    ),
  );

  Widget _buildStepper() => Row(
    children: [
      _MicroBtn(
        icon: Icons.remove_rounded,
        onTap: onRemove,
        filled: false,
      ),
      Expanded(
        child: Text(
          '$quantity',
          textAlign: TextAlign.center,
          style: _font(11.5, FontWeight.w700, _textMain),
        ),
      ),
      _MicroBtn(
        icon: Icons.add_rounded,
        onTap: onAdd,
        filled: true,
      ),
    ],
  );
}

class _MicroBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _MicroBtn({
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: filled ? _textMain : _cardDark,
    borderRadius: BorderRadius.circular(5),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: filled ? _textMain : _borderDark,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 12,
          color: filled ? _bgDark : _textMain,
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// FLOATING CART BAR (NARROW PHONE VIEW)
// ══════════════════════════════════════════════════════════════════════════════
class _FloatingCartBar extends StatelessWidget {
  final CartProvider cart;
  final NumberFormat nf;
  final VoidCallback onTap;

  const _FloatingCartBar({
    required this.cart,
    required this.nf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _surfaceDark.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: _cardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _borderDark),
                  ),
                  child: Text(
                    '${cart.itemCount} item',
                    style: _font(10.5, FontWeight.w600, _textSub),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nf.format(cart.total),
                    style: _font(14.5, FontWeight.w700, _textMain, letterSpacing: -0.3),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _textMain,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Bayar', style: _font(11.5, FontWeight.w700, _bgDark)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: _bgDark),
                    ],
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

// ══════════════════════════════════════════════════════════════════════════════
// CART MODAL SHEET (NARROW PHONE VIEW)
// ══════════════════════════════════════════════════════════════════════════════
class _CartModalSheet extends StatelessWidget {
  final NumberFormat nf;
  const _CartModalSheet({required this.nf});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (_, cart, __) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: _borderDark, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: _textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
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
                  'Keranjang Pesanan',
                  style: _font(14, FontWeight.w700, _textMain),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${cart.itemCount})',
                  style: _font(12, FontWeight.w500, _textSub),
                ),
                const Spacer(),
                if (!cart.isEmpty)
                  GestureDetector(
                    onTap: () => _confirmClear(context, cart),
                    child: Text(
                      'Kosongkan',
                      style: _font(11, FontWeight.w500, _textMuted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Items list
            if (cart.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Keranjang kosong', style: _font(12, FontWeight.w500, _textSub)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.40,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final item = cart.items[index];
                    return _CartItemRow(
                      item: item,
                      nf: nf,
                      onAdd: () => cart.addProduct(item.product),
                      onRemove: () => cart.removeProduct(item.product.id),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: _borderDark),
            const SizedBox(height: 14),

            // Summary & Checkout
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pembayaran', style: _font(10.5, FontWeight.w400, _textSub)),
                    const SizedBox(height: 2),
                    Text(
                      nf.format(cart.total),
                      style: _font(18, FontWeight.w800, _textMain, letterSpacing: -0.4),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: cart.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PaymentScreen()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _textMain,
                    foregroundColor: _bgDark,
                    disabledBackgroundColor: _cardDark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Bayar Sekarang',
                    style: _font(12.5, FontWeight.w700, cart.isEmpty ? _textMuted : _bgDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Kosongkan Keranjang?', style: _font(13.5, FontWeight.w700, _textMain)),
        content: Text('Semua pesanan saat ini akan dihapus.', style: _font(12, FontWeight.w400, _textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: _font(11.5, FontWeight.w500, _textSub)),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Kosongkan', style: _font(11.5, FontWeight.w600, _stockRed)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CART ITEM ROW
// ══════════════════════════════════════════════════════════════════════════════
class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final NumberFormat nf;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartItemRow({
    required this.item,
    required this.nf,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: _font(11.5, FontWeight.w600, _textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  nf.format(item.subtotal),
                  style: _font(10, FontWeight.w500, _textSub),
                ),
              ],
            ),
          ),
          _MicroBtn(icon: Icons.remove_rounded, onTap: onRemove, filled: false),
          SizedBox(
            width: 26,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: _font(11.5, FontWeight.w700, _textMain),
            ),
          ),
          _MicroBtn(icon: Icons.add_rounded, onTap: onAdd, filled: true),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDE ORDER PANEL (TABLET / DESKTOP SIDEBAR)
// ══════════════════════════════════════════════════════════════════════════════
class _WideOrderPanel extends StatelessWidget {
  final NumberFormat nf;
  const _WideOrderPanel({required this.nf});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (_, cart, __) => Container(
        color: _surfaceDark,
        child: Column(
          children: [
            // Header
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
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
                  Text('Daftar Pesanan', style: _font(13.5, FontWeight.w700, _textMain)),
                  if (cart.itemCount > 0) ...[
                    const SizedBox(width: 6),
                    Text('(${cart.itemCount})', style: _font(12, FontWeight.w500, _textSub)),
                  ],
                  const Spacer(),
                  if (!cart.isEmpty)
                    GestureDetector(
                      onTap: () => cart.clear(),
                      child: Text('Hapus', style: _font(11, FontWeight.w500, _textMuted)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderDark),

            // Order items
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 24, color: _textMuted),
                          const SizedBox(height: 8),
                          Text('Keranjang kosong', style: _font(12, FontWeight.w500, _textSub)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final item = cart.items[index];
                        return _CartItemRow(
                          item: item,
                          nf: nf,
                          onAdd: () => cart.addProduct(item.product),
                          onRemove: () => cart.removeProduct(item.product.id),
                        );
                      },
                    ),
            ),

            // Footer
            const Divider(height: 1, color: _borderDark),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: _font(11, FontWeight.w400, _textSub)),
                      Text(
                        nf.format(cart.total),
                        style: _font(16.5, FontWeight.w800, _textMain, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: cart.isEmpty
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PaymentScreen()),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _textMain,
                        foregroundColor: _bgDark,
                        disabledBackgroundColor: _cardDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Bayar Sekarang',
                        style: _font(12, FontWeight.w700, cart.isEmpty ? _textMuted : _bgDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIGITAL LIVE CLOCK
// ══════════════════════════════════════════════════════════════════════════════
class _DigitalClock extends StatefulWidget {
  const _DigitalClock();

  @override
  State<_DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<_DigitalClock> {
  late String _timeStr;
  late String _dateStr;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startTimer();
  }

  void _updateTime() {
    final now = DateTime.now();
    _timeStr = DateFormat('HH:mm').format(now);
    _dateStr = DateFormat('EEE, d MMM', 'id').format(now);
  }

  void _startTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 20));
      if (mounted) setState(_updateTime);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(_timeStr, style: _font(12, FontWeight.w600, _textMain)),
      Text(_dateStr, style: _font(8.5, FontWeight.w400, _textMuted)),
    ],
  );
}
