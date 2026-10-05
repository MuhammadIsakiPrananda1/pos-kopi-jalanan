import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _bgDark      = Color(0xFF09090B);
const _surfaceDark = Color(0xFF141417);
const _cardDark    = Color(0xFF18181B);
const _borderDark  = Color(0xFF27272A);
const _textMuted   = Color(0xFF71717A);
const _textSub     = Color(0xFFA1A1AA);
const _textMain    = Color(0xFFFAFAFA);
const _redError    = Color(0xFFEF4444);
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _font(double size, FontWeight weight, Color color, {double letterSpacing = 0}) =>
    GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController(text: 'admin123');
  bool _obscurePassword = true;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.admin;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
      if (role == UserRole.admin) {
        _usernameCtrl.text = 'admin';
        _passwordCtrl.text = 'admin123';
      } else {
        _usernameCtrl.text = 'karyawan';
        _passwordCtrl.text = '1234';
      }
    });
  }

  Future<void> _submitLogin() async {
    setState(() => _errorMessage = null);
    final auth = context.read<AuthProvider>();

    final success = await auth.login(_usernameCtrl.text, _passwordCtrl.text);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Username atau Password salah untuk role yang dipilih.';
      });
    }
  }

  void _quickLogin(UserRole role) {
    context.read<AuthProvider>().loginAs(role);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Logo & Header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _surfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: _borderDark, width: 1.5),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/images/logo_mark.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront_rounded,
                              size: 32,
                              color: _textMain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: _font(18, FontWeight.w800, _textMain, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masuk untuk mengakses sistem kasir & kelola toko',
                    textAlign: TextAlign.center,
                    style: _font(12, FontWeight.w400, _textSub),
                  ),
                  const SizedBox(height: 28),

                  // Role Selector Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderDark),
                    ),
                    child: Row(
                      children: [
                        _buildRoleTab(
                          title: 'Admin / Pemilik',
                          icon: Icons.admin_panel_settings_outlined,
                          role: UserRole.admin,
                        ),
                        _buildRoleTab(
                          title: 'Karyawan / Kasir',
                          icon: Icons.badge_outlined,
                          role: UserRole.karyawan,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role Description Hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _borderDark),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: _textSub),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedRole == UserRole.admin
                                ? 'Akses Admin: Kelola stok barang, restock, pantau omzet, catatan keuangan & laporan.'
                                : 'Akses Karyawan: Khusus transaksi penjualan kasir (POS), keranjang, & cetak struk.',
                            style: _font(11, FontWeight.w400, _textSub),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Inputs
                  Text('Username', style: _font(11.5, FontWeight.w600, _textSub)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _usernameCtrl,
                      style: _font(13, FontWeight.w500, _textMain),
                      cursorColor: _textMain,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: _textMuted),
                        hintText: 'Masukkan username',
                        hintStyle: _font(12, FontWeight.w400, _textMuted),
                        filled: true,
                        fillColor: _surfaceDark,
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
                  const SizedBox(height: 14),

                  Text('Password / PIN', style: _font(11.5, FontWeight.w600, _textSub)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      style: _font(13, FontWeight.w500, _textMain),
                      cursorColor: _textMain,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: _textMuted),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 16,
                            color: _textMuted,
                          ),
                        ),
                        hintText: 'Masukkan password',
                        hintStyle: _font(12, FontWeight.w400, _textMuted),
                        filled: true,
                        fillColor: _surfaceDark,
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

                  // Error Banner
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _redError.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _redError.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: _redError, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: _font(11.5, FontWeight.w500, _redError),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _textMain,
                        foregroundColor: _bgDark,
                        disabledBackgroundColor: _cardDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _bgDark),
                            )
                          : Text(
                              'Masuk ke Sistem',
                              style: _font(13, FontWeight.w700, _bgDark),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1, color: _borderDark),
                  const SizedBox(height: 20),

                  // Quick 1-Tap Login Chips
                  Text(
                    'Masuk Cepat (Akses Langsung):',
                    textAlign: TextAlign.center,
                    style: _font(11, FontWeight.w500, _textMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _quickLogin(UserRole.admin),
                          icon: const Icon(Icons.admin_panel_settings_outlined, size: 14),
                          label: Text('Admin', style: _font(11.5, FontWeight.w600, _textMain)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textMain,
                            side: const BorderSide(color: _borderDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _quickLogin(UserRole.karyawan),
                          icon: const Icon(Icons.badge_outlined, size: 14),
                          label: Text('Karyawan', style: _font(11.5, FontWeight.w600, _textMain)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textMain,
                            side: const BorderSide(color: _borderDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab({
    required String title,
    required IconData icon,
    required UserRole role,
  }) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleChanged(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _cardDark : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected ? _borderDark : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? _textMain : _textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: _font(
                  11.5,
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                  isSelected ? _textMain : _textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
