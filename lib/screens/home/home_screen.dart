import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../dashboard/dashboard_screen.dart';
import '../cashier/cashier_screen.dart';
import '../products/product_list_screen.dart';
import '../reports/reports_and_finance_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/navigation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = const [
    DashboardScreen(),
    ProductListScreen(),
    CashierScreen(),
    ReportsAndFinanceScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _screens[nav.currentIndex],
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),

          // Custom Compact Floating Nav
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildFloatingNav(nav),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNav(NavigationProvider nav) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // The Dock Background
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactNavItem(0, Icons.grid_view_rounded, 'Home', nav),
              _buildCompactNavItem(1, Icons.inventory_2_rounded, 'Produk', nav),

              // Empty space for the protruding button
              const SizedBox(width: 60),

              _buildCompactNavItem(3, Icons.analytics_rounded, 'Laporan', nav),
              _buildCompactNavItem(4, Icons.settings_rounded, 'Menu', nav),
            ],
          ),
        ),

        // The Protruding Center Button
        Positioned(
          top: -10, // Pop out upwards slightly less
          child: _buildCenterButton(nav),
        ),
      ],
    );
  }

  Widget _buildCenterButton(NavigationProvider nav) {
    final isActive = nav.currentIndex == 2;
    return GestureDetector(
      onTap: () => nav.setIndex(2),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isActive ? Colors.white : AppColors.surface,
            width: 2.5,
          ),
        ),
        child: const Icon(
          Icons.point_of_sale_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCompactNavItem(
      int index, IconData icon, String label, NavigationProvider nav) {
    final isActive = nav.currentIndex == index;
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
              color: isActive ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
