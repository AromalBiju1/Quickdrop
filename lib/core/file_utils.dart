import 'dart:io';

import 'package:path/path.dart' as p;

/// Small, dependency-free helpers shared by the sender, receiver and web UI.
class FileUtils {
  static const Map<String, String> _mimeTypes = {
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.bmp': 'image/bmp',
    '.heic': 'image/heic',
    '.heif': 'image/heif',
    '.svg': 'image/svg+xml',
    '.avif': 'image/avif',
    '.pdf': 'application/pdf',
    '.txt': 'text/plain',
    '.md': 'text/markdown',
    '.json': 'application/json',
    '.csv': 'text/csv',
    '.zip': 'application/zip',
    '.apk': 'application/vnd.android.package-archive',
    '.mp4': 'video/mp4',
    '.mov': 'video/quicktime',
    '.webm': 'video/webm',
    '.mkv': 'video/x-matroska',
    '.mp3': 'audio/mpeg',
    '.m4a': 'audio/mp4',
    '.wav': 'audio/wav',
    '.flac': 'audio/flac',
    '.ogg': 'audio/ogg',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xls': 'application/vnd.ms-excel',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.ppt': 'application/vnd.ms-powerpoint',
    '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  };

  static String fileName(String path) {
    if (path.isEmpty) return 'file';
    return p.basename(path);
  }

  static String extension(String path) =>
      p.extension(path).toLowerCase();

  static String mimeType(String path) =>
      _mimeTypes[extension(path)] ?? 'application/octet-stream';

  static bool isImage(String path) => mimeType(path).startsWith('image/');

  static bool isVideo(String path) => mimeType(path).startsWith('video/');

  static bool isAudio(String path) => mimeType(path).startsWith('audio/');

  /// Removes path separators and control characters so an incoming file name
  /// can never escape the receive directory.
  static String sanitizeFileName(String name) {
    var clean = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_').trim();
    clean = clean.replaceAll(RegExp(r'^\.+'), '');
    if (clean.isEmpty) clean = 'file';
    if (clean.length > 180) {
      final ext = p.extension(clean);
      clean = clean.substring(0, 180 - ext.length) + ext;
    }
    return clean;
  }

  /// Returns a path that does not exist yet, e.g. `photo (2).png`.
  static Future<File> uniqueFile(Directory directory, String fileName) async {
    final safeName = sanitizeFileName(fileName);
    var candidate = File(p.join(directory.path, safeName));
    if (!await candidate.exists()) return candidate;

    final base = p.basenameWithoutExtension(safeName);
    final ext = p.extension(safeName);
    var index = 2;
    while (await candidate.exists()) {
      candidate = File(p.join(directory.path, '$base ($index)$ext'));
      index++;
    }
    return candidate;
  }

  static String formatBytes(int bytes) {
    if (bytes < 0) bytes = 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatSpeed(double bytesPerSecond) {
    if (!bytesPerSecond.isFinite || bytesPerSecond <= 0) return '—';
    return '${formatBytes(bytesPerSecond.round())}/s';
  }

  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 1) return '${duration.inMilliseconds} ms';
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  static String friendlyTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
