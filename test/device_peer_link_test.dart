import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/models/device_peer.dart';
import 'package:quickdrop/models/link.dart';

void main() {
  test('peer defaults to an unknown link', () {
    final peer = DevicePeer(
      id: 'dev_1',
      name: 'Phone',
      deviceType: 'mobile',
      ip: '192.168.1.10',
      httpPort: 53318,
    );

    expect(peer.link, LinkKind.unknown);
  });

  test('copyWith changes the link', () {
    final peer = DevicePeer(
      id: 'dev_1',
      name: 'Phone',
      deviceType: 'mobile',
      ip: '192.168.1.10',
      httpPort: 53318,
    );

    expect(peer.copyWith(link: LinkKind.usb).link, LinkKind.usb);
  });

  test('link metadata is not advertised', () {
    final peer = DevicePeer(
      id: 'dev_1',
      name: 'Phone',
      deviceType: 'mobile',
      ip: '192.168.42.10',
      httpPort: 53318,
      link: LinkKind.usb,
    );

    expect(peer.toJson().containsKey('link'), isFalse);
  });
}
