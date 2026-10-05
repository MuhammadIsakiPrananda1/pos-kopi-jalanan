import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/transaction_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<TransactionProvider>().loadReportData(30);
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Navigator.canPop(context)
          ? AppBar(
              title: Text('Laporan & Analisis', style: AppTextStyles.titleMedium),
              centerTitle: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
            )
          : null,
      body: Consumer<TransactionProvider>(
        builder: (_, txn, __) {
          if (txn.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }

          final groupedSales = _groupSalesByDate(txn.dailySoldItems);
          
          double totalRevenue30 = 0;
          double todayRevenue = 0;
          int totalItems30 = 0;
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

          for (var item in txn.dailySoldItems) {
            final rev = (item['total_revenue'] as num).toDouble();
            final qty = (item['total_sold'] as num).toInt();
            
            totalRevenue30 += rev;
            totalItems30 += qty;
            
            if (item['sale_date'] == todayStr) {
              todayRevenue += rev;
            }
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryHeader(todayRevenue, totalRevenue30, totalItems30, nf),
                const SizedBox(height: 20),
                _buildTopProducts(txn, nf),
                const SizedBox(height: 20),
                _buildDailySalesHistory(groupedSales, nf),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(double todayRevenue, double revenue30, int items, NumberFormat nf) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Omzet Hari Ini', style: AppTextStyles.caption.copyWith(fontSize: 9)),
                    const SizedBox(height: 2),
                    Text(nf.format(todayRevenue), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.divider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Omzet 30 Hari', style: AppTextStyles.caption.copyWith(fontSize: 9)),
                    const SizedBox(height: 2),
                    Text(nf.format(revenue30), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.divider),
          Row(
            children: [
              const Icon(Icons.shopping_bag_rounded, color: AppColors.info, size: 14),
              const SizedBox(width: 8),
              Text('Total Terjual (30 Hari)', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              const Spacer(),
              Text('$items Pcs', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.info)),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupSalesByDate(List<Map<String, dynamic>> sales) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final sale in sales) {
      final date = sale['sale_date'] as String;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(sale);
    }
    return grouped;
  }

  Widget _buildTopProducts(TransactionProvider txn, NumberFormat nf) {
    if (txn.topProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text('Produk Terlaris', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txn.topProducts.length > 5 ? 5 : txn.topProducts.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.3)),
            itemBuilder: (context, i) {
              final p = txn.topProducts[i];
              final sold = (p['total_sold'] as num).toInt();
              final revenue = (p['total_revenue'] as num).toDouble();

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showProductDetail(p, nf),
                  borderRadius: i == 0 
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : i == (txn.topProducts.length > 5 ? 4 : txn.topProducts.length - 1)
                      ? const BorderRadius.vertical(bottom: Radius.circular(12))
                      : null,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: i == 0 ? AppColors.accent : AppColors.surfaceHigh,
                      child: Text('${i + 1}', style: TextStyle(fontSize: 10, color: i == 0 ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(p['product_name'] as String, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(nf.format(revenue), style: AppTextStyles.caption.copyWith(fontSize: 9)),
                    trailing: Text('$sold Pcs', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailySalesHistory(Map<String, List<Map<String, dynamic>>> groupedSales, NumberFormat nf) {
    if (groupedSales.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.textHint, size: 40),
              const SizedBox(height: 12),
              Text('Belum ada riwayat penjualan', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
            ],
          ),
        ),
      );
    }

    final sortedDates = groupedSales.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text('Riwayat Penjualan', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateStr = sortedDates[index];
            final sales = groupedSales[dateStr]!;
            final date = DateTime.parse(dateStr);
            final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
            
            String displayDate = DateFormat('EEEE, dd MMM', 'id').format(date);

            final dayTotal = sales.fold<double>(0, (sum, item) => sum + (item['total_revenue'] as num).toDouble());

            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(displayDate, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: isToday ? AppColors.accent : AppColors.textPrimary)),
                  trailing: Text(nf.format(dayTotal), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                  children: [
                    const Divider(height: 1, color: AppColors.divider),
                    ...sales.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final qty = (item['total_sold'] as num).toInt();
                      final rev = (item['total_revenue'] as num).toDouble();
                      final isLast = i == sales.length - 1;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {}, // Optional action
                          borderRadius: isLast 
                            ? const BorderRadius.vertical(bottom: Radius.circular(12))
                            : null,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            visualDensity: VisualDensity.compact,
                            title: Text(item['product_name'] as String, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                            subtitle: Text('$qty x @ ${nf.format(rev / qty)}', style: AppTextStyles.caption.copyWith(fontSize: 9)),
                            trailing: Text(nf.format(rev), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showProductDetail(Map<String, dynamic> product, NumberFormat nf) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Text('Detail Produk', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 20)),
              ],
            ),
            const SizedBox(height: 20),
            Text(product['product_name'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCompactDetailItem('Terjual', '${product['total_sold']} Pcs', Icons.shopping_bag_rounded, AppColors.info),
                const SizedBox(width: 12),
                _buildCompactDetailItem('Omzet', nf.format(product['total_revenue']), Icons.payments_rounded, AppColors.success),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDetailItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
