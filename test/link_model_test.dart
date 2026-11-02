import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/models/link.dart';

void main() {
  group('LinkKind', () {
    test('ranks fast links above slow ones', () {
      expect(LinkKind.usb.rank, greaterThan(LinkKind.ethernet.rank));
      expect(LinkKind.ethernet.rank, greaterThan(LinkKind.wifi.rank));
      expect(LinkKind.wifi.rank, greaterThan(LinkKind.bluetooth.rank));
      expect(LinkKind.bluetooth.rank, greaterThan(LinkKind.unknown.rank));
    });

    test('has human labels', () {
      expect(LinkKind.wifi.label, 'Wi-Fi');
      expect(LinkKind.usb.label, 'USB');
      expect(LinkKind.bluetooth.label, 'Bluetooth');
      expect(LinkKind.ethernet.label, 'Wired');
      expect(LinkKind.unknown.label, 'Network');
    });

    test('display preference keeps the LAN address first', () {
      expect(LinkKind.wifi.displayRank, greaterThan(LinkKind.ethernet.displayRank));
      expect(LinkKind.ethernet.displayRank, greaterThan(LinkKind.usb.displayRank));
      expect(LinkKind.usb.displayRank, greaterThan(LinkKind.bluetooth.displayRank));
    });
  });

  group('LinkInterface', () {
    const link = LinkInterface(name: 'usb0', ip: '192.168.42.65', kind: LinkKind.usb);

    test('derives /24 prefix and broadcast', () {
      expect(link.prefix, '192.168.42');
      expect(link.broadcast, '192.168.42.255');
    });

    test('matches addresses on the same /24 only', () {
      expect(link.sharesSubnet('192.168.42.234'), isTrue);
      expect(link.sharesSubnet('192.168.43.234'), isFalse);
      expect(link.sharesSubnet('not-an-ip'), isFalse);
    });

    test('uses kind rank as score', () {
      expect(link.rank, LinkKind.usb.rank);
    });

    test('equality includes name, address and kind', () {
      expect(
        link,
        const LinkInterface(name: 'usb0', ip: '192.168.42.65', kind: LinkKind.usb),
      );
      expect(
        link,
        isNot(const LinkInterface(
          name: 'usb0',
          ip: '192.168.42.65',
          kind: LinkKind.wifi,
        )),
      );
    });
  });
}
