import 'package:flutter/material.dart';

/// The visual system for QuickDrop.
///
/// Paper-white surfaces, ink typography and a single emerald accent. The
/// interface should read like a quiet desktop utility, not a landing page.
class QuickDropColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundWarm = Color(0xFFFBF8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF047857);
  static const Color emeraldDeep = Color(0xFF065F46);
  static const Color emeraldSoft = Color(0xFFECFDF5);
  static const Color emeraldBorder = Color(0xFFA7F3D0);

  static const Color onyx = Color(0xFF0F172A);
  static const Color textPrimary = onyx;
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textFaint = Color(0xFF94A3B8);

  static const Color rose = Color(0xFFDC2626);
  static const Color roseDark = Color(0xFFB91C1C);
  static const Color roseSoft = Color(0xFFFEF2F2);
  static const Color roseBorder = Color(0xFFFECACA);

  static const Color amber = Color(0xFFB45309);
  static const Color amberSoft = Color(0xFFFFFBEB);
  static const Color amberBorder = Color(0xFFFDE68A);

  static const Color blue = Color(0xFF2563EB);
  static const Color blueSoft = Color(0xFFEFF6FF);
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetSoft = Color(0xFFF5F3FF);

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get raisedShadow => const [
        BoxShadow(
          color: Color(0x140F172A),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ];
}

class QuickDropText {
  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: QuickDropColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: QuickDropColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: QuickDropColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: QuickDropColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13.5,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: QuickDropColors.textSecondary,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: QuickDropColors.textMuted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: QuickDropColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontFamily: 'monospace',
    color: QuickDropColors.textSecondary,
  );
}

class QuickDropTheme {
  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: QuickDropColors.emerald,
      onPrimary: Colors.white,
      primaryContainer: QuickDropColors.emeraldSoft,
      onPrimaryContainer: QuickDropColors.emeraldDeep,
      secondary: QuickDropColors.onyx,
      onSecondary: Colors.white,
      secondaryContainer: QuickDropColors.surfaceSubtle,
      onSecondaryContainer: QuickDropColors.onyx,
      tertiary: QuickDropColors.emeraldDark,
      onTertiary: Colors.white,
      surface: QuickDropColors.surface,
      onSurface: QuickDropColors.textPrimary,
      error: QuickDropColors.rose,
      onError: Colors.white,
      errorContainer: QuickDropColors.roseSoft,
      onErrorContainer: QuickDropColors.roseDark,
      outline: QuickDropColors.border,
      outlineVariant: QuickDropColors.surfaceSubtle,
      surfaceContainerLowest: QuickDropColors.surface,
      surfaceContainerLow: QuickDropColors.surfaceMuted,
      surfaceContainer: QuickDropColors.surfaceSubtle,
      surfaceContainerHigh: Color(0xFFE8EDF3),
      surfaceContainerHighest: Color(0xFFE2E8F0),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: QuickDropColors.background,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: const TextTheme(
        headlineLarge: QuickDropText.display,
        headlineMedium: QuickDropText.headline,
        headlineSmall: QuickDropText.title,
        titleLarge: QuickDropText.title,
        titleMedium: QuickDropText.cardTitle,
        titleSmall: TextStyle(
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: QuickDropColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: QuickDropColors.textPrimary,
        ),
        bodyMedium: QuickDropText.body,
        bodySmall: QuickDropText.small,
        labelLarge: QuickDropText.button,
        labelMedium: TextStyle(
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: QuickDropColors.textSecondary,
        ),
        labelSmall: QuickDropText.label,
      ),
      cardTheme: CardThemeData(
        color: QuickDropColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: QuickDropColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: QuickDropColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: QuickDropColors.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: QuickDropColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        shadowColor: const Color(0x260F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: QuickDropColors.border),
        ),
        titleTextStyle: QuickDropText.title,
        contentTextStyle: QuickDropText.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: QuickDropColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: QuickDropColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: QuickDropColors.onyx,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: QuickDropColors.emeraldBorder,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        elevation: 6,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: QuickDropColors.emerald,
          foregroundColor: Colors.white,
          disabledBackgroundColor: QuickDropColors.surfaceSubtle,
          disabledForegroundColor: QuickDropColors.textFaint,
          textStyle: QuickDropText.button,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: QuickDropColors.surface,
          foregroundColor: QuickDropColors.textPrimary,
          side: const BorderSide(color: QuickDropColors.border),
          textStyle: QuickDropText.button,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QuickDropColors.emeraldDark,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: QuickDropColors.textSecondary,
          highlightColor: QuickDropColors.surfaceSubtle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QuickDropColors.surfaceMuted,
        hintStyle: const TextStyle(
          color: QuickDropColors.textFaint,
          fontSize: 13.5,
        ),
        labelStyle: const TextStyle(
          color: QuickDropColors.textSecondary,
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          color: QuickDropColors.emeraldDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: QuickDropColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: QuickDropColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: QuickDropColors.emerald,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: QuickDropColors.rose),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: QuickDropColors.rose,
            width: 1.4,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: QuickDropColors.surfaceSubtle,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: QuickDropColors.emerald,
        linearTrackColor: QuickDropColors.surfaceSubtle,
        circularTrackColor: QuickDropColors.surfaceSubtle,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return QuickDropColors.emerald;
          }
          return QuickDropColors.borderStrong;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: QuickDropColors.onyx,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 450),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: QuickDropColors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: const TextStyle(
          color: QuickDropColors.textPrimary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: QuickDropColors.border),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          QuickDropColors.borderStrong,
        ),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(8),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: QuickDropColors.emeraldDark,
        selectionColor: QuickDropColors.emerald.withValues(alpha: 0.22),
        selectionHandleColor: QuickDropColors.emeraldDark,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Backwards-compatible name while the app migrates to the light theme.
  static ThemeData get darkTheme => lightTheme;
}
