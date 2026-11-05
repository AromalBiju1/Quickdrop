import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/app_store.dart';
import 'package:quickdrop/core/discovery_service.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/main.dart';
import 'package:quickdrop/ui/quickdrop_theme.dart';

void main() {
  testWidgets('QuickDrop dashboard renders', (WidgetTester tester) async {
    final discovery = DiscoveryService(
      deviceId: 'test_dev',
      deviceName: 'Test Device',
    );
    final server = TransferServer(
      deviceName: 'Test Device',
      deviceId: discovery.deviceId,
      enablePersistence: false,
    );

    await tester.pumpWidget(
      QuickDropApp(
        discoveryService: discovery,
        transferServer: server,
        settings: AppSettings.defaults(),
      ),
    );
    await tester.pump();

    expect(find.text('QuickDrop'), findsOneWidget);
    expect(find.text('Send files'), findsOneWidget);
    expect(find.text('Nearby devices'), findsOneWidget);
  });

  testWidgets('explicit dark mode applies the dark palette', (tester) async {
    final discovery = DiscoveryService(
      deviceId: 'test_dev',
      deviceName: 'Test Device',
    );
    final server = TransferServer(
      deviceName: 'Test Device',
      deviceId: discovery.deviceId,
      enablePersistence: false,
    );

    await tester.pumpWidget(
      QuickDropApp(
        discoveryService: discovery,
        transferServer: server,
        settings: AppSettings(
          deviceName: 'Test Device',
          themeMode: ThemeMode.dark,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      app.darkTheme?.extension<QuickDropPalette>()?.surface,
      QuickDropPalette.dark.surface,
    );

    final context = tester.element(find.text('QuickDrop'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('tabs switch and render the selected content', (tester) async {
    final discovery = DiscoveryService(
      deviceId: 'test_dev',
      deviceName: 'Test Device',
    );
    final server = TransferServer(
      deviceName: 'Test Device',
      deviceId: discovery.deviceId,
      enablePersistence: false,
    );

    await tester.pumpWidget(
      QuickDropApp(
        discoveryService: discovery,
        transferServer: server,
        settings: AppSettings.defaults(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Receive'));
    await tester.pumpAndSettle();

    expect(find.text('No Wi-Fi?'), findsOneWidget);
    expect(find.text('Send files'), findsNothing);
  });
}
