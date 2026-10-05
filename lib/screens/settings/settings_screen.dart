import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/finance_provider.dart';
import 'printer_settings_screen.dart';

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
const _redError    = Color(0xFFEF4444);
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _font(double size, FontWeight weight, Color color, {double letterSpacing = 0}) =>
    GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // STORE PROFILE
                  _buildSectionHeader('Profil Toko'),
                  const SizedBox(height: 8),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      Icons.storefront_outlined,
                      'Nama Toko',
                      settings.storeName.isEmpty ? 'Belum diatur' : settings.storeName,
                      onTap: () => _showEditDialog('Nama Toko', settings.storeName,
                          (v) => settings.updateStoreName(v)),
                    ),
                    _buildSettingsTile(
                      Icons.location_on_outlined,
                      'Alamat',
                      settings.storeAddress.isEmpty ? 'Belum diatur' : settings.storeAddress,
                      onTap: () => _showEditDialog('Alamat', settings.storeAddress,
                          (v) => settings.updateStoreAddress(v)),
                    ),
                    _buildSettingsTile(
                      Icons.phone_outlined,
                      'No. Telepon',
                      settings.storePhone.isEmpty ? 'Belum diatur' : settings.storePhone,
                      onTap: () => _showEditDialog('No. Telepon', settings.storePhone,
                          (v) => settings.updateStorePhone(v)),
                    ),
                    _buildSettingsTile(
                      Icons.tag_rounded,
                      'Slogan',
                      settings.storeSlogan.isEmpty ? 'Belum diatur' : settings.storeSlogan,
                      onTap: () => _showEditDialog('Slogan', settings.storeSlogan,
                          (v) => settings.updateStoreSlogan(v)),
                    ),
                  ]),

                  const SizedBox(height: 22),

                  // RECEIPT SETTINGS
                  _buildSectionHeader('Struk Belanja'),
                  const SizedBox(height: 8),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      Icons.print_outlined,
                      'Hubungkan Printer',
                      'Sambungkan printer bluetooth',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrinterSettingsScreen(),
                        ),
                      ),
                    ),
                    _buildSettingsTile(
                      Icons.title_rounded,
                      'Header Struk',
                      settings.receiptHeader.isEmpty ? 'Belum diatur' : settings.receiptHeader,
                      onTap: () => _showEditDialog('Header Struk', settings.receiptHeader,
                          (v) => settings.updateReceiptHeader(v)),
                    ),
                    _buildSettingsTile(
                      Icons.subtitles_outlined,
                      'Footer Struk',
                      settings.receiptFooter.isEmpty ? 'Belum diatur' : settings.receiptFooter,
                      onTap: () => _showEditDialog('Footer Struk', settings.receiptFooter,
                          (v) => settings.updateReceiptFooter(v)),
                    ),
                    _buildSettingsTile(
                      Icons.straighten_rounded,
                      'Ukuran Kertas',
                      settings.paperSize,
                      onTap: () => _showPaperSizeDialog(settings),
                    ),
                  ]),

                  const SizedBox(height: 22),

                  // DATA MANAGEMENT
                  _buildSectionHeader('Data & Keamanan'),
                  const SizedBox(height: 8),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      Icons.history_rounded,
                      'Hapus Riwayat Transaksi',
                      'Bersihkan data laporan',
                      isDanger: true,
                      onTap: () => _showConfirmAction(
                        'Hapus Riwayat?',
                        'Semua data transaksi akan dihapus permanen.',
                        () async {
                          final txnProv = context.read<TransactionProvider>();
                          final finProv = context.read<FinanceProvider>();
                          await txnProv.clearHistory();
                          finProv.loadRecords();
                        },
                      ),
                    ),
                    _buildSettingsTile(
                      Icons.inventory_2_outlined,
                      'Hapus Semua Produk',
                      'Bersihkan data stok',
                      isDanger: true,
                      onTap: () => _showConfirmAction(
                        'Hapus Produk?',
                        'Semua data produk akan dihapus permanen.',
                        () async {
                          await context.read<ProductProvider>().clearProducts();
                        },
                      ),
                    ),
                    _buildSettingsTile(
                      Icons.restart_alt_rounded,
                      'Reset Aplikasi',
                      'Kembali ke pengaturan awal',
                      isDanger: true,
                      onTap: () => _showConfirmAction(
                        'Reset Aplikasi?',
                        'Aplikasi akan kembali ke kondisi awal. Semua data akan hilang.',
                        () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Aplikasi telah di-reset.',
                                style: _font(12, FontWeight.w600, _bgDark),
                              ),
                              backgroundColor: _textMain,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 22),

                  // ABOUT
                  _buildSectionHeader('Lainnya'),
                  const SizedBox(height: 8),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      Icons.help_outline_rounded,
                      'Bantuan & Dukungan',
                      'Hubungi teknisi',
                      onTap: () => _showHelpSupport(context),
                    ),
                    _buildSettingsTile(
                      Icons.policy_outlined,
                      'Kebijakan Privasi',
                      'Baca ketentuan',
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    _buildSettingsTile(
                      Icons.info_outline_rounded,
                      'Detail Aplikasi',
                      'Informasi teknis aplikasi',
                      onTap: () => _showAppDetails(context),
                    ),
                  ]),

                  const SizedBox(height: 10),

                  // Footer
                  Center(
                    child: Text(
                      'v${AppConstants.appVersion}  •  ${AppConstants.developer}',
                      style: _font(
                        9.5,
                        FontWeight.w500,
                        _textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header (konsisten dengan tab lain) ─────────────────────────────────────
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
                color: _stockGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pengaturan',
              style: _font(15, FontWeight.w700, _textMain, letterSpacing: -0.2),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Konfigurasi aplikasi kasir Anda',
            style: _font(10, FontWeight.w500, _textMuted),
          ),
        ),
      ],
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: _font(11.5, FontWeight.w600, _textSub),
      ),
    );
  }

  // ── Settings Card ──────────────────────────────────────────────────────────
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderDark, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: _borderSubtle,
                indent: 52,
              ),
          ],
        ],
      ),
    );
  }

  // ── Settings Tile ──────────────────────────────────────────────────────────
  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle, {
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    final color = isDanger ? _redError : _textMain;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        splashColor: (isDanger ? _redError : _textMain).withValues(alpha: 0.05),
        highlightColor: (isDanger ? _redError : _textMain).withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDanger
                      ? _redError.withValues(alpha: 0.1)
                      : _cardDark,
                  borderRadius: BorderRadius.circular(7),
                  border: isDanger
                      ? null
                      : Border.all(color: _borderSubtle),
                ),
                child: Icon(
                  icon,
                  color: isDanger ? _redError : _textSub,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _font(
                        12.5,
                        FontWeight.w600,
                        color,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _font(10, FontWeight.w500, _textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _textMuted.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit Dialog ────────────────────────────────────────────────────────────
  void _showEditDialog(String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderDark),
        ),
        title: Text(
          'Edit $title',
          style: _font(14, FontWeight.w700, _textMain),
        ),
        content: SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            autofocus: true,
            style: _font(13, FontWeight.w500, _textMain),
            cursorColor: _textMain,
            cursorWidth: 1.5,
            decoration: InputDecoration(
              hintText: 'Masukkan $title baru',
              hintStyle: _font(12, FontWeight.w400, _textMuted),
              filled: true,
              fillColor: _surfaceDark,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: _font(12, FontWeight.w600, _textSub)),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$title diperbarui',
                    style: _font(12, FontWeight.w600, _bgDark),
                  ),
                  backgroundColor: _textMain,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(
              'Simpan',
              style: _font(12, FontWeight.w700, _textMain),
            ),
          ),
        ],
      ),
    );
  }

  // ── Paper Size Dialog ──────────────────────────────────────────────────────
  void _showPaperSizeDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderDark),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        title: Text(
          'Ukuran Kertas',
          style: _font(14, FontWeight.w700, _textMain),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['58mm', '80mm'].map((size) {
            final isSelected = settings.paperSize == size;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? _textMain.withValues(alpha: 0.06)
                    : _surfaceDark,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settings.updatePaperSize(size);
                    Navigator.pop(ctx);
                  },
                  splashColor: _textMain.withValues(alpha: 0.06),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _textMain : _borderDark,
                        width: isSelected ? 1.2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? _textMain : _textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            size == '58mm'
                                ? '58mm (Kecil/Standar)'
                                : '80mm (Besar/Desktop)',
                            style: _font(
                              12,
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                              isSelected ? _textMain : _textSub,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Confirm Action Dialog ──────────────────────────────────────────────────
  void _showConfirmAction(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderDark),
        ),
        title: Text(
          title,
          style: _font(14, FontWeight.w700, _textMain),
        ),
        content: Text(
          message,
          style: _font(12, FontWeight.w400, _textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: _font(12, FontWeight.w600, _textSub)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onConfirm();
              Navigator.pop(ctx);
            },
            child: Text(
              'Ya, Lanjutkan',
              style: _font(12, FontWeight.w700, _redError),
            ),
          ),
        ],
      ),
    );
  }

  // ── Help & Support Sheet ───────────────────────────────────────────────────
  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSheetHeader('Bantuan & Dukungan'),
            const SizedBox(height: 16),
            _buildSupportItem(
              Icons.chat_bubble_outline_rounded,
              'WhatsApp Support',
              '+62 812-5225-4886',
            ),
            const SizedBox(height: 10),
            _buildSupportItem(
              Icons.email_outlined,
              'Email Support',
              'Arlianto032@gmail.com',
            ),
            const SizedBox(height: 20),
            _buildSheetCloseButton(ctx),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _surfaceDark,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _borderSubtle),
            ),
            child: Icon(icon, color: _textSub, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _font(10, FontWeight.w500, _textMuted)),
                const SizedBox(height: 1),
                Text(value, style: _font(12, FontWeight.w600, _textMain)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Privacy Policy Sheet ───────────────────────────────────────────────────
  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: _borderDark, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            _buildSheetHeader('Kebijakan Privasi'),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  'Kebijakan Privasi KOPI JALANAN GANK\n\n'
                  '1. Pengumpulan Data\nAplikasi ini menyimpan data transaksi dan produk secara lokal di perangkat Anda. Kami tidak mengunggah data bisnis Anda ke server luar tanpa izin.\n\n'
                  '2. Penggunaan Data\nData digunakan semata-mata untuk keperluan operasional kasir, pelaporan keuangan, dan manajemen inventaris toko Anda.\n\n'
                  '3. Keamanan\nKarena data disimpan secara lokal, Anda bertanggung jawab penuh atas keamanan perangkat Anda. Kami menyarankan untuk melakukan backup data secara rutin.\n\n'
                  '4. Perangkat Pihak Ketiga\nAplikasi ini berinteraksi dengan printer Bluetooth pihak ketiga. Kami tidak bertanggung jawab atas kegagalan hardware eksternal.\n\n'
                  '5. Perubahan Kebijakan\nKami berhak memperbarui kebijakan ini sewaktu-waktu untuk meningkatkan layanan.',
                  style: _font(
                    11.5,
                    FontWeight.w400,
                    _textSub,
                    letterSpacing: 0.1,
                  ).copyWith(height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSheetCloseButton(ctx, label: 'Saya Mengerti'),
          ],
        ),
      ),
    );
  }

  // ── App Details Sheet ──────────────────────────────────────────────────────
  void _showAppDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardDark,
                shape: BoxShape.circle,
                border: Border.all(color: _borderDark),
              ),
              child: const Icon(
                Icons.local_cafe_outlined,
                size: 28,
                color: _textMain,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppConstants.appName,
              style: _font(15, FontWeight.w800, _textMain, letterSpacing: 0.4),
            ),
            const SizedBox(height: 6),
            Text(
              'Aplikasi kasir digital yang dirancang khusus untuk mengelola operasional Gank Kopi dengan cepat, akurat, dan real-time.',
              textAlign: TextAlign.center,
              style: _font(11, FontWeight.w400, _textSub).copyWith(height: 1.5),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderDark),
              ),
              child: Text(
                'Versi ${AppConstants.appVersion}',
                style: _font(10.5, FontWeight.w600, _textSub),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.developer,
              style: _font(
                9.5,
                FontWeight.w500,
                _textMuted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 16),
            _buildSheetCloseButton(ctx),
          ],
        ),
      ),
    );
  }

  // ── Sheet helpers ──────────────────────────────────────────────────────────
  Widget _buildSheetContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: _borderDark, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: _textMuted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSheetHeader(String title) {
    return Row(
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
        Text(title, style: _font(14, FontWeight.w700, _textMain)),
      ],
    );
  }

  Widget _buildSheetCloseButton(BuildContext ctx, {String label = 'Tutup'}) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(ctx),
        style: ElevatedButton.styleFrom(
          backgroundColor: _textMain,
          foregroundColor: _bgDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: _font(12.5, FontWeight.w700, _bgDark),
        ),
      ),
    );
  }
}
