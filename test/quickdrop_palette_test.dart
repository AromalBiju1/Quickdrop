import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/ui/quickdrop_theme.dart';

void main() {
  test('light and dark palettes are distinct', () {
    expect(
      QuickDropPalette.light.surface,
      isNot(QuickDropPalette.dark.surface),
    );
    expect(
      QuickDropPalette.light.textPrimary,
      isNot(QuickDropPalette.dark.textPrimary),
    );
    expect(QuickDropPalette.light.onAccent, const Color(0xFFFFFFFF));
  });

  test('palette lerp blends every color', () {
    final mid = QuickDropPalette.light.lerp(QuickDropPalette.dark, 0.5);
    expect(
      mid.background,
      Color.lerp(
        QuickDropPalette.light.background,
        QuickDropPalette.dark.background,
        0.5,
      ),
    );
    expect(mid.surface, isNot(QuickDropPalette.light.surface));
  });

  testWidgets('context.qd resolves from the theme extension', (tester) async {
    late QuickDropPalette seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: QuickDropTheme.light,
        home: Builder(
          builder: (context) {
            seen = context.qd;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen.surface, QuickDropPalette.light.surface);
  });

  testWidgets('dark theme carries the dark palette', (tester) async {
    late QuickDropPalette seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: QuickDropTheme.dark,
        home: Builder(
          builder: (context) {
            seen = context.qd;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen.background, QuickDropPalette.dark.background);
  });
}
