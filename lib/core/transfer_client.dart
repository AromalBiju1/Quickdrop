import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/device_peer.dart';

class TransferResult {
  final bool success;
  final String message;
  final int durationMs;
  final String? savedPath;

  TransferResult({
    required this.success,
    required this.message,
    required this.durationMs,
    this.savedPath,
  });
}

class TransferClient {
  static Future<TransferResult> sendPhoto({
    required DevicePeer targetPeer,
    required File file,
    required String senderName,
    void Function(double progress)? onProgress,
  }) async {
    final startTime = DateTime.now();
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);

    try {
      if (!await file.exists()) {
        return TransferResult(
          success: false,
          message: 'Selected file does not exist',
          durationMs: 0,
        );
      }

      final fileSize = await file.length();
      final fileName = file.path.split(Platform.isWindows ? '\\' : '/').last;

      final url = Uri.parse('http://${targetPeer.ip}:${targetPeer.httpPort}/api/transfer');
      final request = await client.postUrl(url);

      request.headers.set('X-File-Name', Uri.encodeComponent(fileName));
      request.headers.set('X-Sender-Name', senderName);
      request.headers.set('Content-Length', fileSize.toString());

      final ext = fileName.toLowerCase();
      if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
        request.headers.set('Content-Type', 'image/jpeg');
      } else {
        request.headers.set('Content-Type', 'image/png');
      }

      // Stream file with progress tracking
      final fileStream = file.openRead();
      int bytesSent = 0;

      await for (final chunk in fileStream) {
        request.add(chunk);
        bytesSent += chunk.length;
        if (onProgress != null && fileSize > 0) {
          onProgress(bytesSent / fileSize);
        }
      }

      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == HttpStatus.ok) {
        try {
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          return TransferResult(
            success: true,
            message: 'Delivered in ${duration}ms',
            durationMs: duration,
            savedPath: data['path'] as String?,
          );
        } catch (_) {
          return TransferResult(
            success: true,
            message: 'Delivered in ${duration}ms',
            durationMs: duration,
          );
        }
      } else {
        return TransferResult(
          success: false,
          message: 'Server error: ${response.statusCode}',
          durationMs: duration,
        );
      }
    } catch (e) {
      // Fallback: If on mobile and direct IP timed out, try ADB reverse port 127.0.0.1:53319
      if (Platform.isAndroid && targetPeer.ip != '127.0.0.1') {
        try {
          final fallbackPeer = DevicePeer(
            id: 'adb_reverse',
            name: targetPeer.name,
            deviceType: targetPeer.deviceType,
            ip: '127.0.0.1',
            httpPort: 53319,
          );
          return await sendPhoto(
            targetPeer: fallbackPeer,
            file: file,
            senderName: senderName,
            onProgress: onProgress,
          );
        } catch (_) {}
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      String friendlyMsg = '$e';
      if (friendlyMsg.contains('Connection timed out') || friendlyMsg.contains('errno = 110')) {
        friendlyMsg = 'Firewall blocked connection. Run "sudo ufw allow 53318/tcp" on laptop.';
      } else if (friendlyMsg.contains('Connection refused') || friendlyMsg.contains('errno = 111')) {
        friendlyMsg = 'QuickDrop is not running on target device.';
      }

      return TransferResult(
        success: false,
        message: friendlyMsg,
        durationMs: duration,
      );
    } finally {
      client.close();
    }
  }

  static Future<bool> ping(DevicePeer peer) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 2);
    try {
      final url = Uri.parse('http://${peer.ip}:${peer.httpPort}/api/ping');
      final req = await client.getUrl(url);
      final res = await req.close();
      return res.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
