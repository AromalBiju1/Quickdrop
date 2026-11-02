import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/peer_merge.dart';
import 'package:quickdrop/models/device_peer.dart';
import 'package:quickdrop/models/link.dart';

DevicePeer _peer({
  String id = 'dev_1',
  String name = 'Phone',
  String ip = '192.168.1.10',
  bool manual = false,
  LinkKind link = LinkKind.wifi,
}) {
  return DevicePeer(
    id: id,
    name: name,
    deviceType: 'mobile',
    ip: ip,
    httpPort: 53318,
    isManual: manual,
    link: link,
  );
}

void main() {
  test('first observation records its link', () {
    final merged = mergePeerObservation(null, _peer(), LinkKind.usb);

    expect(merged.link, LinkKind.usb);
  });

  test('a faster link replaces the address', () {
    final merged = mergePeerObservation(
      _peer(ip: '192.168.1.10', link: LinkKind.wifi),
      _peer(ip: '192.168.42.10'),
      LinkKind.usb,
    );

    expect(merged.link, LinkKind.usb);
    expect(merged.ip, '192.168.42.10');
  });

  test('a slower link keeps the faster address but refreshes lastSeen', () {
    final oldSeen = DateTime.now().subtract(const Duration(minutes: 1));
    final existing = _peer(ip: '192.168.42.10', link: LinkKind.usb)
      ..lastSeen = oldSeen;

    final merged = mergePeerObservation(
      existing,
      _peer(ip: '192.168.1.10'),
      LinkKind.wifi,
    );

    expect(merged.link, LinkKind.usb);
    expect(merged.ip, '192.168.42.10');
    expect(merged.lastSeen.isAfter(oldSeen), isTrue);
  });

  test('equal links take the newest observation', () {
    final merged = mergePeerObservation(
      _peer(ip: '192.168.1.10', link: LinkKind.wifi),
      _peer(ip: '192.168.1.11'),
      LinkKind.wifi,
    );

    expect(merged.ip, '192.168.1.11');
  });

  test('manual status survives every observation', () {
    final merged = mergePeerObservation(
      _peer(manual: true, link: LinkKind.wifi),
      _peer(ip: '192.168.42.10'),
      LinkKind.usb,
    );

    expect(merged.isManual, isTrue);
    expect(merged.link, LinkKind.usb);
  });

  test('peer list sorts manual last, then by link speed and name', () {
    final sorted = sortPeers([
      _peer(id: 'manual', name: 'Adam', manual: true, link: LinkKind.usb),
      _peer(id: 'bt', name: 'Zed', link: LinkKind.bluetooth),
      _peer(id: 'wifi-b', name: 'Beta', link: LinkKind.wifi),
      _peer(id: 'wifi-a', name: 'Alpha', link: LinkKind.wifi),
      _peer(id: 'usb', name: 'Zulu', link: LinkKind.usb),
    ]);

    expect(sorted.map((peer) => peer.id), [
      'usb',
      'wifi-a',
      'wifi-b',
      'bt',
      'manual',
    ]);
  });
}
