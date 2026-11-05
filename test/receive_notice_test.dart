import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/app_store.dart';
import 'package:quickdrop/core/discovery_service.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/main.dart';
import 'package:quickdrop/models/device_peer.dart';
import 'package:quickdrop/ui/quickdrop_theme.dart';

TransferItem _item(String name, {String? id}) {
  return TransferItem(
    id: id ?? 'rx_$name',
    fileName: name,
    fileSize: 1024,
    filePath: '/tmp/$name',
    senderName: 'Laptop',
    isIncoming: true,
    timestamp: DateTime(2026, 11, 2),
    success: true,
  );
}

Future<void> _pumpApp(WidgetTester tester, TransferServer server) async {
  final discovery = DiscoveryService(
    deviceId: 'test_dev',
    deviceName: 'Test Device',
  );
  await tester.pumpWidget(
    QuickDropApp(
      discoveryService: discovery,
      transferServer: server,
      settings: AppSettings.defaults(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

TransferServer _server() => TransferServer(
      deviceName: 'Test Device',
      deviceId: 'test_dev',
      enablePersistence: false,
    );

void main() {
  testWidgets('history loaded at startup does not raise a notice',
      (tester) async {
    final server = _server();
    server.historyNotifier.value = [_item('old.png')];

    await _pumpApp(tester, server);

    expect(find.text('File received'), findsNothing);
  });

  testWidgets('incoming files group into one top notice and View opens Received',
      (tester) async {
    final server = _server();
    await _pumpApp(tester, server);

    server.addIncomingHistory(_item('photo.png'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    server.addIncomingHistory(_item('clip.mov'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2 files received'), findsOneWidget);
    expect(find.text('from Laptop'), findsOneWidget);

    await tester.tap(find.text('View'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Transfers'), findsWidgets);
    final received = tester.widget<Text>(find.text('Received'));
    expect(received.style?.color, QuickDropPalette.light.textPrimary);
    expect(find.text('2 files received'), findsNothing);
  });
}
