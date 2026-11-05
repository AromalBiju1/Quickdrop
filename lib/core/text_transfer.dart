import 'dart:convert';

/// Constants and helpers shared by the text sender, receiver and browser page.
class TextTransfer {
  static const String header = 'X-Text-Snippet';
  static const int maxCharacters = 16000;
  static const int maxBytes = 64 * 1024;

  static String fileName({DateTime? at}) {
    final time = at ?? DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'QuickDrop-text-${time.year}${two(time.month)}${two(time.day)}'
        '-${two(time.hour)}${two(time.minute)}${two(time.second)}.txt';
  }

  static int byteLength(String text) => utf8.encode(text).length;

  /// Returns a user-facing error, or null when the text can be sent.
  static String? validate(String text) {
    if (text.trim().isEmpty) return 'Nothing to send.';
    if (byteLength(text) > maxBytes) {
      return 'Text is limited to 64 KiB.';
    }
    if (text.length > maxCharacters) {
      return 'Text is limited to $maxCharacters characters.';
    }
    return null;
  }

  /// First 500 characters, used by history. Keeps line breaks.
  static String preview(String text, {int limit = 500}) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}…';
  }

  /// One-line, 80-character preview for notifications and banners.
  static String notificationPreview(String text, {int limit = 80}) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= limit) return flat;
    return '${flat.substring(0, limit)}…';
  }
}
