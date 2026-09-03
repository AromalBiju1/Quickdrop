import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/device_peer.dart';
import 'linux_integrations.dart';

class TransferServer {
  static const int serverPort = 53318;
  final String deviceName;
  HttpServer? _server;

  final ValueNotifier<List<TransferItem>> historyNotifier =
      ValueNotifier<List<TransferItem>>([]);
  final ValueNotifier<TransferItem?> activeTransferNotifier =
      ValueNotifier<TransferItem?>(null);

  TransferServer({required this.deviceName});

  Future<void> start() async {
    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        serverPort,
        shared: true,
      );
      _server?.listen(_handleRequest, onError: (e) {
        debugPrint('[Server] Request error: $e');
      });
      debugPrint('[Server] Listening on port $serverPort');
    } catch (e) {
      debugPrint('[Server] Failed to bind HTTP server: $e');
    }
  }

  Future<Directory> getSaveDirectory() async {
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '/home/elyssia';
      final screenshotsDir = Directory('$home/Pictures/Screenshots');
      if (!await screenshotsDir.exists()) {
        try {
          await screenshotsDir.create(recursive: true);
          return screenshotsDir;
        } catch (_) {}
      } else {
        return screenshotsDir;
      }
      final downloadsDir = Directory('$home/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    } else {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final qdDir = Directory('${extDir.path}/QuickDrop');
          if (!await qdDir.exists()) await qdDir.create(recursive: true);
          return qdDir;
        }
      } catch (_) {}
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // Enable CORS for web browser drops
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    if (path == '/api/ping') {
      request.response
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({
          'status': 'online',
          'device': deviceName,
          'platform': Platform.operatingSystem,
        }));
      await request.response.close();
      return;
    }

    if (path == '/api/transfer' && request.method == 'POST') {
      await _handleIncomingTransfer(request);
      return;
    }

    if (path == '/' || path == '/web') {
      await _handleWebInterface(request);
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not Found');
    await request.response.close();
  }

  Future<void> _handleIncomingTransfer(HttpRequest request) async {
    try {
      final rawFileName = request.headers.value('X-File-Name');
      final fileName = rawFileName != null && rawFileName.isNotEmpty
          ? Uri.decodeComponent(rawFileName)
          : 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';

      final senderName = request.headers.value('X-Sender-Name') ?? 'Phone';
      final saveDir = await getSaveDirectory();

      // Ensure unique filename if already exists
      var targetFile = File('${saveDir.path}/$fileName');
      if (await targetFile.exists()) {
        final dotIdx = fileName.lastIndexOf('.');
        final base = dotIdx != -1 ? fileName.substring(0, dotIdx) : fileName;
        final ext = dotIdx != -1 ? fileName.substring(dotIdx) : '';
        targetFile = File('${saveDir.path}/${base}_${DateTime.now().millisecondsSinceEpoch}$ext');
      }

      final sink = targetFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in request) {
        sink.add(chunk);
        receivedBytes += chunk.length;
      }
      await sink.flush();
      await sink.close();

      debugPrint('[Server] Received $fileName ($receivedBytes bytes) saved to ${targetFile.path}');

      // Zero-touch clipboard copy & desktop notification on Linux
      bool copiedToClipboard = false;
      if (Platform.isLinux) {
        copiedToClipboard = await LinuxIntegrations.copyImageToClipboard(targetFile.path);
        await LinuxIntegrations.showDesktopNotification(
          'QuickDrop: Screenshot Received',
          'Saved to ${targetFile.path.split('/').last}${copiedToClipboard ? " & copied to clipboard!" : ""}',
          imagePath: targetFile.path,
        );
      }

      final item = TransferItem(
        id: 'rx_${DateTime.now().millisecondsSinceEpoch}',
        fileName: targetFile.path.split('/').last,
        fileSize: receivedBytes,
        filePath: targetFile.path,
        senderName: senderName,
        isIncoming: true,
        timestamp: DateTime.now(),
        success: true,
      );

      _addTransferHistory(item);

      request.response
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({
          'status': 'success',
          'file': item.fileName,
          'path': item.filePath,
          'size': item.fileSize,
          'clipboard': copiedToClipboard,
        }));
      await request.response.close();
    } catch (e, st) {
      debugPrint('[Server] Error handling transfer: $e\n$st');
      request.response
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  void _addTransferHistory(TransferItem item) {
    final list = List<TransferItem>.from(historyNotifier.value);
    list.insert(0, item);
    historyNotifier.value = list;
    activeTransferNotifier.value = item;
  }

  void addOutgoingHistory(TransferItem item) {
    _addTransferHistory(item);
  }

  Future<void> _handleWebInterface(HttpRequest request) async {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>QuickDrop Web Receiver</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0B0E14; color: #E0E6ED; margin: 0; padding: 24px; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 90vh; }
    .card { background: #151922; border: 1px solid #283042; border-radius: 16px; padding: 32px; max-width: 440px; width: 100%; text-align: center; box-shadow: 0 10px 40px rgba(0,0,0,0.5); }
    h1 { color: #00F0FF; margin-top: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.5px; }
    p { color: #8892B0; font-size: 14px; line-height: 1.5; }
    .drop-zone { border: 2px dashed #00F0FF; border-radius: 12px; padding: 36px 16px; margin: 20px 0; background: rgba(0, 240, 255, 0.03); cursor: pointer; transition: 0.2s; }
    .drop-zone:hover { background: rgba(0, 240, 255, 0.08); }
    input[type=file] { display: none; }
    .btn { background: linear-gradient(135deg, #00F0FF, #0072FF); color: #000; font-weight: 700; border: none; padding: 12px 24px; border-radius: 8px; cursor: pointer; font-size: 15px; width: 100%; margin-top: 10px; }
    #status { margin-top: 16px; font-size: 13px; font-weight: 600; }
  </style>
</head>
<body>
  <div class="card">
    <h1>QuickDrop Direct Beam</h1>
    <p>Target Device: <strong>$deviceName</strong></p>
    <div class="drop-zone" onclick="document.getElementById('fileInput').click()">
      <div style="font-size: 36px; margin-bottom: 8px;">📸</div>
      <div>Click or Drag & Drop Screenshot Here</div>
      <input type="file" id="fileInput" accept="image/*" onchange="uploadFile(this.files[0])">
    </div>
    <div id="status"></div>
  </div>
  <script>
    async function uploadFile(file) {
      if (!file) return;
      const status = document.getElementById('status');
      status.innerText = 'Sending ' + file.name + '...';
      status.style.color = '#00F0FF';
      try {
        const res = await fetch('/api/transfer', {
          method: 'POST',
          headers: {
            'X-File-Name': encodeURIComponent(file.name),
            'X-Sender-Name': 'Web Browser',
            'Content-Type': file.type || 'image/png'
          },
          body: file
        });
        if (res.ok) {
          status.innerText = '✓ Sent! Copied to laptop clipboard & saved.';
          status.style.color = '#00E676';
        } else {
          status.innerText = 'Failed: ' + res.statusText;
          status.style.color = '#FF5252';
        }
      } catch (err) {
        status.innerText = 'Error: ' + err.message;
        status.style.color = '#FF5252';
      }
    }
  </script>
</body>
</html>
''';

    request.response
      ..headers.contentType = ContentType.html
      ..statusCode = HttpStatus.ok
      ..write(html);
    await request.response.close();
  }

  void stop() {
    _server?.close(force: true);
    _server = null;
  }
}
