import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/discovery_service.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/main.dart';

void main() {
  testWidgets('QuickDrop smoke test', (WidgetTester tester) async {
    final discovery = DiscoveryService(deviceId: 'test_dev');
    final server = TransferServer(deviceName: 'Test Device');

    await tester.pumpWidget(QuickDropApp(
      discoveryService: discovery,
      transferServer: server,
    ));

    expect(find.text('QuickDrop'), findsOneWidget);
  });
}
