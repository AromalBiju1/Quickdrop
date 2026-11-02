import 'dart:io';

import 'file_utils.dart';

class LinuxIntegrations {
  static Future<bool> copyImageToClipboard(String filePath) async {
    if (!Platform.isLinux) return false;
    final file = File(filePath);
    if (!await file.exists()) return false;

    final mime = _mimeFor(filePath);

    // Wayland
    if (await _hasCommand('wl-copy')) {
      try {
        final process = await Process.start('wl-copy', ['--type', mime]);
        await file.openRead().pipe(process.stdin);
        final exitCode = await process.exitCode.timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            process.kill();
            return -1;
          },
        );
        if (exitCode == 0) return true;
      } catch (_) {}
    }

    // X11
    for (final command in const ['xclip', 'xsel']) {
      if (!await _hasCommand(command)) continue;
      try {
        final args = command == 'xclip'
            ? ['-selection', 'clipboard', '-target', mime, '-i']
            : ['--clipboard', '--input', '--mime-type', mime];
        final process = await Process.start(command, args);
        await file.openRead().pipe(process.stdin);
        final exitCode = await process.exitCode.timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            process.kill();
            return -1;
          },
        );
        if (exitCode == 0) return true;
      } catch (_) {}
    }

    return false;
  }

  static String _mimeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/png';
  }

  static Future<bool> _hasCommand(String command) async {
    try {
      final result = await Process.run('which', [command]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<void> showDesktopNotification(
    String title,
    String message, {
    String? imagePath,
  }) async {
    if (!Platform.isLinux) return;
    try {
      final args = <String>['-a', 'QuickDrop', '-t', '3500'];
      if (imagePath != null &&
          File(imagePath).existsSync() &&
          FileUtils.isImage(imagePath)) {
        args.addAll(['-i', imagePath]);
      }
      args.addAll([title, message]);
      await Process.run('notify-send', args);
    } catch (_) {}
  }

  static Future<void> openFile(String filePath) async {
    if (Platform.isLinux) {
      try {
        await Process.run('xdg-open', [filePath]);
      } catch (_) {}
    }
  }

  static Future<void> openFolder(String folderPath) async {
    if (Platform.isLinux) {
      try {
        await Process.run('xdg-open', [folderPath]);
      } catch (_) {}
    }
  }

  static Future<void> openUrl(String url) async {
    if (Platform.isLinux) {
      try {
        await Process.run('xdg-open', [url]);
      } catch (_) {}
    }
  }
}
