import 'package:flutter/material.dart';

/// The visual system for QuickDrop.
///
/// Paper-white surfaces, ink typography and a single emerald accent. The
/// interface should read like a quiet desktop utility, not a landing page.

/// Semantic colors for one QuickDrop theme.
///
/// Every widget resolves colors from the active theme through `context.qd`.
/// The light instance preserves the 1.1.0 palette; the dark instance is tuned
/// for the same emerald identity on deep blue-black surfaces.
@immutable
class QuickDropPalette extends ThemeExtension<QuickDropPalette> {
  final Color background;
  final Color backgroundWarm;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;

  final Color emerald;
  final Color emeraldDark;
  final Color emeraldDeep;
  final Color emeraldSoft;
  final Color emeraldBorder;

  final Color onyx;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;

  final Color rose;
  final Color roseDark;
  final Color roseSoft;
  final Color roseBorder;
  final Color amber;
  final Color amberSoft;
  final Color amberBorder;
  final Color blue;
  final Color blueSoft;
  final Color violet;
  final Color violetSoft;

  /// Text and icons drawn on top of [emerald] or [rose].
  final Color onAccent;

  final Color shadowSoft;
  final Color shadowRaised;

  const QuickDropPalette({
    required this.background,
    required this.backgroundWarm,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.emerald,
    required this.emeraldDark,
    required this.emeraldDeep,
    required this.emeraldSoft,
    required this.emeraldBorder,
    required this.onyx,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.rose,
    required this.roseDark,
    required this.roseSoft,
    required this.roseBorder,
    required this.amber,
    required this.amberSoft,
    required this.amberBorder,
    required this.blue,
    required this.blueSoft,
    required this.violet,
    required this.violetSoft,
    required this.onAccent,
    required this.shadowSoft,
    required this.shadowRaised,
  });

