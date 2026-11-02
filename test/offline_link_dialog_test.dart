import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/app_store.dart';
import 'package:quickdrop/core/discovery_service.dart';
import 'package:quickdrop/core/link_manager.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/main.dart';
import 'package:quickdrop/models/link.dart';
import 'package:quickdrop/ui/components/offline_link_dialog.dart';

class _FakeProvider implements LinkProvider {
  final List<LinkInterface> links;

  const _FakeProvider(this.links);

  @override
  Future<List<LinkInterface>> discover() async => links;
}

void main() {
  testWidgets('offline dialog shows setup steps and detected links', (
    tester,
  ) async {
    final manager = LinkManager(
      provider: const _FakeProvider([
        LinkInterface(name: 'usb0', ip: '192.168.42.5', kind: LinkKind.usb),
        LinkInterface(name: 'bnep0', ip: '10.0.0.5', kind: LinkKind.bluetooth),
      ]),
    );
    await manager.refresh();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfflineLinkDialog(linkManager: manager)),
      ),
    );

    expect(find.text('Use USB or Bluetooth'), findsOneWidget);
    expect(find.text('USB tethering'), findsOneWidget);
    expect(find.text('Bluetooth tethering'), findsOneWidget);
    expect(find.text('usb0'), findsOneWidget);
    expect(find.text('192.168.42.5'), findsOneWidget);
    expect(find.text('bnep0'), findsOneWidget);
    expect(find.text('10.0.0.5'), findsOneWidget);
  });

  testWidgets('offline dialog explains when no links are detected', (
    tester,
  ) async {
    final manager = LinkManager(provider: const _FakeProvider([]));
    await manager.refresh();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfflineLinkDialog(linkManager: manager)),
      ),
    );

    expect(find.text('No tethering links detected yet.'), findsOneWidget);
  });

  testWidgets('No Wi-Fi? on the receive tab opens the offline dialog', (
    tester,
  ) async {
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

    await tester.tap(find.text('Receive').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No Wi-Fi?'), findsOneWidget);
    await tester.ensureVisible(find.text('No Wi-Fi?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No Wi-Fi?'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Use USB or Bluetooth'), findsOneWidget);
  });
}
