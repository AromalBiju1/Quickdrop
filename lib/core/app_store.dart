import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Lightweight JSON persistence. Keeps QuickDrop dependency-free while letting
/// settings, history and remembered peers survive a restart.
class AppStore {
  static Directory? _directory;

  static Future<Directory?> _dir() async {
    if (_directory != null) return _directory;
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/quickdrop');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _directory = dir;
      return dir;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> readJson(String name) async {
    try {
      final dir = await _dir();
      if (dir == null) return {};
      final file = File('${dir.path}/$name.json');
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> writeJson(String name, Object value) async {
    try {
      final dir = await _dir();
      if (dir == null) return;
      final file = File('${dir.path}/$name.json');
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(value), flush: true);
      await temp.rename(file.path);
    } catch (_) {
      // Persistence must never take the app down.
    }
  }

  static Future<AppSettings> loadSettings() async {
    final json = await readJson('settings');
    return AppSettings.fromJson(json);
  }

  static Future<void> saveSettings(AppSettings settings) =>
      writeJson('settings', settings.toJson());

  static Future<List<String>> loadRememberedPeers() async {
    final json = await readJson('peers');
    final peers = json['hosts'];
    if (peers is! List) return [];
    return peers.whereType<String>().toList();
  }

  static Future<void> saveRememberedPeers(List<String> hosts) =>
      writeJson('peers', {'hosts': hosts});
}

class AppSettings {
  final String deviceName;
  final bool autoCopyImages;
  final bool notifications;

  const AppSettings({
    required this.deviceName,
    this.autoCopyImages = true,
    this.notifications = true,
  });

  factory AppSettings.defaults() {
    var name = 'QuickDrop Device';
    try {
      final host = Platform.localHostname;
      if (host.isNotEmpty && host != 'localhost') {
        name = Platform.isLinux
            ? '$host (Linux)'
            : Platform.isWindows
            ? '$host (Windows)'
            : host;
      } else if (Platform.isAndroid) {
        name = 'Android Phone';
      } else if (Platform.isLinux) {
        name = 'Linux Laptop';
      } else if (Platform.isWindows) {
        name = 'Windows PC';
      }
    } catch (_) {}
    return AppSettings(deviceName: name);
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      deviceName: (json['device_name'] as String?)?.trim().isNotEmpty == true
          ? (json['device_name'] as String).trim()
          : defaults.deviceName,
      autoCopyImages: json['auto_copy_images'] as bool? ?? true,
      notifications: json['notifications'] as bool? ?? true,
    );
  }

  AppSettings copyWith({
    String? deviceName,
    bool? autoCopyImages,
    bool? notifications,
  }) {
    return AppSettings(
      deviceName: deviceName ?? this.deviceName,
      autoCopyImages: autoCopyImages ?? this.autoCopyImages,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'device_name': deviceName,
    'auto_copy_images': autoCopyImages,
    'notifications': notifications,
  };
}
