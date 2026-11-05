import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/app_store.dart';
import 'package:quickdrop/core/discovery_service.dart';
import 'package:quickdrop/core/quickdrop_controller.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/models/device_peer.dart';

void main() {
  test('sendTextToPeer records an outgoing text entry', () async {
    final dir = await Directory.systemTemp.createTemp('quickdrop_ctrl_text_');
    final server = TransferServer(
      deviceName: 'Me',
      deviceId: 'me',
      port: 0,
      saveDirectoryOverride: dir.path,
      enablePersistence: false,
      copyTextOverride: (_) async => true,
    );
    await server.start();
    addTearDown(() async {
      server.stop();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    final discovery = DiscoveryService(deviceId: 'me', deviceName: 'Me');
    final controller = QuickDropController(
      discovery: discovery,
      server: server,
      settings: const AppSettings(
        deviceName: 'Me',
        notifications: false,
      ),
    );
    addTearDown(controller.dispose);

    final peer = DevicePeer(
      id: 'self',
      name: 'Me',
      deviceType: 'desktop',
      ip: '127.0.0.1',
      httpPort: server.boundPort,
    );

    final result = await controller.sendTextToPeer(peer, 'hello');

    expect(result.success, isTrue);
    final outgoing = server.historyNotifier.value.firstWhere(
      (item) => !item.isIncoming,
    );
    expect(outgoing.kind, TransferKind.text);
    expect(outgoing.preview, 'hello');
    expect(outgoing.filePath, isEmpty);
  });
}
