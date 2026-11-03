import 'dart:io';

/// Windows desktop integration for the handful of actions Flutter does not
/// provide out of the box.
///
/// Shell actions use the Windows file-protocol handler, so Explorer handles
/// file associations and URLs exactly as it would for a double-click. Clipboard
/// image and notification support use the PowerShell/.NET APIs that ship with
/// Windows 10 and 11.
class WindowsIntegrations {
  static Future<bool> copyImageToClipboard(String filePath) async {
    if (!Platform.isWindows) return false;
    final file = File(filePath);
    if (!await file.exists()) return false;

    const script = r'''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$image = [System.Drawing.Image]::FromFile($env:QUICKDROP_IMAGE)
try {
  [System.Windows.Forms.Clipboard]::SetImage($image)
} finally {
  $image.Dispose()
}
''';

    try {
      final result = await Process.run(
        _powershellPath,
        const [
          '-NoLogo',
          '-NoProfile',
          '-NonInteractive',
          '-STA',
          '-WindowStyle',
          'Hidden',
          '-Command',
          script,
        ],
        environment: {'QUICKDROP_IMAGE': file.absolute.path},
      ).timeout(const Duration(seconds: 12));
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
    if (!Platform.isWindows) return;

    // A tray balloon works for unpackaged Win32 apps without requiring an
    // installed Start-menu shortcut or an AppUserModelID registration.
    const script = r'''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$icon = $null
try {
  if ($env:QUICKDROP_EXE) {
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($env:QUICKDROP_EXE)
  }
} catch {}
$notify = New-Object System.Windows.Forms.NotifyIcon
try {
  if ($icon -ne $null) {
    $notify.Icon = $icon
  } else {
    $notify.Icon = [System.Drawing.SystemIcons]::Information
  }
  $notify.BalloonTipTitle = $env:QUICKDROP_TITLE
  $notify.BalloonTipText = $env:QUICKDROP_MESSAGE
  $notify.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
  $notify.Visible = $true
  $notify.ShowBalloonTip(5000)
  Start-Sleep -Seconds 6
} finally {
  $notify.Visible = $false
  $notify.Dispose()
  if ($icon -ne $null) { $icon.Dispose() }
}
''';

    try {
      await Process.start(
        _powershellPath,
        const [
          '-NoLogo',
          '-NoProfile',
          '-NonInteractive',
          '-STA',
          '-WindowStyle',
          'Hidden',
          '-Command',
          script,
        ],
        environment: {
          'QUICKDROP_TITLE': title,
          'QUICKDROP_MESSAGE': message,
          'QUICKDROP_EXE': Platform.resolvedExecutable,
        },
        mode: ProcessStartMode.detached,
      );
    } catch (_) {}
  }

  static Future<bool> openFile(String filePath) async {
    if (!Platform.isWindows) return false;
    return _openWithShell(filePath);
  }

  static Future<bool> openFolder(String folderPath) async {
    if (!Platform.isWindows) return false;
    try {
      final process = await Process.start(_systemExecutable('explorer.exe'), [
        folderPath,
      ], mode: ProcessStartMode.detached);
      return process.pid > 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openUrl(String url) async {
    if (!Platform.isWindows) return false;
    return _openWithShell(url);
  }

  /// Opens files and URLs through the shell's registered protocol handler.
  static Future<bool> _openWithShell(String target) async {
    if (target.isEmpty) return false;
    try {
      final process = await Process.start(_systemExecutable('rundll32.exe'), [
        'url.dll,FileProtocolHandler',
        target,
      ], mode: ProcessStartMode.detached);
      return process.pid > 0;
    } catch (_) {
      return false;
    }
  }

  static String get _powershellPath {
    final root = Platform.environment['SystemRoot'];
    if (root != null && root.isNotEmpty) {
      final candidate =
          '$root\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
      if (File(candidate).existsSync()) return candidate;
    }
    return 'powershell.exe';
  }

  static String _systemExecutable(String name) {
    final root = Platform.environment['SystemRoot'];
    if (root != null && root.isNotEmpty) {
      final candidate = '$root\\System32\\$name';
      if (File(candidate).existsSync()) return candidate;
    }
    return name;
  }
}
