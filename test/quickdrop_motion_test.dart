import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/ui/quickdrop_motion.dart';

void main() {
  testWidgets('reduced motion returns zero durations', (tester) async {
    late bool reduced;
    late Duration duration;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            reduced = QuickDropMotion.reduced(context);
            duration = QuickDropMotion.duration(
              context,
              const Duration(milliseconds: 200),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(reduced, isTrue);
    expect(duration, Duration.zero);
  });

  testWidgets('normal motion keeps the requested duration', (tester) async {
    late Duration duration;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            duration = QuickDropMotion.duration(
              context,
              const Duration(milliseconds: 200),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(duration, const Duration(milliseconds: 200));
  });
}
