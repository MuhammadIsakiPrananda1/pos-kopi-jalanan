import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/finance_record.dart';
import '../../providers/finance_provider.dart';
import '../../providers/transaction_provider.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
const _bgDark      = Color(0xFF09090B);
const _surfaceDark = Color(0xFF141417);
const _cardDark    = Color(0xFF18181B);
const _borderDark  = Color(0xFF27272A);
const _borderSubtle= Color(0xFF1F1F23);
const _textMuted   = Color(0xFF71717A);
const _textSub     = Color(0xFFA1A1AA);
const _textMain    = Color(0xFFFAFAFA);
const _incomeGreen = Color(0xFF22C55E);
const _expenseRed  = Color(0xFFEF4444);
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _font(double size, FontWeight weight, Color color, {double letterSpacing = 0}) =>
    GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (_, fin, __) {
            if (fin.isLoading && fin.records.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _textMain,
                  strokeWidth: 2,
                ),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildBalanceCard(fin, nf),
                        const SizedBox(height: 20),
                        _buildSectionLabel('Riwayat Catatan'),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (fin.records.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            _buildRecordTile(context, fin.records[i], fin, nf),
                        childCount: fin.records.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          heroTag: 'fab_finance',
          onPressed: () {
            HapticFeedback.lightImpact();
            _showAddRecordSheet(context);
          },
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

  // ── Header (konsisten dengan Kasir, Stok, & lain-lain) ─────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _incomeGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Keuangan',
              style: _font(15, FontWeight.w700, _textMain, letterSpacing: -0.2),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Catat pemasukan & pengeluaran',
            style: _font(10, FontWeight.w500, _textMuted),
          ),
        ),
      ],
    );
  }

  // ── Saldo Card (mengikuti gaya kartu Omzet di Dashboard) ───────────────────
  Widget _buildBalanceCard(FinanceProvider fin, NumberFormat nf) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Saat Ini',
            style: _font(12, FontWeight.w500, _textSub),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nf.format(fin.balance),
              style: _font(
                28,
                FontWeight.w700,
                Colors.white,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _borderDark),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetaItem(
                Icons.south_west_rounded,
                'Masuk ${nf.format(fin.totalIncome)}',
                _incomeGreen,
              ),
              const SizedBox(width: 20),
              _buildMetaItem(
                Icons.north_east_rounded,
                'Keluar ${nf.format(fin.totalExpense)}',
                _expenseRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: _font(11.5, FontWeight.w500, _textSub),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: _font(14, FontWeight.w600, _textMain),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 24,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada catatan',
              style: _font(13, FontWeight.w600, _textMain),
            ),
            const SizedBox(height: 3),
            Text(
              'Tap tombol + untuk mencatat pemasukan/pengeluaran',
              textAlign: TextAlign.center,
              style: _font(11, FontWeight.w400, _textSub),
            ),
          ],
        ),
      ),
    );
  }

  // ── Record Tile ────────────────────────────────────────────────────────────
  Widget _buildRecordTile(
    BuildContext context,
    FinanceRecord record,
    FinanceProvider provider,
    NumberFormat nf,
  ) {
    final isIncome = record.isIncome;
    final color = isIncome ? _incomeGreen : _expenseRed;
    final df = DateFormat('dd MMM, HH:mm', 'id');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderDark, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showRecordDetail(context, record, nf),
            onLongPress: () => _confirmDelete(context, record, provider),
            borderRadius: BorderRadius.circular(12),
            splashColor: _textMain.withValues(alpha: 0.04),
            highlightColor: _textMain.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.description,
                          style: _font(
                            12.5,
                            FontWeight.w600,
                            _textMain,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          df.format(record.createdAt),
                          style: _font(10, FontWeight.w500, _textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${isIncome ? '+' : '-'}${nf.format(record.amount)}',
                    style: _font(12.5, FontWeight.w700, color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Detail Sheet ───────────────────────────────────────────────────────────
  void _showRecordDetail(
    BuildContext context,
    FinanceRecord record,
    NumberFormat nf,
  ) {
    final color = record.isIncome ? _incomeGreen : _expenseRed;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: _borderDark, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: _textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Detail Catatan',
                  style: _font(14, FontWeight.w700, _textMain),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderDark),
              ),
              child: Column(
                children: [
                  Text(
                    record.isIncome ? 'PEMASUKAN' : 'PENGELUARAN',
                    style: _font(
                      9.5,
                      FontWeight.w600,
                      color,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${record.isIncome ? '+' : '-'}${nf.format(record.amount)}',
                      style: _font(
                        22,
                        FontWeight.w800,
                        color,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: _borderDark),
                  const SizedBox(height: 12),
                  _buildDetailRow('Keterangan', record.description),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    'Tanggal',
                    DateFormat('EEEE, dd MMM yyyy', 'id')
                        .format(record.createdAt),
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    'Jam',
                    DateFormat('HH:mm:ss', 'id').format(record.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Delete button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: Material(
                color: _expenseRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                    _confirmDelete(context, record, context.read<FinanceProvider>());
                  },
                  splashColor: _expenseRed.withValues(alpha: 0.12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _expenseRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: _expenseRed,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hapus Catatan',
                          style: _font(12, FontWeight.w600, _expenseRed),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: _font(10.5, FontWeight.w500, _textMuted)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: _font(10.5, FontWeight.w600, _textSub),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Add Record Sheet ───────────────────────────────────────────────────────
  void _showAddRecordSheet(BuildContext context) {
    FinanceType selectedType = FinanceType.income;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GestureDetector(
        onTap: () => FocusScope.of(ctx).unfocus(),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: _surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: _borderDark, width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _textMuted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
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
                        color: _incomeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tambah Catatan',
                      style: _font(14, FontWeight.w700, _textMain),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Type selector
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Pemasukan',
                        icon: Icons.south_west_rounded,
                        color: _incomeGreen,
                        isSelected: selectedType == FinanceType.income,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(
                            () => selectedType = FinanceType.income,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTypeButton(
                        label: 'Pengeluaran',
                        icon: Icons.north_east_rounded,
                        color: _expenseRed,
                        isSelected: selectedType == FinanceType.expense,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(
                            () => selectedType = FinanceType.expense,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Amount
                SizedBox(
                  height: 44,
                  child: TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CurrencyInputFormatter(),
                    ],
                    style: _font(13, FontWeight.w600, _textMain),
                    cursorColor: _textMain,
                    cursorWidth: 1.5,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: _font(12, FontWeight.w400, _textMuted),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: _textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rp',
                              style: _font(13, FontWeight.w600, _textSub),
                            ),
                          ],
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      filled: true,
                      fillColor: _cardDark,
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
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                SizedBox(
                  height: 44,
                  child: TextField(
                    controller: descCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: _font(13, FontWeight.w500, _textMain),
                    cursorColor: _textMain,
                    cursorWidth: 1.5,
                    decoration: InputDecoration(
                      hintText: 'Keterangan (beli biji kopi, dll)',
                      hintStyle: _font(12, FontWeight.w400, _textMuted),
                      prefixIcon: const Icon(
                        Icons.edit_note_rounded,
                        color: _textMuted,
                        size: 16,
                      ),
                      filled: true,
                      fillColor: _cardDark,
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
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final cleanAmount =
                                amountCtrl.text.replaceAll('.', '');
                            final amount = double.tryParse(cleanAmount) ?? 0;
                            final desc = descCtrl.text.trim();

                            if (amount <= 0 || desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Isi nominal dan keterangan!',
                                    style: _font(
                                      12,
                                      FontWeight.w600,
                                      _textMain,
                                    ),
                                  ),
                                  backgroundColor: _cardDark,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: _expenseRed),
                                  ),
                                ),
                              );
                              return;
                            }

                            HapticFeedback.lightImpact();
                            setModalState(() => isLoading = true);
                            final record = FinanceRecord(
                              type: selectedType,
                              amount: amount,
                              description: desc,
                            );
                            final financeProv = context.read<FinanceProvider>();
                            final txnProv = context.read<TransactionProvider>();
                            await financeProv.addRecord(record);

                            // REAL-TIME SYNC: Refresh data dashboard
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              txnProv.loadDailySummary();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _textMain,
                      foregroundColor: _bgDark,
                      disabledBackgroundColor: _cardDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
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
                              const Icon(
                                Icons.save_outlined,
                                size: 16,
                                color: _bgDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Simpan Catatan',
                                style: _font(13, FontWeight.w700, _bgDark),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.12) : _cardDark,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.06),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.45)
                  : _borderDark,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? color : _textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: _font(
                  12,
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                  isSelected ? color : _textSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete Confirmation ────────────────────────────────────────────────────
  void _confirmDelete(
    BuildContext context,
    FinanceRecord record,
    FinanceProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderDark),
        ),
        title: Text(
          'Hapus Catatan?',
          style: _font(14, FontWeight.w700, _textMain),
        ),
        content: Text(
          '"${record.description}" akan dihapus.',
          style: _font(12, FontWeight.w400, _textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: _font(12, FontWeight.w600, _textSub)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteRecord(record.id);
            },
            child: Text(
              'Hapus',
              style: _font(12, FontWeight.w700, _expenseRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final clean = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return const TextEditingValue();

    final value = double.parse(clean);
    final formatter =
        NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
    final newText = formatter.format(value).trim();

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
