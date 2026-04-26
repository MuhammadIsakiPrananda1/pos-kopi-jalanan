class AppConstants {
  AppConstants._();

  static const String appName = 'KOPI JALANAN GANK';
  static const String appTagline = 'Kasir Digital Kopi Jalanan';
  static const String appVersion = '1.0.0';
  static const String developer = 'NEVERLAND STUDIO';

  // Receipt strings
  static const String receiptHeader = 'KOPI JALANAN GANK';
  static const String receiptFooter = 'Terima kasih sudah membeli!';
  static const String receiptDivider = '================================';

  // Categories default
  static const List<String> defaultCategories = [
    'Semua',
    'Kopi',
    'Non Kopi',
    'Makanan',
    'Minuman Lain',
  ];

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  // Animation duration
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
