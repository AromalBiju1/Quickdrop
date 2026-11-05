import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/app_store.dart';
import 'package:quickdrop/core/discovery_service.dart';
import 'package:quickdrop/core/quickdrop_controller.dart';
import 'package:quickdrop/core/text_transfer.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/models/device_peer.dart';
import 'package:quickdrop/ui/components/text_composer_sheet.dart';
import 'package:quickdrop/ui/quickdrop_theme.dart';

QuickDropController _controller() {
  final discovery = DiscoveryService(deviceId: 'me', deviceName: 'Me');
  final server = TransferServer(
    deviceName: 'Me',
    deviceId: 'me',
    enablePersistence: false,
  );
  return QuickDropController(
    discovery: discovery,
    server: server,
    settings: const AppSettings(deviceName: 'Me'),
  );
}

Widget _wrap(QuickDropController controller) {
  return MaterialApp(
    theme: QuickDropTheme.light,
    home: Scaffold(body: TextComposerSheet(controller: controller)),
  );
}

void main() {
  testWidgets('composer counts characters and disables empty sends', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(controller));
    expect(find.text('0 / 16000'), findsOneWidget);

    FilledButton sendButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send'),
    );
    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(find.text('5 / 16000'), findsOneWidget);
    expect(sendButton().onPressed, isNull); // no peer selected
  });

  testWidgets('composer enables send for a peer and pastes the clipboard', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    controller.discovery.peersNotifier.value = [
      DevicePeer(
        id: 'peer',
        name: 'Pixel',
        deviceType: 'mobile',
        ip: '127.0.0.1',
        httpPort: 1,
      ),
    ];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          return {'text': 'pasted text'};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_wrap(controller));
    await tester.tap(find.text('Paste'));
    await tester.pump();

    expect(find.text('pasted text'), findsOneWidget);
    expect(find.text('11 / 16000'), findsOneWidget);

    FilledButton sendButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send'),
    );
    expect(sendButton().onPressed, isNotNull);
  });

  testWidgets('composer disables send when the text is over the limit', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    controller.discovery.peersNotifier.value = [
      DevicePeer(
        id: 'peer',
        name: 'Pixel',
        deviceType: 'mobile',
        ip: '127.0.0.1',
        httpPort: 1,
      ),
    ];

    await tester.pumpWidget(_wrap(controller));
    await tester.enterText(
      find.byType(TextField),
      List.filled(TextTransfer.maxCharacters + 1, 'a').join(),
    );
    await tester.pump();

    expect(find.text('16001 / 16000'), findsOneWidget);
    final sendButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send'),
    );
    expect(sendButton.onPressed, isNull);
  });
}
