import 'dart:io';

class LinuxIntegrations {
  static Future<bool> copyImageToClipboard(String filePath) async {
    if (!Platform.isLinux) return false;
    final file = File(filePath);
    if (!await file.exists()) return false;

    // Detect MIME type based on extension
    final ext = filePath.toLowerCase();
    final mime = ext.endsWith('.jpg') || ext.endsWith('.jpeg') ? 'image/jpeg' : 'image/png';

    // 1. Try wl-copy (Wayland)
    try {
      final whichWl = await Process.run('which', ['wl-copy']);
      if (whichWl.exitCode == 0) {
        final process = await Process.start('wl-copy', ['--type', mime]);
        await file.openRead().pipe(process.stdin);
        final exitCode = await process.exitCode;
        if (exitCode == 0) return true;
      }
    } catch (_) {}

    // 2. Fallback to xclip (X11)
    try {
      final whichXclip = await Process.run('which', ['xclip']);
      if (whichXclip.exitCode == 0) {
        final process = await Process.start('xclip', [
          '-selection',
          'clipboard',
          '-target',
          mime,
          '-i',
        ]);
        await file.openRead().pipe(process.stdin);
        final exitCode = await process.exitCode;
        if (exitCode == 0) return true;
      }
    } catch (_) {}

    return false;
  }

  static Future<void> showDesktopNotification(
    String title,
    String message, {
    String? imagePath,
  }) async {
    if (!Platform.isLinux) return;
    try {
      final args = <String>['-a', 'QuickDrop'];
      if (imagePath != null && File(imagePath).existsSync()) {
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
}
