import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/link_errors.dart';
import 'package:quickdrop/models/link.dart';

void main() {
  test('USB failures explain how to recover', () {
    final message = linkDropMessage(
      'SocketException: Connection reset by peer (errno = 104)',
      LinkKind.usb,
    );

    expect(message, 'USB link disconnected — reconnect the cable and retry.');
  });

  test('Bluetooth failures explain how to recover', () {
    final message = linkDropMessage(
      'SocketException: Connection closed before full header was received',
      LinkKind.bluetooth,
    );

    expect(
      message,
      'Bluetooth link disconnected — reconnect the tether and retry.',
    );
  });

  test('Wi-Fi and non-connection errors keep the generic path', () {
    expect(
      linkDropMessage('SocketException: Connection reset', LinkKind.wifi),
      isNull,
    );
    expect(linkDropMessage('Receiver returned HTTP 500', LinkKind.usb), isNull);
  });
}
