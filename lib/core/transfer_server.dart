import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/device_peer.dart';
import 'app_store.dart';
import 'file_utils.dart';
import 'platform_integrations.dart';
import 'text_transfer.dart';

class TransferServer {
  static const int serverPort = 53318;

  String deviceName;
  final String deviceId;
  final int port;
  final String? saveDirectoryOverride;
  final bool enablePersistence;
  final Future<bool> Function(String text)? copyTextOverride;

  bool autoCopyImages = true;
  bool notifications = true;

  HttpServer? _server;
  Directory? _defaultDirectory;

  final ValueNotifier<List<TransferItem>> historyNotifier =
      ValueNotifier<List<TransferItem>>([]);
  final ValueNotifier<TransferItem?> activeTransferNotifier =
      ValueNotifier<TransferItem?>(null);
  final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);

  TransferServer({
    required this.deviceName,
    this.deviceId = 'server',
    this.port = serverPort,
    this.saveDirectoryOverride,
    this.enablePersistence = true,
    this.copyTextOverride,
  });

  Future<void> start() async {
    await _loadHistory();
    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );
      _server?.listen(
        _handleRequest,
        onError: (e) {
          debugPrint('[Server] Request error: $e');
        },
      );
      isRunningNotifier.value = true;
      debugPrint('[Server] Listening on port ${_server?.port ?? port}');
    } catch (e) {
      isRunningNotifier.value = false;
      debugPrint('[Server] Failed to bind HTTP server: $e');
    }
  }

  int get boundPort => _server?.port ?? port;

  Future<Directory> getSaveDirectory({String? fileName}) async {
    if (saveDirectoryOverride != null) {
      final dir = Directory(saveDirectoryOverride!);
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }

    final isImage = fileName == null || FileUtils.isImage(fileName);
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final home = Platform.isWindows
          ? (Platform.environment['USERPROFILE'] ??
                Platform.environment['HOME'] ??
                Directory.current.path)
          : (Platform.environment['HOME'] ??
                Platform.environment['USERPROFILE'] ??
                Directory.current.path);
      final path = Platform.isLinux && isImage
          ? p.join(home, 'Pictures', 'Screenshots')
          : p.join(home, 'Downloads', 'QuickDrop');
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      if (isImage) _defaultDirectory = dir;
      return dir;
    }

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final qdDir = Directory(p.join(extDir.path, 'QuickDrop'));
        if (!await qdDir.exists()) await qdDir.create(recursive: true);
        _defaultDirectory = qdDir;
        return qdDir;
      }
    } catch (_) {}
    final fallback = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(fallback.path, 'QuickDrop'));
    if (!await dir.exists()) await dir.create(recursive: true);
    _defaultDirectory = dir;
    return dir;
  }

  Future<Directory> getLastSaveDirectory() async {
    return _defaultDirectory ?? await getSaveDirectory();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;
    try {
      if (path == '/api/ping' || path == '/api/info') {
        await _handlePing(request);
        return;
      }
      if (path == '/api/transfer' && request.method == 'POST') {
        await _handleIncomingTransfer(request);
        return;
      }
      if (path == '/' || path == '/web' || path == '/web/') {
        await _handleWebInterface(request);
        return;
      }
      if (path == '/favicon.ico') {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found');
      await request.response.close();
    } catch (e) {
      debugPrint('[Server] Unhandled request error: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> _handlePing(HttpRequest request) async {
    request.response
      ..headers.contentType = ContentType.json
      ..statusCode = HttpStatus.ok
      ..write(
        jsonEncode({
          'status': 'online',
          'id': deviceId,
          'device': deviceName,
          'device_type': _deviceType,
          'platform': Platform.operatingSystem,
          'http_port': boundPort,
          'version': '2.0',
          'offline_capable': true,
        }),
      );
    await request.response.close();
  }

  Future<void> _handleIncomingTransfer(HttpRequest request) async {
    if (request.headers.value(TextTransfer.header) == '1') {
      await _handleIncomingText(request);
      return;
    }
    File? tempFile;
    try {
      final rawFileName = request.headers.value('X-File-Name');
      final fallbackName = 'file_${DateTime.now().millisecondsSinceEpoch}';
      final fileName = FileUtils.sanitizeFileName(
        rawFileName != null && rawFileName.isNotEmpty
            ? Uri.decodeComponent(rawFileName)
            : fallbackName,
      );
      final senderName = Uri.decodeComponent(
        request.headers.value('X-Sender-Name') ?? 'Unknown',
      );
      final batchId = request.headers.value('X-Batch-Id');
      final fileIndex = int.tryParse(
        request.headers.value('X-File-Index') ?? '',
      );
      final fileTotal = int.tryParse(
        request.headers.value('X-File-Total') ?? '',
      );

      final saveDir = await getSaveDirectory(fileName: fileName);
      final targetFile = await FileUtils.uniqueFile(saveDir, fileName);
      tempFile = File('${targetFile.path}.part');

      final sink = tempFile.openWrite();
      var receivedBytes = 0;
      final expectedBytes = request.contentLength;
      // addStream keeps the socket's backpressure, so a 200 MB upload is
      // written to disk as it arrives instead of being buffered in memory.
      final counted = request.map((chunk) {
        receivedBytes += chunk.length;
        return chunk;
      });
      await sink.addStream(counted);
      await sink.flush();
      await sink.close();

      if (expectedBytes >= 0 && receivedBytes != expectedBytes) {
        throw HttpException(
          'Incomplete upload: received $receivedBytes of $expectedBytes bytes',
          uri: request.uri,
        );
      }

      await tempFile.rename(targetFile.path);
      tempFile = null;

      // Android scoped storage does not allow writing into public Downloads
      // with a plain path. The file is staged here first, then copied through
      // MediaStore so it shows up in the phone's Downloads/QuickDrop folder.
      var savedPath = targetFile.path;
      String? savedUri;
      if (Platform.isAndroid) {
        final saved = await PlatformIntegrations.saveToDownloads(
          path: targetFile.path,
          fileName: FileUtils.fileName(targetFile.path),
          mimeType: FileUtils.mimeType(targetFile.path),
        );
        if (saved != null) {
          savedPath = saved.path;
          savedUri = saved.uri;
          try {
            await targetFile.delete();
          } catch (e) {
            debugPrint('[Server] Could not remove staging file: $e');
          }
        } else {
          debugPrint(
            '[Server] Could not publish to Downloads; kept ${targetFile.path}',
          );
        }
      }

      final isDesktop = Platform.isLinux || Platform.isWindows;
      var copiedToClipboard = false;
      if (isDesktop && autoCopyImages && FileUtils.isImage(targetFile.path)) {
        copiedToClipboard = await PlatformIntegrations.copyImageToClipboard(
          targetFile.path,
        );
      }

      final suffix = fileTotal != null && fileTotal > 1 && fileIndex != null
          ? ' ($fileIndex/$fileTotal)'
          : '';
      if (isDesktop && notifications) {
        await PlatformIntegrations.showDesktopNotification(
          'QuickDrop • File received',
          '${FileUtils.fileName(targetFile.path)}$suffix from $senderName'
              '${copiedToClipboard ? ' • copied to clipboard' : ''}',
          imagePath: targetFile.path,
        );
      }

      final item = TransferItem(
        id: 'rx_${DateTime.now().microsecondsSinceEpoch}',
        fileName: FileUtils.fileName(savedPath),
        fileSize: receivedBytes,
        filePath: savedPath,
        contentUri: savedUri,
        senderName: senderName,
        isIncoming: true,
        timestamp: DateTime.now(),
        success: true,
        batchId: batchId,
      );
      addIncomingHistory(item);

      request.response
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(
          jsonEncode({
            'status': 'success',
            'file': item.fileName,
            'path': item.filePath,
            'uri': item.contentUri,
            'size': item.fileSize,
            'clipboard': copiedToClipboard,
          }),
        );
      await request.response.close();
    } catch (e, st) {
      debugPrint('[Server] Error handling transfer: $e\n$st');
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      try {
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.internalServerError
          ..write(jsonEncode({'error': e.toString()}));
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> _handleIncomingText(HttpRequest request) async {
    File? tempFile;
    try {
      final bytes = <int>[];
      var totalBytes = 0;

      // Read the whole body but only keep the first 64 KiB. Draining the rest
      // lets the sender receive the 413 instead of a connection reset.
      await for (final chunk in request) {
        totalBytes += chunk.length;
        if (totalBytes <= TextTransfer.maxBytes) {
          bytes.addAll(chunk);
        }
      }

      if (totalBytes > TextTransfer.maxBytes) {
        await _writeJsonError(
          request,
          HttpStatus.requestEntityTooLarge,
          'Text is limited to 64 KiB.',
        );
        return;
      }

      String text;
      try {
        text = utf8.decode(bytes);
      } on FormatException {
        await _writeJsonError(
          request,
          HttpStatus.badRequest,
          'Text must be UTF-8.',
        );
        return;
      }

      if (text.trim().isEmpty) {
        await _writeJsonError(request, HttpStatus.badRequest, 'Text is empty.');
        return;
      }

      if (text.length > TextTransfer.maxCharacters) {
        await _writeJsonError(
          request,
          HttpStatus.requestEntityTooLarge,
          'Text is limited to ${TextTransfer.maxCharacters} characters.',
        );
        return;
      }

      final rawName = request.headers.value('X-File-Name');
      var fileName = FileUtils.sanitizeFileName(
        rawName != null && rawName.isNotEmpty
            ? Uri.decodeComponent(rawName)
            : TextTransfer.fileName(),
      );
      if (!fileName.toLowerCase().endsWith('.txt')) {
        fileName = '$fileName.txt';
      }
      final senderName = Uri.decodeComponent(
        request.headers.value('X-Sender-Name') ?? 'Unknown',
      );

      final saveDir = await getSaveDirectory(fileName: fileName);
      final targetFile = await FileUtils.uniqueFile(saveDir, fileName);
      tempFile = File('${targetFile.path}.part');
      await tempFile.writeAsBytes(bytes, flush: true);
      await tempFile.rename(targetFile.path);
      tempFile = null;

      var savedPath = targetFile.path;
      String? savedUri;
      if (Platform.isAndroid) {
        final saved = await PlatformIntegrations.saveToDownloads(
          path: targetFile.path,
          fileName: FileUtils.fileName(targetFile.path),
          mimeType: 'text/plain',
        );
        if (saved != null) {
          savedPath = saved.path;
          savedUri = saved.uri;
          try {
            await targetFile.delete();
          } catch (e) {
            debugPrint('[Server] Could not remove text staging file: $e');
          }
        }
      }

      var copied = false;
      try {
        copied =
            await (copyTextOverride ??
                PlatformIntegrations.copyTextToClipboard)(text);
      } catch (e) {
        debugPrint('[Server] Could not copy text to clipboard: $e');
      }

      final isDesktop = Platform.isLinux || Platform.isWindows;
      if (isDesktop && notifications) {
        await PlatformIntegrations.showDesktopNotification(
          'QuickDrop • Text received',
          '${TextTransfer.notificationPreview(text)} from $senderName'
              '${copied ? ' • copied to clipboard' : ' • saved without clipboard'}',
        );
      }

      final item = TransferItem(
        id: 'rx_${DateTime.now().microsecondsSinceEpoch}',
        fileName: FileUtils.fileName(savedPath),
        fileSize: totalBytes,
        filePath: savedPath,
        contentUri: savedUri,
        senderName: senderName,
        isIncoming: true,
        timestamp: DateTime.now(),
        success: true,
        kind: TransferKind.text,
        preview: TextTransfer.preview(text),
      );
      addIncomingHistory(item);

      request.response
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(
          jsonEncode({
            'status': 'success',
            'kind': 'text',
            'file': item.fileName,
            'path': item.filePath,
            'uri': item.contentUri,
            'size': item.fileSize,
            'clipboard': copied,
          }),
        );
      await request.response.close();
    } catch (e, st) {
      debugPrint('[Server] Error handling text transfer: $e\n$st');
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      await _writeJsonError(
        request,
        HttpStatus.internalServerError,
        e.toString(),
      );
    }
  }

  Future<void> _writeJsonError(
    HttpRequest request,
    int status,
    String message,
  ) async {
    try {
      request.response
        ..headers.contentType = ContentType.json
        ..statusCode = status
        ..write(jsonEncode({'error': message}));
      await request.response.close();
    } catch (_) {}
  }

  void addIncomingHistory(TransferItem item) => _addTransferHistory(item);

  void addOutgoingHistory(TransferItem item) => _addTransferHistory(item);

  void _addTransferHistory(TransferItem item) {
    final list = List<TransferItem>.from(historyNotifier.value);
    list.insert(0, item);
    if (list.length > 200) list.removeRange(200, list.length);
    historyNotifier.value = list;
    activeTransferNotifier.value = item;
    _persistHistory();
  }

  void clearHistory() {
    historyNotifier.value = [];
    _persistHistory();
  }

  Future<void> _loadHistory() async {
    if (!enablePersistence) return;
    try {
      final json = await AppStore.readJson('history');
      final items = json['items'];
      if (items is! List) return;
      historyNotifier.value = items
          .whereType<Map>()
          .map((e) => TransferItem.fromJson(Map<String, dynamic>.from(e)))
          .take(200)
          .toList();
    } catch (e) {
      debugPrint('[Server] Failed to load history: $e');
    }
  }

  void _persistHistory() {
    if (!enablePersistence) return;
    unawaited(
      AppStore.writeJson('history', {
        'items': historyNotifier.value.map((item) => item.toJson()).toList(),
      }),
    );
  }

  Future<void> _handleWebInterface(HttpRequest request) async {
    final html = _webTemplate
        .replaceAll('{{DEVICE_NAME}}', _escapeHtml(deviceName))
        .replaceAll('{{VERSION}}', '2.0');
    request.response
      ..headers.contentType = ContentType.html
      ..statusCode = HttpStatus.ok
      ..write(html);
    await request.response.close();
  }

  static String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  String get _deviceType =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows
      ? 'desktop'
      : 'mobile';

  void stop() {
    _server?.close(force: true);
    _server = null;
    isRunningNotifier.value = false;
  }

  static const String _webTemplate = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0a0f1a">
<title>QuickDrop • {{DEVICE_NAME}}</title>
<style>
  :root {
    --bg: #070b12;
    --panel: #0f1624;
    --panel-2: #141d2e;
    --line: #223048;
    --text: #eef4ff;
    --muted: #8fa0bb;
    --cyan: #22e6ff;
    --blue: #4f7cff;
    --green: #2fe6a7;
    --red: #ff5d7a;
    --amber: #ffc247;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    min-height: 100vh;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: var(--text);
    background:
      radial-gradient(900px 500px at 10% -10%, rgba(34,230,255,.13), transparent 60%),
      radial-gradient(800px 500px at 100% 0%, rgba(79,124,255,.16), transparent 55%),
      var(--bg);
    padding: 28px 16px 56px;
  }
  .wrap { max-width: 720px; margin: 0 auto; }
  header { display: flex; align-items: center; gap: 12px; margin-bottom: 26px; }
  .logo {
    width: 46px; height: 46px; border-radius: 14px;
    display: grid; place-items: center;
    background: linear-gradient(140deg, var(--cyan), var(--blue));
    box-shadow: 0 10px 34px rgba(34,230,255,.22);
  }
  .logo svg { width: 24px; height: 24px; fill: #041019; }
  .brand { font-size: 20px; font-weight: 800; letter-spacing: -.4px; }
  .brand small { display: block; font-size: 11px; font-weight: 600; color: var(--muted); letter-spacing: .08em; text-transform: uppercase; margin-top: 2px; }
  .badge {
    margin-left: auto; display: inline-flex; align-items: center; gap: 7px;
    padding: 8px 12px; border-radius: 999px; font-size: 11px; font-weight: 700;
    color: var(--green); background: rgba(47,230,167,.09);
    border: 1px solid rgba(47,230,167,.25); white-space: nowrap;
  }
  .dot { width: 7px; height: 7px; border-radius: 50%; background: var(--green); box-shadow: 0 0 10px rgba(47,230,167,.9); }
  .card {
    background: linear-gradient(180deg, rgba(255,255,255,.025), transparent 40%), var(--panel);
    border: 1px solid var(--line); border-radius: 24px; padding: 26px;
    box-shadow: 0 30px 80px rgba(0,0,0,.35);
  }
  h1 { font-size: clamp(24px, 5vw, 34px); line-height: 1.1; letter-spacing: -1px; margin: 0 0 10px; }
  h1 span { color: var(--cyan); }
  .sub { color: var(--muted); font-size: 14px; line-height: 1.6; margin: 0 0 22px; }
  .device { display: flex; align-items: center; gap: 10px; margin-bottom: 18px; }
  .device-pill { padding: 7px 11px; border-radius: 9px; background: var(--panel-2); border: 1px solid var(--line); font-size: 12px; color: var(--muted); }
  .device-pill b { color: var(--text); font-weight: 700; }
  .drop {
    border: 1.5px dashed rgba(34,230,255,.45); border-radius: 18px;
    padding: 38px 20px; text-align: center; cursor: pointer;
    background: rgba(34,230,255,.035); transition: .18s ease;
  }
  .drop:hover, .drop.over { background: rgba(34,230,255,.09); border-color: var(--cyan); transform: translateY(-1px); }
  .drop-icon {
    width: 58px; height: 58px; margin: 0 auto 14px; border-radius: 18px;
    display: grid; place-items: center; background: rgba(34,230,255,.1);
    border: 1px solid rgba(34,230,255,.22);
  }
  .drop-icon svg { width: 26px; height: 26px; stroke: var(--cyan); fill: none; stroke-width: 1.8; }
  .drop-title { font-weight: 700; font-size: 16px; margin-bottom: 5px; }
  .drop-hint { color: var(--muted); font-size: 12.5px; }
  .pick {
    display: inline-flex; align-items: center; gap: 8px; margin-top: 18px;
    background: linear-gradient(135deg, var(--cyan), var(--blue)); color: #041019;
    border: 0; border-radius: 12px; padding: 12px 20px; font-size: 14px;
    font-weight: 800; cursor: pointer; font-family: inherit;
  }
  .pick:disabled { opacity: .6; cursor: default; }
  input[type=file] { display: none; }
  .files { margin-top: 18px; display: flex; flex-direction: column; gap: 10px; }
  .file {
    display: flex; align-items: center; gap: 12px; padding: 12px 14px;
    background: var(--panel-2); border: 1px solid var(--line); border-radius: 14px;
    animation: rise .2s ease both;
  }
  @keyframes rise { from { opacity: 0; transform: translateY(5px); } to { opacity: 1; transform: none; } }
  .file-icon {
    width: 38px; height: 38px; border-radius: 11px; flex: 0 0 auto;
    display: grid; place-items: center; background: rgba(79,124,255,.12);
    color: #9fb5ff; font-size: 10px; font-weight: 800; letter-spacing: .04em;
  }
  .file-main { min-width: 0; flex: 1; }
  .file-name { font-size: 13px; font-weight: 650; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .file-meta { color: var(--muted); font-size: 11px; margin-top: 3px; }
  .bar { height: 4px; border-radius: 999px; background: #1b2740; margin-top: 8px; overflow: hidden; }
  .bar > i { display: block; height: 100%; width: 0; border-radius: inherit; background: linear-gradient(90deg, var(--cyan), var(--blue)); transition: width .18s ease; }
  .state { font-size: 11px; font-weight: 800; color: var(--muted); white-space: nowrap; }
  .state.ok { color: var(--green); }
  .state.err { color: var(--red); }
  .state.working { color: var(--cyan); }
  .summary { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-top: 18px; padding-top: 18px; border-top: 1px solid var(--line); color: var(--muted); font-size: 12px; }
  .summary b { color: var(--text); }
  .progress-total { height: 6px; border-radius: 999px; background: #182238; overflow: hidden; margin-top: 10px; display: none; }
  .progress-total > i { display: block; height: 100%; width: 0; background: linear-gradient(90deg, var(--cyan), var(--blue)); transition: width .18s ease; }
  .tip { margin-top: 18px; color: var(--muted); font-size: 12px; line-height: 1.6; text-align: center; }
  .tip b { color: #b8c6dd; font-weight: 650; }
  footer { margin-top: 18px; text-align: center; color: #56657f; font-size: 11px; letter-spacing: .04em; }
  @media (max-width: 480px) {
    body { padding: 18px 12px 36px; }
    .card { padding: 20px 16px; border-radius: 20px; }
    .badge { display: none; }
    .drop { padding: 30px 14px; }
  }
</style>
</head>
<body>
<div class="wrap">
  <header>
    <div class="logo">
      <svg viewBox="0 0 24 24"><path d="M13.2 2 4 14h6.1l-1.3 8L19 10h-6.2l.4-8z"/></svg>
    </div>
    <div class="brand">QuickDrop<small>Browser receiver</small></div>
    <div class="badge"><span class="dot"></span> DIRECT &amp; OFFLINE</div>
  </header>

  <div class="card">
    <h1>Send files to <span>{{DEVICE_NAME}}</span>.</h1>
    <p class="sub">Pick anything from this phone or computer. Files travel straight over the local network — no cloud, no account, and no internet connection required.</p>

    <div class="device">
      <div class="device-pill">Receiving on <b>{{DEVICE_NAME}}</b></div>
      <div class="device-pill">v{{VERSION}}</div>
    </div>

    <div class="drop" id="drop">
      <div class="drop-icon">
        <svg viewBox="0 0 24 24"><path d="M12 16V4m0 0L7 9m5-5 5 5"/><path d="M4 15v3a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-3"/></svg>
      </div>
      <div class="drop-title">Drop files here</div>
      <div class="drop-hint">or choose them from this device · multiple files welcome</div>
      <button class="pick" id="pick" type="button">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>
        Choose files
      </button>
    </div>
    <input type="file" id="input" multiple>

    <div class="files" id="files"></div>
    <div class="progress-total" id="totalBar"><i></i></div>
    <div class="summary" id="summary" style="display:none">
      <span id="summaryText"></span>
      <b id="summarySize"></b>
    </div>

    <p class="tip"><b>Works without internet</b> — keep this page open until the files finish. They are saved on the receiving device automatically.</p>
  </div>
  <footer>QuickDrop · local-first file transfer</footer>
</div>
<script>
(function () {
  var input = document.getElementById('input');
  var drop = document.getElementById('drop');
  var pick = document.getElementById('pick');
  var filesEl = document.getElementById('files');
  var summary = document.getElementById('summary');
  var summaryText = document.getElementById('summaryText');
  var summarySize = document.getElementById('summarySize');
  var totalBar = document.getElementById('totalBar');
  var totalFill = totalBar.firstElementChild;
  var running = false;

  function fmt(bytes) {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes / 1024).toFixed(bytes < 10240 ? 1 : 0) + ' KB';
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(bytes < 10485760 ? 1 : 0) + ' MB';
    return (bytes / 1073741824).toFixed(2) + ' GB';
  }

  function ext(name) {
    var i = name.lastIndexOf('.');
    if (i < 0 || i === name.length - 1) return 'FILE';
    return name.slice(i + 1, i + 5).toUpperCase();
  }

  function makeRow(file) {
    var row = document.createElement('div');
    row.className = 'file';
    var icon = document.createElement('div');
    icon.className = 'file-icon';
    icon.textContent = ext(file.name);
    var main = document.createElement('div');
    main.className = 'file-main';
    var name = document.createElement('div');
    name.className = 'file-name';
    name.textContent = file.name;
    var meta = document.createElement('div');
    meta.className = 'file-meta';
    meta.textContent = fmt(file.size);
    var bar = document.createElement('div');
    bar.className = 'bar';
    var fill = document.createElement('i');
    bar.appendChild(fill);
    main.appendChild(name); main.appendChild(meta); main.appendChild(bar);
    var state = document.createElement('div');
    state.className = 'state';
    state.textContent = 'QUEUED';
    row.appendChild(icon); row.appendChild(main); row.appendChild(state);
    filesEl.appendChild(row);
    return { row: row, fill: fill, state: state };
  }

  function uploadOne(file, ui) {
    return new Promise(function (resolve) {
      var xhr = new XMLHttpRequest();
      xhr.open('POST', '/api/transfer');
      xhr.setRequestHeader('X-File-Name', encodeURIComponent(file.name));
      xhr.setRequestHeader('X-Sender-Name', encodeURIComponent('Web browser'));
      xhr.setRequestHeader('X-File-Type', file.type || 'application/octet-stream');
      xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream');
      ui.state.textContent = 'SENDING';
      ui.state.className = 'state working';
      xhr.upload.onprogress = function (e) {
        if (!e.lengthComputable) return;
        var pct = Math.round(e.loaded / e.total * 100);
        ui.fill.style.width = pct + '%';
        ui.state.textContent = pct + '%';
      };
      xhr.onload = function () {
        if (xhr.status >= 200 && xhr.status < 300) {
          ui.fill.style.width = '100%';
          ui.state.textContent = 'SAVED';
          ui.state.className = 'state ok';
          resolve(true);
        } else {
          ui.state.textContent = 'FAILED';
          ui.state.className = 'state err';
          resolve(false);
        }
      };
      xhr.onerror = function () {
        ui.state.textContent = 'FAILED';
        ui.state.className = 'state err';
        resolve(false);
      };
      xhr.send(file);
    });
  }

  async function send(files) {
    if (running || !files || !files.length) return;
    running = true;
    pick.disabled = true;
    filesEl.innerHTML = '';
    summary.style.display = 'flex';
    totalBar.style.display = 'block';
    totalFill.style.width = '0%';
    var list = Array.prototype.slice.call(files);
    var totalBytes = list.reduce(function (n, f) { return n + f.size; }, 0);
    var done = 0, ok = 0;
    summaryText.textContent = 'Sending ' + list.length + (list.length === 1 ? ' file' : ' files') + '…';
    summarySize.textContent = fmt(totalBytes);
    var rows = list.map(makeRow);

    for (var i = 0; i < list.length; i++) {
      var success = await uploadOne(list[i], rows[i]);
      done += list[i].size;
      if (success) ok++;
      totalFill.style.width = Math.round(done / Math.max(totalBytes, 1) * 100) + '%';
    }

    summaryText.textContent = ok === list.length
      ? 'All files delivered to the receiving device'
      : ok + ' of ' + list.length + ' files delivered';
    if (ok < list.length) summaryText.style.color = 'var(--red)';
    running = false;
    pick.disabled = false;
    input.value = '';
    setTimeout(function () { totalBar.style.display = 'none'; }, 1500);
  }

  pick.addEventListener('click', function (e) {
    e.stopPropagation();
    input.click();
  });
  drop.addEventListener('click', function () { input.click(); });
  input.addEventListener('change', function () { send(input.files); });

  ['dragenter', 'dragover'].forEach(function (evt) {
    drop.addEventListener(evt, function (e) { e.preventDefault(); drop.classList.add('over'); });
  });
  ['dragleave', 'drop'].forEach(function (evt) {
    drop.addEventListener(evt, function (e) { e.preventDefault(); drop.classList.remove('over'); });
  });
  drop.addEventListener('drop', function (e) {
    if (e.dataTransfer && e.dataTransfer.files) send(e.dataTransfer.files);
  });
  document.addEventListener('dragover', function (e) { e.preventDefault(); });
  document.addEventListener('drop', function (e) { e.preventDefault(); });
})();
</script>
</body>
</html>''';
}