  static const light = QuickDropPalette(
    background: Color(0xFFF8FAFC),
    backgroundWarm: Color(0xFFFBF8FF),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF1F5F9),
    surfaceMuted: Color(0xFFF8FAFC),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    emerald: Color(0xFF10B981),
    emeraldDark: Color(0xFF047857),
    emeraldDeep: Color(0xFF065F46),
    emeraldSoft: Color(0xFFECFDF5),
    emeraldBorder: Color(0xFFA7F3D0),
    onyx: Color(0xFF0F172A),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    rose: Color(0xFFDC2626),
    roseDark: Color(0xFFB91C1C),
    roseSoft: Color(0xFFFEF2F2),
    roseBorder: Color(0xFFFECACA),
    amber: Color(0xFFB45309),
    amberSoft: Color(0xFFFFFBEB),
    amberBorder: Color(0xFFFDE68A),
    blue: Color(0xFF2563EB),
    blueSoft: Color(0xFFEFF6FF),
    violet: Color(0xFF7C3AED),
    violetSoft: Color(0xFFF5F3FF),
    onAccent: Color(0xFFFFFFFF),
    shadowSoft: Color(0x0A0F172A),
    shadowRaised: Color(0x140F172A),
  );

  static const dark = QuickDropPalette(
    background: Color(0xFF0B1220),
    backgroundWarm: Color(0xFF0D1526),
    surface: Color(0xFF111A2B),
    surfaceSubtle: Color(0xFF16213A),
    surfaceMuted: Color(0xFF0E1626),
    border: Color(0xFF24324A),
    borderStrong: Color(0xFF33445F),
    emerald: Color(0xFF34D399),
    emeraldDark: Color(0xFF6EE7B7),
    emeraldDeep: Color(0xFFA7F3D0),
    emeraldSoft: Color(0xFF0F2A22),
    emeraldBorder: Color(0xFF1E5C49),
    onyx: Color(0xFF1E293B),
    textPrimary: Color(0xFFE6EEF9),
    textSecondary: Color(0xFFA9B8CC),
    textMuted: Color(0xFF8294AC),
    textFaint: Color(0xFF5F7189),
    rose: Color(0xFFF87171),
    roseDark: Color(0xFFFCA5A5),
    roseSoft: Color(0xFF2A1215),
    roseBorder: Color(0xFF5B2329),
    amber: Color(0xFFFBBF24),
    amberSoft: Color(0xFF2A2110),
    amberBorder: Color(0xFF5A4718),
    blue: Color(0xFF60A5FA),
    blueSoft: Color(0xFF10203A),
    violet: Color(0xFFA78BFA),
    violetSoft: Color(0xFF1E1633),
    onAccent: Color(0xFF051A12),
    shadowSoft: Color(0x66000000),
    shadowRaised: Color(0xA6000000),
  );

  List<BoxShadow> get cardShadow => [
    BoxShadow(color: shadowSoft, blurRadius: 2, offset: const Offset(0, 1)),
  ];

  List<BoxShadow> get raisedShadow => [
    BoxShadow(color: shadowRaised, blurRadius: 24, offset: const Offset(0, 10)),
  ];

  @override
  QuickDropPalette copyWith({
    Color? background,
    Color? backgroundWarm,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceMuted,
    Color? border,
    Color? borderStrong,
    Color? emerald,
    Color? emeraldDark,
    Color? emeraldDeep,
    Color? emeraldSoft,
    Color? emeraldBorder,
    Color? onyx,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
    Color? rose,
    Color? roseDark,
    Color? roseSoft,
    Color? roseBorder,
    Color? amber,
    Color? amberSoft,
    Color? amberBorder,
    Color? blue,
    Color? blueSoft,
    Color? violet,
    Color? violetSoft,
    Color? onAccent,
    Color? shadowSoft,
    Color? shadowRaised,
  }) {
    return QuickDropPalette(
      background: background ?? this.background,
      backgroundWarm: backgroundWarm ?? this.backgroundWarm,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      emerald: emerald ?? this.emerald,
      emeraldDark: emeraldDark ?? this.emeraldDark,
      emeraldDeep: emeraldDeep ?? this.emeraldDeep,
      emeraldSoft: emeraldSoft ?? this.emeraldSoft,
      emeraldBorder: emeraldBorder ?? this.emeraldBorder,
      onyx: onyx ?? this.onyx,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      rose: rose ?? this.rose,
      roseDark: roseDark ?? this.roseDark,
      roseSoft: roseSoft ?? this.roseSoft,
      roseBorder: roseBorder ?? this.roseBorder,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      amberBorder: amberBorder ?? this.amberBorder,
      blue: blue ?? this.blue,
      blueSoft: blueSoft ?? this.blueSoft,
      violet: violet ?? this.violet,
      violetSoft: violetSoft ?? this.violetSoft,
      onAccent: onAccent ?? this.onAccent,
      shadowSoft: shadowSoft ?? this.shadowSoft,
      shadowRaised: shadowRaised ?? this.shadowRaised,
    );
  }

  @override
  QuickDropPalette lerp(
    covariant ThemeExtension<QuickDropPalette>? other,
    double t,
  ) {
    if (other is! QuickDropPalette) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return QuickDropPalette(
      background: blend(background, other.background),
      backgroundWarm: blend(backgroundWarm, other.backgroundWarm),
      surface: blend(surface, other.surface),
      surfaceSubtle: blend(surfaceSubtle, other.surfaceSubtle),
      surfaceMuted: blend(surfaceMuted, other.surfaceMuted),
      border: blend(border, other.border),
      borderStrong: blend(borderStrong, other.borderStrong),
      emerald: blend(emerald, other.emerald),
      emeraldDark: blend(emeraldDark, other.emeraldDark),
      emeraldDeep: blend(emeraldDeep, other.emeraldDeep),
      emeraldSoft: blend(emeraldSoft, other.emeraldSoft),
      emeraldBorder: blend(emeraldBorder, other.emeraldBorder),
      onyx: blend(onyx, other.onyx),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      textMuted: blend(textMuted, other.textMuted),
      textFaint: blend(textFaint, other.textFaint),
      rose: blend(rose, other.rose),
      roseDark: blend(roseDark, other.roseDark),
      roseSoft: blend(roseSoft, other.roseSoft),
      roseBorder: blend(roseBorder, other.roseBorder),
      amber: blend(amber, other.amber),
      amberSoft: blend(amberSoft, other.amberSoft),
      amberBorder: blend(amberBorder, other.amberBorder),
      blue: blend(blue, other.blue),
      blueSoft: blend(blueSoft, other.blueSoft),
      violet: blend(violet, other.violet),
      violetSoft: blend(violetSoft, other.violetSoft),
      onAccent: blend(onAccent, other.onAccent),
      shadowSoft: blend(shadowSoft, other.shadowSoft),
      shadowRaised: blend(shadowRaised, other.shadowRaised),
    );
  }
}

