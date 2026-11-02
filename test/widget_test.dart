import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/app_store.dart';
import 'package:quickdrop/core/discovery_service.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/main.dart';

void main() {
  testWidgets('QuickDrop dashboard renders', (WidgetTester tester) async {
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
    await tester.pump();

    expect(find.text('QuickDrop'), findsOneWidget);
    expect(find.text('Send files'), findsOneWidget);
    expect(find.text('Nearby devices'), findsOneWidget);
  });
}
