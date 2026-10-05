import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../home/home_screen.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
const _bgDark      = Color(0xFF09090B);
const _surfaceDark = Color(0xFF141417);
const _borderDark  = Color(0xFF27272A);
const _borderSubtle= Color(0xFF1F1F23);
const _textMuted   = Color(0xFF71717A);
const _textSub     = Color(0xFFA1A1AA);
const _textMain    = Color(0xFFFAFAFA);
const _stockGreen  = Color(0xFF22C55E);
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _font(double size, FontWeight weight, Color color, {double letterSpacing = 0}) =>
    GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Satu animasi sekali jalan (one-shot): setelah selesai controller berhenti
  // total — tidak ada repaint berkelanjutan, ringan untuk sistem.
  late final AnimationController _ctrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _footerFade;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Staggered: logo → judul → tagline → footer (satu controller, tanpa loop)
    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
    );
    _taglineFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOut),
    );
    _footerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
    );
    _progress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
    );

    _ctrl.forward();
    _startApp();
  }

  Future<void> _startApp() async {
    await Future.delayed(const Duration(milliseconds: 1750));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Konten utama: presisi di tengah layar ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _buildLogo(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: _font(
                        19,
                        FontWeight.w800,
                        _textMain,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: _font(
                        11.5,
                        FontWeight.w500,
                        _textSub,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer: progress tipis + versi ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: FadeTransition(
                opacity: _footerFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (_, __) => LinearProgressIndicator(
                            value: _progress.value,
                            minHeight: 2.5,
                            backgroundColor: _borderSubtle,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _textMain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'v${AppConstants.appVersion}  •  ${AppConstants.developer}',
                      style: _font(
                        9.5,
                        FontWeight.w500,
                        _textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo: emblem emas + titik status hijau (konsisten dengan header tab) ──
  Widget _buildLogo() {
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              color: _surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: _borderDark, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/logo_mark.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_cafe_outlined,
                    size: 34,
                    color: _textMain,
                  ),
                ),
              ),
            ),
          ),
          // Titik status hijau
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _stockGreen,
                shape: BoxShape.circle,
                border: Border.all(color: _bgDark, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
