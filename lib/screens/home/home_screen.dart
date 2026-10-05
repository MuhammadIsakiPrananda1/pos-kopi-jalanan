import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/product_list_screen.dart';
import '../cashier/cashier_screen.dart';
import '../finance/finance_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/navigation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Application Screens: 0 = Dashboard, 1 = Menu & Stok, 2 = Kasir (POS), 3 = Keuangan, 4 = Pengaturan
  final List<Widget> _screens = const [
    DashboardScreen(),
    ProductListScreen(),
    CashierScreen(),
    FinanceScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final activeIndex = nav.currentIndex >= _screens.length ? 0 : nav.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      extendBody: true,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey<int>(activeIndex),
              child: _screens[activeIndex],
            ),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),

          // Floating Navigation Dock
          Positioned(
            bottom: 18,
            left: 16,
            right: 16,
            child: _buildNavigationDock(activeIndex, nav),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDock(int activeIndex, NavigationProvider nav) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141417).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: activeIndex == 0,
                nav: nav,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.inventory_2_outlined,
                label: 'Stok',
                isActive: activeIndex == 1,
                nav: nav,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.point_of_sale_rounded,
                label: 'Kasir',
                isActive: activeIndex == 2,
                nav: nav,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Keuangan',
                isActive: activeIndex == 3,
                nav: nav,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.tune_rounded,
                label: 'Pengaturan',
                isActive: activeIndex == 4,
                nav: nav,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required NavigationProvider nav,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => nav.setIndex(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF71717A),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 9.5,
                color: isActive ? Colors.white : const Color(0xFF71717A),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Container(
                width: 12,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
