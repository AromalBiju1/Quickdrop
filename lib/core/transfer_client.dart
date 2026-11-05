import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/device_peer.dart';
import 'file_utils.dart';
import 'link_errors.dart';
import 'text_transfer.dart';

class TransferResult {
  final bool success;
  final bool canceled;
  final String message;
  final int durationMs;
  final String? savedPath;
  final int bytesSent;

  TransferResult({
    required this.success,
    required this.message,
    required this.durationMs,
    this.savedPath,
    this.bytesSent = 0,
    this.canceled = false,
  });
}

/// Lets the UI abort an in-flight upload. Closing the underlying client also
/// unblocks a stalled socket.
class TransferCancelToken {
  bool _canceled = false;
  HttpClient? _client;

  bool get isCanceled => _canceled;

  void cancel() {
    _canceled = true;
    _client?.close(force: true);
  }

  void _attach(HttpClient client) {
    _client = client;
    if (_canceled) client.close(force: true);
  }

  void _detach() {
    _client = null;
  }
}

class TransferClient {
  static Future<TransferResult> sendFile({
    required DevicePeer targetPeer,
    required File file,
    required String senderName,
    void Function(int sentBytes, int totalBytes)? onProgress,
    void Function()? onUploadFinished,
    TransferCancelToken? cancelToken,
    String? batchId,
    int fileIndex = 0,
    int fileTotal = 1,
  }) async {
    final startTime = DateTime.now();
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    client.idleTimeout = const Duration(seconds: 45);
    cancelToken?._attach(client);

    try {
      if (cancelToken?.isCanceled == true) {
        return TransferResult(
          success: false,
          canceled: true,
          message: 'Canceled',
          durationMs: 0,
        );
      }

      if (!await file.exists()) {
        return TransferResult(
          success: false,
          message: 'File no longer exists: ${FileUtils.fileName(file.path)}',
          durationMs: 0,
        );
      }

      final fileSize = await file.length();
      final fileName = FileUtils.fileName(file.path);
      final url = Uri.parse(
        'http://${targetPeer.ip}:${targetPeer.httpPort}/api/transfer',
      );
      final request = await client.postUrl(url);

      request.headers.set('X-File-Name', Uri.encodeComponent(fileName));
      request.headers.set('X-Sender-Name', Uri.encodeComponent(senderName));
      request.headers.set('X-File-Type', FileUtils.mimeType(fileName));
      request.headers.set('Content-Type', FileUtils.mimeType(fileName));
      if (batchId != null) {
        request.headers.set('X-Batch-Id', batchId);
        request.headers.set('X-File-Index', '${fileIndex + 1}');
        request.headers.set('X-File-Total', '$fileTotal');
      }
      request.contentLength = fileSize;

      var bytesSent = 0;
      final uploadStream = file.openRead().transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            if (cancelToken?.isCanceled == true) {
              sink.addError(const _CanceledException());
              return;
            }
            bytesSent += chunk.length;
            onProgress?.call(bytesSent, fileSize);
            sink.add(chunk);
          },
        ),
      );

      // addStream propagates socket backpressure to the file stream. Without
      // it the whole file is read into memory first: the UI jumps to 100% and
      // a large APK sits buffered for minutes (or dies under memory pressure).
      await request.addStream(uploadStream);

      if (cancelToken?.isCanceled == true) {
        throw const _CanceledException();
      }

      // Every byte is with the socket now; the receiver still has to finish
      // writing, renaming and acknowledging the file.
      onUploadFinished?.call();
      final response = await request.close().timeout(
        const Duration(minutes: 2),
      );
      final responseBody = await utf8.decodeStream(response);
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == HttpStatus.ok) {
        String? savedPath;
        try {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          savedPath = data['path'] as String?;
        } catch (_) {}
        return TransferResult(
          success: true,
          message:
              'Delivered in ${FileUtils.formatDuration(Duration(milliseconds: duration))}',
          durationMs: duration,
          savedPath: savedPath,
          bytesSent: bytesSent,
        );
      }

      return TransferResult(
        success: false,
        message: 'Receiver returned HTTP ${response.statusCode}',
        durationMs: duration,
        bytesSent: bytesSent,
      );
    } on _CanceledException {
      return TransferResult(
        success: false,
        canceled: true,
        message: 'Canceled',
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    } catch (e) {
      if (cancelToken?.isCanceled == true) {
        return TransferResult(
          success: false,
          canceled: true,
          message: 'Canceled',
          durationMs: DateTime.now().difference(startTime).inMilliseconds,
        );
      }

      // Legacy USB fallback: `adb reverse tcp:53319 tcp:53318` on the laptop.
      if (Platform.isAndroid && targetPeer.ip != '127.0.0.1') {
        try {
          final fallbackPeer = targetPeer.copyWith(
            ip: '127.0.0.1',
            httpPort: 53319,
          );
          final fallback = await sendFile(
            targetPeer: fallbackPeer,
            file: file,
            senderName: senderName,
            onProgress: onProgress,
            onUploadFinished: onUploadFinished,
            cancelToken: cancelToken,
            batchId: batchId,
            fileIndex: fileIndex,
            fileTotal: fileTotal,
          );
          if (fallback.success) return fallback;
        } catch (_) {}
      }

      return TransferResult(
        success: false,
        message: linkDropMessage(e, targetPeer.link) ?? _friendlyError(e),
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    } finally {
      cancelToken?._detach();
      client.close(force: true);
    }
  }

  static Future<TransferResult> sendText({
    required DevicePeer targetPeer,
    required String text,
    required String senderName,
  }) async {
    final startTime = DateTime.now();
    final validation = TextTransfer.validate(text);
    if (validation != null) {
      return TransferResult(success: false, message: validation, durationMs: 0);
    }

    final bytes = utf8.encode(text);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .postUrl(
            Uri.parse(
              'http://${targetPeer.ip}:${targetPeer.httpPort}/api/transfer',
            ),
          )
          .timeout(const Duration(seconds: 10));

      request.headers.set(
        'X-File-Name',
        Uri.encodeComponent(TextTransfer.fileName()),
      );
      request.headers.set('X-Sender-Name', Uri.encodeComponent(senderName));
      request.headers.set(TextTransfer.header, '1');
      request.headers.set('X-File-Type', 'text/plain');
      request.headers.set('Content-Type', 'text/plain; charset=utf-8');
      request.contentLength = bytes.length;
      request.add(bytes);

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final responseBody = await utf8.decodeStream(response);
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == HttpStatus.ok) {
        String? savedPath;
        try {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          savedPath = data['path'] as String?;
        } catch (_) {}
        return TransferResult(
          success: true,
          message:
              'Text delivered in '
              '${FileUtils.formatDuration(Duration(milliseconds: duration))}',
          durationMs: duration,
          savedPath: savedPath,
          bytesSent: bytes.length,
        );
      }

      return TransferResult(
        success: false,
        message: response.statusCode == HttpStatus.requestEntityTooLarge
            ? 'The receiver rejected the text as too large.'
            : 'Receiver returned HTTP ${response.statusCode}',
        durationMs: duration,
        bytesSent: bytes.length,
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return TransferResult(
          success: false,
          message: 'The receiver did not respond within 10 seconds.',
          durationMs: DateTime.now().difference(startTime).inMilliseconds,
        );
      }
      return TransferResult(
        success: false,
        message: linkDropMessage(e, targetPeer.link) ?? _friendlyError(e),
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _friendlyError(Object error) {
    final text = '$error';
    if (text.contains('Connection timed out') ||
        text.contains('errno = 110') ||
        text.contains('Operation timed out')) {
      return 'Connection timed out. Allow QuickDrop through the firewall on the receiver.';
    }
    if (text.contains('Connection refused') || text.contains('errno = 111')) {
      return 'QuickDrop is not running on the target device.';
    }
    if (text.contains('No route to host') || text.contains('errno = 113')) {
      return 'No route to that device. Check that both devices are on the same network.';
    }
    if (text.contains('Network is unreachable') ||
        text.contains('errno = 101')) {
      return 'Network is unreachable. Reconnect both devices to the same Wi-Fi or hotspot.';
    }
    if (text.contains('TimeoutException')) {
      return 'The receiver stopped responding while saving the file.';
    }
    if (text.contains('Connection closed') ||
        text.contains('Connection reset')) {
      return 'The connection dropped before the receiver finished. Keep both apps open and try again.';
    }
    return 'Transfer failed: $text';
  }

  /// Returns peer metadata when a QuickDrop receiver answers, otherwise null.
  static Future<DevicePeer?> probe(
    String ip, {
    int port = 53318,
    Duration timeout = const Duration(milliseconds: 800),
  }) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final url = Uri.parse('http://$ip:$port/api/ping');
      final request = await client.getUrl(url).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await utf8.decodeStream(response).timeout(timeout);
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['status'] != 'online') return null;
      return DevicePeer(
        id: data['id'] as String? ?? 'peer_$ip',
        name: data['device'] as String? ?? 'QuickDrop device',
        deviceType: data['device_type'] as String? ?? 'mobile',
        ip: ip,
        httpPort: (data['http_port'] as num?)?.toInt() ?? port,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<bool> ping(DevicePeer peer) async =>
      await probe(peer.ip, port: peer.httpPort) != null;
}

class _CanceledException implements Exception {
  const _CanceledException();
}
