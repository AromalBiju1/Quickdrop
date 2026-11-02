import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/app_store.dart';
import 'package:quickdrop/core/discovery_service.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/main.dart';

Future<void> _loadInter() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}

void main() {
  testWidgets('render tabs for visual review', (WidgetTester tester) async {
    await _loadInter();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final discovery = DiscoveryService(deviceId: 'test_dev', deviceName: 'Test Device');
    final server = TransferServer(
      deviceName: 'Test Device',
      deviceId: discovery.deviceId,
      enablePersistence: false,
    );

    await tester.pumpWidget(QuickDropApp(
      discoveryService: discovery,
      transferServer: server,
      settings: AppSettings.defaults(),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(QuickDropApp),
      matchesGoldenFile('goldens/send.png'),
    );

    await tester.tap(find.text('Receive').first);
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(QuickDropApp),
      matchesGoldenFile('goldens/receive.png'),
    );

    await tester.tap(find.text('Transfers').first);
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(QuickDropApp),
      matchesGoldenFile('goldens/transfers.png'),
    );
  });
}
