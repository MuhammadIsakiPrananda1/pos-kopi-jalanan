import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/cart_item_tile.dart';
import 'payment_screen.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen>
    with SingleTickerProviderStateMixin {
  bool _showCart = false;
  late AnimationController _cartController;

  @override
  void initState() {
    super.initState();
    _cartController = AnimationController(
      vsync: this,
      duration: AppConstants.animNormal,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _cartController.dispose();
    super.dispose();
  }

  void _toggleCart() {
    setState(() => _showCart = !_showCart);
    if (_showCart) {
      _cartController.forward();
    } else {
      _cartController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Product list
          Expanded(child: _buildProductList()),
          // Cart panel
          _buildCartPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      centerTitle: true,
      title: Text('KASIR', style: AppTextStyles.appBarTitle),
      actions: [
        Consumer<CartProvider>(
          builder: (_, cart, __) => Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: cart.isEmpty ? null : _toggleCart,
                icon: Icon(
                  _showCart ? Icons.close_rounded : Icons.shopping_cart_rounded,
                  color: cart.isEmpty ? AppColors.textSecondary : AppColors.accent,
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: AppColors.background,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProductList() {
    return Consumer2<ProductProvider, CartProvider>(
      builder: (_, prod, cart, __) {
        if (prod.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        final products = prod.products;
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('Belum ada produk untuk dijual',
                    style: AppTextStyles.bodyMedium),
                Text('Tambah stok kopi di menu Manajemen Stok',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        final nf = NumberFormat.currency(
            locale: 'id', symbol: 'Rp ', decimalDigits: 0);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 180), // Tambah padding bawah agar tidak tertutup panel
          itemCount: products.length,
          itemBuilder: (_, i) {
            final product = products[i];
            final cartItem = cart.items.cast<CartItem?>().firstWhere(
                  (item) => item?.product.id == product.id,
                  orElse: () => null,
                );
            final quantity = cartItem?.quantity ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: quantity > 0
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : AppColors.divider.withValues(alpha: 0.5),
                  width: quantity > 0 ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon Produk
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.coffee_rounded,
                        color: AppColors.accent, size: 20),
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
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Stok: ${product.stock}',
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                              color: product.stock < 10
                                  ? AppColors.error
                                  : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Selektor Jumlah
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quantity > 0) ...[
                        _buildQtyBtn(Icons.remove_rounded,
                            () => cart.removeProduct(product.id)),
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: Text(
                            '$quantity',
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      _buildQtyBtn(Icons.add_rounded, () {
                        if (product.stock > quantity) {
                          cart.addProduct(product);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Stok tidak mencukupi!'),
                                duration: Duration(seconds: 1)),
                          );
                        }
                      }, isPrimary: true),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isPrimary ? AppColors.background : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return Consumer<CartProvider>(
      builder: (_, cart, __) {
        final nf =
            NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

        if (cart.isEmpty) {
          if (_showCart) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => setState(() => _showCart = false));
          }
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: AppConstants.animNormal,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cart header
              GestureDetector(
                onTap: _toggleCart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.shopping_cart_rounded,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${cart.itemCount} item',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 13),
                      ),
                      const Spacer(),
                      Icon(
                        _showCart
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Cart Items (expandable)
              if (_showCart) ...[
                const Divider(height: 1, color: AppColors.divider),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingM, vertical: 4),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return CartItemTile(
                        item: item,
                        onIncrement: () => cart.addProduct(item.product),
                        onDecrement: () => cart.removeProduct(item.product.id),
                        onRemove: () => cart.removeAll(item.product.id),
                      );
                    },
                  ),
                ),
              ],

              // Total & Bayar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                          Text(
                            nf.format(cart.total),
                            style: AppTextStyles.price.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PaymentScreen(),
                            ),
                          );
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payments_rounded,
                                  color: AppColors.background, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'BAYAR',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.background,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 90), // Spasi agar tidak tertutup Navbar Melayang
            ],
          ),
        );
      },
    );
  }
}
