import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../models/finance_record.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/custom_button.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadRecords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Nested TabBar styled as Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.background,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'CATATAN'),
                  Tab(text: 'SALDO'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsTab(nf),
                _buildBalanceTab(nf),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          heroTag: 'fab_finance',
          onPressed: () => _showAddRecordDialog(context),
          backgroundColor: AppColors.accent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: AppColors.background),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildRecordsTab(NumberFormat nf) {
    return Consumer<FinanceProvider>(
      builder: (_, fin, __) {
        if (fin.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }

        if (fin.records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💰', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Belum ada catatan', style: AppTextStyles.bodyMedium),
                Text('Tambah pemasukan/pengeluaran',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => fin.loadRecords(),
          color: AppColors.accent,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            itemCount: fin.records.length,
            itemBuilder: (_, i) {
              final record = fin.records[i];
              return _buildRecordTile(context, record, fin, nf);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecordTile(
    BuildContext context,
    FinanceRecord record,
    FinanceProvider provider,
    NumberFormat nf,
  ) {
    final isIncome = record.isIncome;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final df = DateFormat('dd MMM yyyy, HH:mm', 'id');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: color,
            size: 22,
          ),
        ),
        title: Text(record.description, style: AppTextStyles.titleMedium),
        subtitle: Text(
          df.format(record.createdAt),
          style: AppTextStyles.caption,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${nf.format(record.amount)}',
              style: AppTextStyles.price.copyWith(
                  color: color, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: Text(
                isIncome ? 'Pemasukan' : 'Pengeluaran',
                style: AppTextStyles.caption.copyWith(color: color),
              ),
            ),
          ],
        ),
        onLongPress: () => _confirmDelete(context, record, provider),
      ),
    );
  }

  Widget _buildBalanceTab(NumberFormat nf) {
    return Consumer<FinanceProvider>(
      builder: (_, fin, __) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            children: [
              // Balance card Premium
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text('SALDO SAAT INI',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.background.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        nf.format(fin.balance),
                        style: AppTextStyles.priceLarge.copyWith(
                          color: AppColors.background,
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Income / Expense split
              Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      label: 'Total Pemasukan',
                      value: nf.format(fin.totalIncome),
                      icon: Icons.arrow_downward_rounded,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BalanceCard(
                      label: 'Total Pengeluaran',
                      value: nf.format(fin.totalExpense),
                      icon: Icons.arrow_upward_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _showAddRecordDialog(BuildContext context) {
    FinanceType selectedType = FinanceType.income;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Tambah Catatan', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),

              // Type selector
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(
                          () => selectedType = FinanceType.income),
                      child: AnimatedContainer(
                        duration: AppConstants.animFast,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedType == FinanceType.income
                              ? AppColors.income.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
                          border: Border.all(
                            color: selectedType == FinanceType.income
                                ? AppColors.income
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          '+ Pemasukan',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: selectedType == FinanceType.income
                                ? AppColors.income
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(
                          () => selectedType = FinanceType.expense),
                      child: AnimatedContainer(
                        duration: AppConstants.animFast,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedType == FinanceType.expense
                              ? AppColors.expense.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
                          border: Border.all(
                            color: selectedType == FinanceType.expense
                                ? AppColors.expense
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          '- Pengeluaran',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: selectedType == FinanceType.expense
                                ? AppColors.expense
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Amount
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CurrencyInputFormatter(),
                ],
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.payments_rounded,
                          color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text('Rp ',
                          style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: descCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Keterangan (Beli biji kopi, dll)',
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textHint, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                label: 'SIMPAN CATATAN',
                icon: Icons.save_rounded,
                isLoading: isLoading,
                onPressed: () async {
                  final cleanAmount = amountCtrl.text.replaceAll('.', '');
                  final amount = double.tryParse(cleanAmount) ?? 0;
                  final desc = descCtrl.text.trim();

                  if (amount <= 0 || desc.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Isi nominal dan keterangan!'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  setModalState(() => isLoading = true);
                  final record = FinanceRecord(
                    type: selectedType,
                    amount: amount,
                    description: desc,
                  );
                  await context.read<FinanceProvider>().addRecord(record);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, FinanceRecord record, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL)),
        title: Text('Hapus Catatan?', style: AppTextStyles.headlineMedium),
        content: Text(
          '"${record.description}" akan dihapus.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteRecord(record.id);
            },
            child:
                const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BalanceCard({
    required this.label,
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
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold),
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
    if (newValue.text.isEmpty) return newValue;

    final double value = double.parse(newValue.text.replaceAll('.', ''));
    final formatter =
        NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
    final String newText = formatter.format(value).trim();

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
