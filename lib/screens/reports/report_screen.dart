import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../providers/transaction_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedDays = 7;
  final List<int> _dayOptions = [1, 7, 30];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<TransactionProvider>().loadReportData(_selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TransactionProvider>(
        builder: (_, txn, __) {
          if (txn.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.accent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),

                  // Summary cards
                  _buildSummaryCards(txn, nf),
                  const SizedBox(height: 20),

                  // Chart
                  _buildRevenueChart(txn),
                  const SizedBox(height: 20),

                  // Top products
                  _buildTopProducts(txn, nf),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final labels = {1: 'Hari Ini', 7: '7 Hari', 30: '30 Hari'};
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _dayOptions.map((days) {
          final isSelected = _selectedDays == days;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDays = days);
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[days] ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(TransactionProvider txn, NumberFormat nf) {
    final totalRevenue = txn.dailyRevenue.fold<double>(
        0,
        (sum, day) =>
            sum + ((day['total_revenue'] as num?)?.toDouble() ?? 0));
    final totalTransactions = txn.dailyRevenue.fold<int>(
        0,
        (sum, day) =>
            sum + ((day['transaction_count'] as num?)?.toInt() ?? 0));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL OMZET',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.background.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        nf.format(totalRevenue),
                        style: AppTextStyles.priceLarge.copyWith(
                            color: AppColors.background, fontSize: 26),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: AppColors.background, size: 24),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Transaksi',
                value: '$totalTransactions',
                icon: Icons.receipt_long_rounded,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Rata-rata/Hari',
                value: nf.format(txn.dailyRevenue.isEmpty
                    ? 0.0
                    : totalRevenue / txn.dailyRevenue.length),
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChart(TransactionProvider txn) {
    if (txn.dailyRevenue.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.textHint, size: 40),
              const SizedBox(height: 8),
              Text('Belum ada data transaksi', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );
    }

    final maxRevenue = txn.dailyRevenue.fold<double>(
        0,
        (max, day) =>
            (day['total_revenue'] as num?)!.toDouble() > max
                ? (day['total_revenue'] as num).toDouble()
                : max);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text('Grafik Pendapatan', style: AppTextStyles.titleLarge),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxRevenue * 1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceHigh,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final nf = NumberFormat.compactCurrency(
                          locale: 'id', symbol: 'Rp ', decimalDigits: 0);
                      return BarTooltipItem(
                        nf.format(rod.toY),
                        AppTextStyles.bodySmall
                            .copyWith(color: AppColors.accent),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= txn.dailyRevenue.length) {
                          return const SizedBox.shrink();
                        }
                        final dateStr =
                            txn.dailyRevenue[index]['date'] as String? ?? '';
                        final date = DateTime.tryParse(dateStr);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            date != null
                                ? DateFormat('dd/MM').format(date)
                                : '',
                            style: AppTextStyles.caption,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: txn.dailyRevenue.asMap().entries.map((entry) {
                  final i = entry.key;
                  final revenue =
                      (entry.value['total_revenue'] as num?)?.toDouble() ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        color: AppColors.accent,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxRevenue * 1.3,
                          color: AppColors.surfaceLight,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(TransactionProvider txn, NumberFormat nf) {
    if (txn.topProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text('Produk Terlaris',
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txn.topProducts.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
            itemBuilder: (context, i) {
              final p = txn.topProducts[i];
              final totalSold = txn.topProducts.isNotEmpty
                  ? (txn.topProducts.first['total_sold'] as num?)?.toDouble() ??
                      1
                  : 1.0;
              final sold = (p['total_sold'] as num?)?.toDouble() ?? 0;
              final fraction = sold / totalSold;

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${i + 1}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: i == 0 ? AppColors.accent : AppColors.textHint,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p['product_name'] as String? ?? '-',
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${p['total_sold']} sold',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                      child: LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          i == 0 ? AppColors.accent : AppColors.textHint,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title,
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
