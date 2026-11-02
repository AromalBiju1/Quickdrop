import '../models/link.dart';

/// Turns low-level socket failures into a recovery hint for tether links.
///
/// Returns null when the error is not a link-drop or the peer is on Wi-Fi, so
/// the caller can fall back to its generic error messages.
String? linkDropMessage(Object error, LinkKind link) {
  final text = '$error';
  final dropped =
      text.contains('Connection reset') ||
      text.contains('Connection closed') ||
      text.contains('Broken pipe') ||
      text.contains('No route to host') ||
      text.contains('Network is unreachable') ||
      text.contains('errno = 104') ||
      text.contains('errno = 101') ||
      text.contains('errno = 113');
  if (!dropped) return null;

  return switch (link) {
    LinkKind.usb => 'USB link disconnected — reconnect the cable and retry.',
    LinkKind.bluetooth =>
      'Bluetooth link disconnected — reconnect the tether and retry.',
    _ => null,
  };
}
