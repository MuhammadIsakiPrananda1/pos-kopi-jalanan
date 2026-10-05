import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/finance_provider.dart';
import '../reports/report_screen.dart';

// ── Donut palette (Tren 7 Hari: makin baru makin terang) ─────────────────────
const List<Color> _donutPalette = [
  Color(0xFFB45309),
  Color(0xFFD97706),
  Color(0xFFF59E0B),
  Color(0xFFFBBF24),
  Color(0xFFFCD34D),
  Color(0xFFFDE68A),
  Color(0xFFFEF3C7),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isBalanceVisible = true;
  int? _selectedChartIndex;

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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LiveClockHeader(),
              const SizedBox(height: 20),
              Consumer<ProductProvider>(
                builder: (_, prodProv, __) => _buildStockAlert(prodProv),
              ),
              Consumer2<TransactionProvider, FinanceProvider>(
                builder: (_, txn, fin, __) => _buildRevenueCard(txn, fin, nf),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                'Tren 7 Hari',
                actionLabel: 'Lihat Laporan',
                onAction: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              Consumer<TransactionProvider>(
                builder: (_, txn, __) => _buildTrendChart(txn, nf),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel('Produk Terlaris'),
              const SizedBox(height: 10),
              Consumer<TransactionProvider>(
                builder: (_, txn, __) => _buildTopProducts(txn, nf),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildStockAlert(ProductProvider prodProv) {
    final low = prodProv.products.where((p) => p.stock <= 5).toList();
    if (low.isEmpty) return const SizedBox.shrink();

    final nav = context.read<NavigationProvider>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          nav.setIndex(1);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1710),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${low.length} stok menipis: ${low.map((e) => e.name).take(2).join(', ')}${low.length > 2 ? '...' : ''}',
                  style: GoogleFonts.quicksand(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFFBBF24),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    TransactionProvider txn,
    FinanceProvider fin,
    NumberFormat nf,
  ) {
    final double todayRev = txn.todayRevenue;
    final int todayCount = txn.todayTransactionCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Omzet Hari Ini',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isBalanceVisible = !_isBalanceVisible);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _isBalanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isBalanceVisible ? nf.format(todayRev) : 'Rp ••••••••',
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFF27272A)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetaItem(Icons.receipt_long_rounded, '$todayCount transaksi'),
              const SizedBox(width: 20),
              _buildMetaItem(
                Icons.account_balance_wallet_rounded,
                _isBalanceVisible ? 'Kas ${nf.format(fin.balance)}' : 'Kas Rp ••••••',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                actionLabel,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrendChart(TransactionProvider txn, NumberFormat nf) {
    final now = DateTime.now();
    final Map<String, double> revByDate = {};
    for (var r in txn.dailyRevenue) {
      final d = r['date']?.toString() ?? '';
      final rev = (r['total_revenue'] as num?)?.toDouble() ?? 0.0;
      revByDate[d] = rev;
    }

    final List<Map<String, dynamic>> daysData = [];
    double totalRev = 0;
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(day);
      final dayLabel = DateFormat('E', 'id').format(day);
      final rev = revByDate[dateKey] ?? 0.0;
      totalRev += rev;
      daysData.add({
        'label': dayLabel,
        'revenue': rev,
        'isToday': i == 0,
        'percent': 0.0,
      });
    }
    for (final d in daysData) {
      final rev = d['revenue'] as double;
      d['percent'] = totalRev > 0 ? rev / totalRev : 0.0;
    }

    if (totalRev <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF27272A), width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.donut_large_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada penjualan 7 hari terakhir',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Grafik donat muncul setelah ada transaksi',
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final int? selectedIndex = (_selectedChartIndex != null &&
            _selectedChartIndex! >= 0 &&
            _selectedChartIndex! < daysData.length)
        ? _selectedChartIndex
        : null;

    final segments = List.generate(
      daysData.length,
      (i) => _DonutSegment(
        percent: daysData[i]['percent'] as double,
        color: _donutPalette[i],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Donut chart + info tengah
          SizedBox(
            width: 136,
            height: 136,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(136),
                  painter: _DonutChartPainter(
                    segments: segments,
                    selectedIndex: selectedIndex,
                  ),
                ),
                SizedBox(
                  width: 84,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: selectedIndex == null
                        ? [
                            Text(
                              'Total 7 Hari',
                              style: GoogleFonts.quicksand(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isBalanceVisible
                                    ? nf.format(totalRev)
                                    : 'Rp ••••••',
                                style: GoogleFonts.quicksand(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ]
                        : [
                            Text(
                              daysData[selectedIndex]['label'] as String,
                              style: GoogleFonts.quicksand(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatPercent(
                                (daysData[selectedIndex]['percent'] as double) *
                                    100,
                              ),
                              style: GoogleFonts.quicksand(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isBalanceVisible
                                    ? nf.format(
                                        daysData[selectedIndex]['revenue'])
                                    : 'Rp ••••••',
                                style: GoogleFonts.quicksand(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Legend + persentase
          Expanded(
            child: Column(
              children: List.generate(daysData.length, (i) {
                final d = daysData[i];
                final bool isSelected = selectedIndex == i;
                final bool isToday = d['isToday'] as bool;
                final double pct = (d['percent'] as double) * 100;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(
                      () => _selectedChartIndex = isSelected ? null : i,
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1F1F24)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _donutPalette[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            d['label'] as String,
                            style: GoogleFonts.quicksand(
                              fontSize: 10.5,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isToday || isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatPercent(pct),
                          style: GoogleFonts.quicksand(
                            fontSize: 10.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(TransactionProvider txn, NumberFormat nf) {
    if (txn.topProducts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF27272A), width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.local_cafe_outlined,
              color: AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada transaksi hari ini',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Mulai catat pesanan lewat Kasir POS',
              style: GoogleFonts.quicksand(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final displayItems = txn.topProducts.take(5).toList();
    final maxSold = displayItems.isNotEmpty
        ? ((displayItems.first['total_sold'] as num?)?.toInt() ?? 1)
        : 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayItems.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFF1F1F24),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final p = displayItems[index];
          final int sold = (p['total_sold'] as num?)?.toInt() ?? 0;
          final double revenue =
              (p['total_revenue'] as num?)?.toDouble() ?? 0.0;
          final String name = p['product_name'] as String? ?? '-';
          final double proportion =
              maxSold > 0 ? (sold / maxSold).clamp(0.1, 1.0) : 0.1;

          final rankColors = [
            const Color(0xFFF59E0B),
            const Color(0xFFA1A1AA),
            const Color(0xFFD97706),
          ];
          final rankColor =
              index < 3 ? rankColors[index] : AppColors.textSecondary;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: rankColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.quicksand(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$sold terjual',
                            style: GoogleFonts.quicksand(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: proportion,
                                minHeight: 3,
                                backgroundColor: const Color(0xFF222228),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  index == 0
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF52525B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isBalanceVisible ? nf.format(revenue) : 'Rp ••••••',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatPercent(double value) {
  if (value > 0 && value < 0.1) return '<0,1%';
  final digits = value >= 10 || value == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits).replaceAll('.', ',')}%';
}

class _DonutSegment {
  final double percent;
  final Color color;

  const _DonutSegment({required this.percent, required this.color});
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final int? selectedIndex;

  const _DonutChartPainter({
    required this.segments,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double strokeWidth = 15;
    final double radius = (size.width - strokeWidth) / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const double gap = 0.035;
    const double startAngle = -math.pi / 2;

    // Background track (juga tampil untuk hari tanpa penjualan)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = const Color(0xFF27272A),
    );

    double angle = startAngle;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.percent <= 0) continue;

      final double sweep = math.max(seg.percent * 2 * math.pi - gap, 0.015);
      final bool isSelected = selectedIndex == i;
      final bool dimmed = selectedIndex != null && !isSelected;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 3 : strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = dimmed ? seg.color.withValues(alpha: 0.28) : seg.color;

      canvas.drawArc(rect, angle, sweep, false, paint);
      angle += seg.percent * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        !_sameSegments(oldDelegate.segments, segments);
  }

  bool _sameSegments(List<_DonutSegment> a, List<_DonutSegment> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].percent != b[i].percent || a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }
}

// ── Live Clock Header (isolated widget agar scroll tidak terganggu) ─────────
class _LiveClockHeader extends StatefulWidget {
  const _LiveClockHeader();

  @override
  State<_LiveClockHeader> createState() => _LiveClockHeaderState();
}

class _LiveClockHeaderState extends State<_LiveClockHeader> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final h = _now.hour;
    if (h >= 4 && h < 11) return 'Selamat pagi';
    if (h >= 11 && h < 15) return 'Selamat siang';
    if (h >= 15 && h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id').format(_now);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: GoogleFonts.quicksand(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                dateStr,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF27272A), width: 1.2),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/logo_mark.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.local_cafe_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}