import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/text_transfer.dart';
import 'package:quickdrop/core/transfer_server.dart';
import 'package:quickdrop/models/device_peer.dart';

Future<TransferServer> _start({
  Future<bool> Function(String text)? copyText,
}) async {
  final dir = await Directory.systemTemp.createTemp('quickdrop_text_test_');
  final server = TransferServer(
    deviceName: 'Receiver',
    deviceId: 'rx_test',
    port: 0,
    saveDirectoryOverride: dir.path,
    enablePersistence: false,
    copyTextOverride: copyText,
  );
  server.notifications = false;
  await server.start();
  addTearDown(() async {
    server.stop();
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  return server;
}

Future<HttpClientResponse> _post(
  TransferServer server, {
  required String fileName,
  required String body,
  bool text = true,
}) async {
  final client = HttpClient();
  addTearDown(() => client.close(force: true));
  final request = await client.postUrl(
    Uri.parse('http://127.0.0.1:${server.boundPort}/api/transfer'),
  );
  request.headers.set('X-File-Name', Uri.encodeComponent(fileName));
  request.headers.set('X-Sender-Name', Uri.encodeComponent('Sender'));
  request.headers.set('Content-Type', 'text/plain; charset=utf-8');
  if (text) request.headers.set(TextTransfer.header, '1');
  final bytes = utf8.encode(body);
  request.contentLength = bytes.length;
  request.add(bytes);
  return request.close();
}

Future<Map<String, dynamic>> _json(HttpClientResponse response) async =>
    jsonDecode(await utf8.decodeStream(response)) as Map<String, dynamic>;

void main() {
  test('text upload saves, copies and records a text entry', () async {
    var copied = '';
    final server = await _start(copyText: (text) async {
      copied = text;
      return true;
    });

    final response = await _post(
      server,
      fileName: 'QuickDrop-text-test.txt',
      body: 'https://example.com',
    );

    expect(response.statusCode, HttpStatus.ok);
    final body = await _json(response);
    expect(body['kind'], 'text');
    expect(body['clipboard'], isTrue);
    expect(copied, 'https://example.com');

    final item = server.historyNotifier.value.single;
    expect(item.kind, TransferKind.text);
    expect(item.preview, 'https://example.com');
    expect(item.filePath, endsWith('.txt'));
    expect(await File(item.filePath).readAsString(), 'https://example.com');
  });

  test('empty text returns 400 and records nothing', () async {
    final server = await _start(copyText: (_) async => true);
    final response = await _post(
      server,
      fileName: 'empty.txt',
      body: '   ',
    );
    expect(response.statusCode, HttpStatus.badRequest);
    expect(server.historyNotifier.value, isEmpty);
  });

  test('text over 64 KiB returns 413 and records nothing', () async {
    final server = await _start(copyText: (_) async => true);
    final response = await _post(
      server,
      fileName: 'big.txt',
      body: List.filled(TextTransfer.maxBytes + 1, 'a').join(),
    );
    expect(response.statusCode, HttpStatus.requestEntityTooLarge);
    expect(server.historyNotifier.value, isEmpty);
  });

  test('upload without the text header keeps file behavior', () async {
    final server = await _start(copyText: (_) async => true);
    final response = await _post(
      server,
      fileName: 'note.txt',
      body: 'a normal file',
      text: false,
    );
    expect(response.statusCode, HttpStatus.ok);
    final item = server.historyNotifier.value.single;
    expect(item.kind, TransferKind.file);
    expect(item.preview, isNull);
  });

  test('clipboard failure keeps the file and history entry', () async {
    final server = await _start(copyText: (_) async => false);
    final response = await _post(
      server,
      fileName: 'clipboard.txt',
      body: 'still saved',
    );
    expect(response.statusCode, HttpStatus.ok);
    final body = await _json(response);
    expect(body['clipboard'], isFalse);
    final item = server.historyNotifier.value.single;
    expect(File(item.filePath).existsSync(), isTrue);
  });
}
