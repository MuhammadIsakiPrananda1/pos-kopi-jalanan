import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/finance_provider.dart';
import '../cashier/cashier_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final txnProv = context.read<TransactionProvider>();
    final prodProv = context.read<ProductProvider>();
    final finProv = context.read<FinanceProvider>();
    await Future.wait([
      txnProv.loadDailySummary(),
      txnProv.loadReportData(7),
      finProv.loadRecords(),
      if (prodProv.products.isEmpty) prodProv.loadProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final df = DateFormat('EEEE, dd MMMM', 'id');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER RINGKAS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppConstants.appName, 
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent)),
                        Text(df.format(DateTime.now()), 
                          style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.storefront_rounded, color: AppColors.accent, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // MAIN STAT CARD (SALDO & REVENUE)
                Consumer2<TransactionProvider, FinanceProvider>(
                  builder: (_, txn, fin, __) => _buildMainStatCard(txn, fin, nf),
                ),
                const SizedBox(height: 24),

                // QUICK GRID SERVICES
                Text('Menu Utama', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildQuickGrid(context),
                const SizedBox(height: 24),

                // TODAY'S INSIGHTS (DETAIL)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Terlaris Hari Ini', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<TransactionProvider>(
                  builder: (_, txn, __) => _buildTodayInsights(txn, nf),
                ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatCard(TransactionProvider txn, FinanceProvider fin, NumberFormat nf) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Saldo Kas', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(nf.format(fin.balance), 
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Omzet Hari Ini', nf.format(txn.todayRevenue), Icons.auto_graph_rounded),
              _buildMiniStat('Transaksi', '${txn.todayTransactionCount}', Icons.receipt_long_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white60, size: 14),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickGrid(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.8,
      children: [
        _buildGridItem(context, 'Kasir', Icons.add_shopping_cart_rounded, AppColors.accent, () {
          nav.setIndex(2); // New Tab Kasir
        }),
        _buildGridItem(context, 'Produk', Icons.inventory_2_rounded, AppColors.info, () {
          nav.setIndex(1); // New Tab Produk
        }),
        _buildGridItem(context, 'Keuangan', Icons.account_balance_rounded, AppColors.success, () {
          nav.setIndex(3); // New Tab Laporan & Keuangan
        }),
        _buildGridItem(context, 'Laporan', Icons.bar_chart_rounded, Colors.orange, () {
          nav.setIndex(3); // New Tab Laporan & Keuangan
        }),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, fontSize: 10)),
      ],
    );
  }

  Widget _buildTodayInsights(TransactionProvider txn, NumberFormat nf) {
    if (txn.topProducts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('Belum ada transaksi hari ini', style: TextStyle(color: Colors.white24, fontSize: 12))),
      );
    }

    return Column(
      children: txn.topProducts.take(3).map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.coffee_rounded, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['product_name'] as String? ?? '-', 
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${p['total_sold']} item terjual', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text(nf.format(p['total_revenue'] ?? 0), 
                style: AppTextStyles.price.copyWith(fontSize: 14, color: AppColors.accent)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
