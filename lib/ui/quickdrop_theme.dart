import 'package:flutter/material.dart';

class QuickDropColors {
  static const Color background = Color(0xFF090D14);
  static const Color surface = Color(0xFF131823);
  static const Color surfaceLight = Color(0xFF1C2333);
  static const Color border = Color(0xFF263147);
  
  static const Color cyan = Color(0xFF00F0FF);
  static const Color cyanGlow = Color(0x3300F0FF);
  static const Color indigo = Color(0xFF6366F1);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFF43F5E);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

class QuickDropTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: QuickDropColors.background,
      colorScheme: const ColorScheme.dark(
        primary: QuickDropColors.cyan,
        secondary: QuickDropColors.indigo,
        surface: QuickDropColors.surface,
        error: QuickDropColors.rose,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: QuickDropColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: QuickDropColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: QuickDropColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