extension QuickDropUi on BuildContext {
  QuickDropPalette get qd =>
      Theme.of(this).extension<QuickDropPalette>() ?? QuickDropPalette.light;

  TextTheme get text => Theme.of(this).textTheme;

  TextStyle get mono => text.bodySmall!.copyWith(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.4,
    color: text.bodyMedium?.color,
  );
}

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
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> get raisedShadow => const [
    BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 10)),
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
  static ThemeData get light =>
      _build(QuickDropPalette.light, Brightness.light);

  static ThemeData get dark => _build(QuickDropPalette.dark, Brightness.dark);

  static ThemeData _build(QuickDropPalette p, Brightness brightness) {
    final scheme = brightness == Brightness.light
        ? ColorScheme.light(
            primary: p.emerald,
            onPrimary: p.onAccent,
            primaryContainer: p.emeraldSoft,
            onPrimaryContainer: p.emeraldDeep,
            secondary: p.onyx,
            onSecondary: p.onAccent,
            secondaryContainer: p.surfaceSubtle,
            onSecondaryContainer: p.textPrimary,
            tertiary: p.emeraldDark,
            onTertiary: p.onAccent,
            surface: p.surface,
            onSurface: p.textPrimary,
            error: p.rose,
            onError: p.onAccent,
            errorContainer: p.roseSoft,
            onErrorContainer: p.roseDark,
            outline: p.border,
            outlineVariant: p.surfaceSubtle,
            surfaceContainerLowest: p.surface,
            surfaceContainerLow: p.surfaceMuted,
            surfaceContainer: p.surfaceSubtle,
            surfaceContainerHigh: p.surfaceSubtle,
            surfaceContainerHighest: p.border,
          )
        : ColorScheme.dark(
            primary: p.emerald,
            onPrimary: p.onAccent,
            primaryContainer: p.emeraldSoft,
            onPrimaryContainer: p.emeraldDeep,
            secondary: p.onyx,
            onSecondary: p.textPrimary,
            secondaryContainer: p.surfaceSubtle,
            onSecondaryContainer: p.textPrimary,
            tertiary: p.emeraldDark,
            onTertiary: p.onAccent,
            surface: p.surface,
            onSurface: p.textPrimary,
            error: p.rose,
            onError: p.onAccent,
            errorContainer: p.roseSoft,
            onErrorContainer: p.roseDark,
            outline: p.border,
            outlineVariant: p.surfaceSubtle,
            surfaceContainerLowest: p.surface,
            surfaceContainerLow: p.surfaceMuted,
            surfaceContainer: p.surfaceSubtle,
            surfaceContainerHigh: p.surfaceSubtle,
            surfaceContainerHighest: p.border,
          );

    final textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: p.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: p.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: p.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: p.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: p.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 14, height: 1.55, color: p.textPrimary),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: p.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: p.textMuted,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: p.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: p.textMuted,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      extensions: [p],
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: p.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        shadowColor: p.shadowRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.onyx,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: brightness == Brightness.light
            ? p.emeraldBorder
            : p.emeraldDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        elevation: 6,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.emerald,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.surfaceSubtle,
          disabledForegroundColor: p.textFaint,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.emeraldDark,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textSecondary,
          highlightColor: p.surfaceSubtle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceMuted,
        hintStyle: TextStyle(color: p.textFaint, fontSize: 13.5),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 13),
        floatingLabelStyle: TextStyle(
          color: p.emeraldDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.emerald, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.rose),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.rose, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.surfaceSubtle,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.emerald,
        linearTrackColor: p.surfaceSubtle,
        circularTrackColor: p.surfaceSubtle,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.onAccent;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.emerald;
          return p.borderStrong;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.onyx,
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
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: p.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(p.borderStrong),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(8),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.emeraldDark,
        selectionColor: p.emerald.withValues(alpha: 0.22),
        selectionHandleColor: p.emeraldDark,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.emeraldSoft,
          selectedForegroundColor: p.emeraldDeep,
          foregroundColor: p.textSecondary,
          side: BorderSide(color: p.border),
          textStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
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
}
