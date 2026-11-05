import 'dart:io';

import 'package:flutter/services.dart';

import 'linux_integrations.dart';
import 'windows_integrations.dart';

class SavedDownload {
  final String uri;
  final String path;

  const SavedDownload({required this.uri, required this.path});
}

/// Small bridge for the two OS actions that make offline setup easier:
/// opening hotspot settings on Android and opening the web receiver.
class PlatformIntegrations {
  static const MethodChannel _channel = MethodChannel('quickdrop/system');

  static Future<bool> openHotspotSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openHotspotSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openWifiSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openWifiSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openUrl(String url) async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<bool>('openUrl', {'url': url}) ??
            false;
      } catch (_) {
        return false;
      }
    }
    if (Platform.isLinux) {
      return LinuxIntegrations.openUrl(url);
    }
    if (Platform.isWindows) {
      return WindowsIntegrations.openUrl(url);
    }
    return false;
  }

  /// Copies a received file into public Downloads/QuickDrop on Android.
  ///
  /// Scoped storage blocks plain writes to Downloads, so the native side
  /// inserts a MediaStore row and streams the staged file into it.
  static Future<SavedDownload?> saveToDownloads({
    required String path,
    required String fileName,
    required String mimeType,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveToDownloads',
        {'path': path, 'fileName': fileName, 'mimeType': mimeType},
      );
      final uri = result?['uri'] as String?;
      final savedPath = result?['path'] as String?;
      if (uri == null || savedPath == null) return null;
      return SavedDownload(uri: uri, path: savedPath);
    } catch (_) {
      return null;
    }
  }

  /// Opens the system Downloads view (or the app's folder when available).
  static Future<bool> openDownloads() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('openDownloads') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens a content URI (preferred) or a file path with the system viewer.
  static Future<bool> openFile(String target, {String? mimeType}) async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<bool>('openFile', {
              'uri': target,
              'mimeType': mimeType ?? '*/*',
            }) ??
            false;
      } catch (_) {
        return false;
      }
    }
    if (Platform.isLinux) return LinuxIntegrations.openFile(target);
    if (Platform.isWindows) return WindowsIntegrations.openFile(target);
    return false;
  }

  static Future<bool> openFolder(String target) async {
    if (Platform.isLinux) return LinuxIntegrations.openFolder(target);
    if (Platform.isWindows) return WindowsIntegrations.openFolder(target);
    return false;
  }

  static Future<bool> copyImageToClipboard(String filePath) async {
    if (Platform.isLinux) {
      return LinuxIntegrations.copyImageToClipboard(filePath);
    }
    if (Platform.isWindows) {
      return WindowsIntegrations.copyImageToClipboard(filePath);
    }
    return false;
  }

  /// Puts plain text on the system clipboard on every supported platform.
  static Future<bool> copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> showDesktopNotification(
    String title,
    String message, {
    String? imagePath,
  }) async {
    if (Platform.isLinux) {
      await LinuxIntegrations.showDesktopNotification(
        title,
        message,
        imagePath: imagePath,
      );
    } else if (Platform.isWindows) {
      await WindowsIntegrations.showDesktopNotification(
        title,
        message,
        imagePath: imagePath,
      );
    }
  }
}
