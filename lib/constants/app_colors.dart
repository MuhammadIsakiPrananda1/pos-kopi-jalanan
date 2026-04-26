import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background layers
  static const Color background = Color(0xFF111111);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color surfaceHigh = Color(0xFF333333);

  // Brand colors
  static const Color primary = Color(0xFF1A1A1A);
  static const Color secondary = Color(0xFF6B3A2A); // Coklat kopi
  static const Color accent = Color(0xFFD4A76A);    // Kopi susu / gold
  static const Color accentDark = Color(0xFFB8863A); // Aksen gelap

  // Text colors
  static const Color textPrimary = Color(0xFFF5F0E8);   // Putih gading
  static const Color textSecondary = Color(0xFF9E9E9E); // Abu-abu
  static const Color textHint = Color(0xFF616161);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF42A5F5);

  // UI elements
  static const Color divider = Color(0xFF2E2E2E);
  static const Color iconColor = Color(0xFFBDBDBD);
  static const Color shimmer = Color(0xFF252525);

  // Income / Expense
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFEF5350);

  // Gradient
  static const LinearGradient coffeeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B3A2A), Color(0xFF3E1F10)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A76A), Color(0xFF8B5E3C)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF111111)],
  );
}
