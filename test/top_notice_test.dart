import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/ui/components/top_notice.dart';

Future<void> _pumpHost(
  WidgetTester tester,
  TopNoticeCenter center, {
  Widget? home,
}) async {
  await tester.pumpWidget(
    TopNoticeScope(
      controller: center,
      child: MaterialApp(
        builder: (context, child) => TopNoticeHost(
          controller: center,
          child: child ?? const SizedBox.shrink(),
        ),
        home: home ?? const Scaffold(body: SizedBox()),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a top notice and dismisses it automatically',
      (tester) async {
    final center = TopNoticeCenter();
    await _pumpHost(tester, center);

    center.show(const TopNotice(
      message: 'File received',
      detail: 'photo.png from Laptop',
      duration: Duration(seconds: 3),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('File received'), findsOneWidget);
    expect(find.text('photo.png from Laptop'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('File received'), findsNothing);
    center.dispose();
  });

  testWidgets('runs the action and dismisses the notice', (tester) async {
    final center = TopNoticeCenter();
    await _pumpHost(tester, center);
    var tapped = 0;

    center.show(TopNotice(
      message: '2 files received',
      actionLabel: 'View',
      onAction: () => tapped++,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
    expect(find.text('2 files received'), findsNothing);
    center.dispose();
  });

  testWidgets('a newer notice replaces the current one', (tester) async {
    final center = TopNoticeCenter();
    await _pumpHost(tester, center);

    center.show(const TopNotice(message: 'First'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('First'), findsOneWidget);

    center.show(const TopNotice(message: 'Second'));
    await tester.pumpAndSettle();

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    center.dismiss();
    await tester.pumpAndSettle();
    center.dispose();
  });

  testWidgets('helper reaches the shared center from a route context',
      (tester) async {
    final center = TopNoticeCenter();
    await _pumpHost(
      tester,
      center,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showTopNotice(
              context,
              const TopNotice(message: 'Settings saved'),
            ),
            child: const Text('trigger'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Settings saved'), findsOneWidget);
    expect(center.current?.message, 'Settings saved');

    center.dismiss();
    await tester.pumpAndSettle();
    center.dispose();
  });
}
