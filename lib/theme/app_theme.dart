import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF2D6BFF);
  static const Color primarySoft = Color(0xFFEAF0FF);

  // Success ("เขาติดเรา" — ยอดที่จะได้รับคืน)
  static const Color success = Color(0xFF0FBF7F);
  static const Color successSoft = Color(0xFFE4F8F1);

  // Warn ("เราติดเขา" — ใช้สีส้ม ไม่ใช้สีแดง)
  static const Color warn = Color(0xFFFF8A3D);
  static const Color warnSoft = Color(0xFFFFF1E7);

  // Danger (เฉพาะการลบ/ยกเลิกเท่านั้น)
  static const Color danger = Color(0xFFE5484D);

  // Ink
  static const Color ink = Color(0xFF0F1729);
  static const Color ink2 = Color(0xFF4B5563);
  static const Color ink3 = Color(0xFF9AA3B2);

  // Background & Surfaces
  static const Color bg = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFEDF0F5);

  // Dark Mode Tokens
  static const Color darkBg = Color(0xFF0B0F1A);
  static const Color darkCard = Color(0xFF151A26);
  static const Color darkLine = Color(0xFF232A3A);
  static const Color darkInk = Color(0xFFF9FAFB);
  static const Color darkInk2 = Color(0xFF9CA3AF);
}

class AppRadius {
  static const double sm = 10.0;
  static const double md = 16.0;
  static const double lg = 22.0;
  static const double xl = 28.0;

  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.ink),
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
