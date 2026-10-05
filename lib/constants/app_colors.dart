import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background layers (Monochrome Black & Dark Zinc)
  static const Color background = Color(0xFF09090B);
  static const Color surface = Color(0xFF141417);
  static const Color surfaceLight = Color(0xFF1F1F23);
  static const Color surfaceHigh = Color(0xFF27272A);

  // Brand colors (Black & White Minimalist)
  static const Color primary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFA1A1AA);
  static const Color accent = Color(0xFFFFFFFF);    // Pure White Accent
  static const Color accentDark = Color(0xFFE4E4E7); // Off-white / Zinc 200

  // Text colors
  static const Color textPrimary = Color(0xFFFAFAFA);   // Pure White text
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color textHint = Color(0xFF71717A);      // Zinc 500

  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // UI elements
  static const Color divider = Color(0xFF27272A);
  static const Color iconColor = Color(0xFFD4D4D8);
  static const Color shimmer = Color(0xFF18181B);

  // Income / Expense
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient coffeeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF27272A), Color(0xFF09090B)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFE4E4E7)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF18181B), Color(0xFF09090B)],
  );
}

