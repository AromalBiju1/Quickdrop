import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/text_transfer.dart';
import 'package:quickdrop/core/transfer_client.dart';
import 'package:quickdrop/models/device_peer.dart';

void main() {
  test('sendText posts the raw UTF-8 body with text headers', () async {
    final received = Completer<Map<String, Object?>>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final body = await utf8.decodeStream(request);
      received.complete({
        'path': request.uri.path,
        'marker': request.headers.value(TextTransfer.header),
        'name': request.headers.value('X-File-Name'),
        'sender': request.headers.value('X-Sender-Name'),
        'body': body,
      });
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'success', 'path': '/tmp/text.txt'}));
      await request.response.close();
    });

    final peer = DevicePeer(
      id: 'peer',
      name: 'Peer',
      deviceType: 'desktop',
      ip: '127.0.0.1',
      httpPort: server.port,
    );

    final result = await TransferClient.sendText(
      targetPeer: peer,
      text: 'héllo\nworld',
      senderName: 'Me',
    );

    expect(result.success, isTrue);
    expect(result.savedPath, '/tmp/text.txt');

    final data = await received.future;
    expect(data['path'], '/api/transfer');
    expect(data['marker'], '1');
    expect(
      Uri.decodeComponent(data['name']! as String),
      startsWith('QuickDrop-text-'),
    );
    expect(Uri.decodeComponent(data['sender']! as String), 'Me');
    expect(data['body'], 'héllo\nworld');
  });

  test('sendText rejects empty text before opening a connection', () async {
    final peer = DevicePeer(
      id: 'peer',
      name: 'Peer',
      deviceType: 'desktop',
      ip: '127.0.0.1',
      httpPort: 1,
    );
    final result = await TransferClient.sendText(
      targetPeer: peer,
      text: '   ',
      senderName: 'Me',
    );
    expect(result.success, isFalse);
    expect(result.message, contains('Nothing'));
  });

  test('sendText rejects oversized text before opening a connection', () async {
    final peer = DevicePeer(
      id: 'peer',
      name: 'Peer',
      deviceType: 'desktop',
      ip: '127.0.0.1',
      httpPort: 1,
    );
    final result = await TransferClient.sendText(
      targetPeer: peer,
      text: List.filled(TextTransfer.maxBytes + 1, 'a').join(),
      senderName: 'Me',
    );
    expect(result.success, isFalse);
    expect(result.message, contains('64 KiB'));
  });
}
