import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/link_manager.dart';
import 'package:quickdrop/models/link.dart';

class _FakeProvider implements LinkProvider {
  List<LinkInterface> next;
  int calls = 0;

  _FakeProvider(this.next);

  @override
  Future<List<LinkInterface>> discover() async {
    calls++;
    return next;
  }
}

void main() {
  group('SystemNetworkLinkProvider classification', () {
    test('labels tether and LAN interfaces', () {
      expect(SystemNetworkLinkProvider.classify('usb0'), LinkKind.usb);
      expect(SystemNetworkLinkProvider.classify('rndis0'), LinkKind.usb);
      expect(SystemNetworkLinkProvider.classify('bnep0'), LinkKind.bluetooth);
      expect(SystemNetworkLinkProvider.classify('bt-pan'), LinkKind.bluetooth);
      expect(SystemNetworkLinkProvider.classify('wlan0'), LinkKind.wifi);
      expect(SystemNetworkLinkProvider.classify('ap0'), LinkKind.wifi);
      expect(SystemNetworkLinkProvider.classify('eth0'), LinkKind.ethernet);
      expect(
        SystemNetworkLinkProvider.classify('enp0s20u1'),
        LinkKind.ethernet,
      );
      expect(
        SystemNetworkLinkProvider.classify(
          'Remote NDIS based Internet Sharing Device',
        ),
        LinkKind.usb,
      );
      expect(
        SystemNetworkLinkProvider.classify('Bluetooth Network Connection'),
        LinkKind.bluetooth,
      );
      expect(SystemNetworkLinkProvider.classify('Wi-Fi'), LinkKind.wifi);
      expect(
        SystemNetworkLinkProvider.classify('Ethernet 2'),
        LinkKind.ethernet,
      );
      expect(SystemNetworkLinkProvider.classify('mystery0'), LinkKind.unknown);
    });

    test('drops loopback, container, VPN and cellular names', () {
      for (final name in [
        'lo',
        'docker0',
        'veth12',
        'tailscale0',
        'tun0',
        'rmnet0',
        'clat0',
        'vEthernet (WSL)',
        'VMware Network Adapter VMnet1',
      ]) {
        expect(SystemNetworkLinkProvider.isVirtual(name), isTrue, reason: name);
      }
      expect(SystemNetworkLinkProvider.isVirtual('usb0'), isFalse);
      expect(SystemNetworkLinkProvider.isVirtual('bnep0'), isFalse);
      expect(SystemNetworkLinkProvider.isVirtual('Ethernet 2'), isFalse);
      expect(SystemNetworkLinkProvider.isVirtual('Wi-Fi'), isFalse);
    });
  });

  group('LinkManager', () {
    test('sorts by speed and collapses duplicate IPs', () async {
      final provider = _FakeProvider([
        const LinkInterface(
          name: 'bnep0',
          ip: '10.0.0.2',
          kind: LinkKind.bluetooth,
        ),
        const LinkInterface(
          name: 'wlan0',
          ip: '192.168.1.5',
          kind: LinkKind.wifi,
        ),
        const LinkInterface(
          name: 'usb0',
          ip: '192.168.42.5',
          kind: LinkKind.usb,
        ),
        const LinkInterface(
          name: 'rndis0',
          ip: '192.168.42.5',
          kind: LinkKind.usb,
        ),
      ]);
      final manager = LinkManager(provider: provider);
      await manager.refresh();

      expect(manager.links.map((link) => link.kind), [
        LinkKind.usb,
        LinkKind.wifi,
        LinkKind.bluetooth,
      ]);
      expect(manager.links.length, 3);
    });

    test('displayIp prefers Wi-Fi over a USB tether', () async {
      final provider = _FakeProvider([
        const LinkInterface(
          name: 'usb0',
          ip: '192.168.42.5',
          kind: LinkKind.usb,
        ),
        const LinkInterface(
          name: 'wlan0',
          ip: '192.168.1.5',
          kind: LinkKind.wifi,
        ),
      ]);
      final manager = LinkManager(provider: provider);
      await manager.refresh();

      expect(manager.displayIp, '192.168.1.5');
    });

    test('falls back to the tether when Wi-Fi is gone', () async {
      final provider = _FakeProvider([
        const LinkInterface(
          name: 'usb0',
          ip: '192.168.42.5',
          kind: LinkKind.usb,
        ),
      ]);
      final manager = LinkManager(provider: provider);
      await manager.refresh();

      expect(manager.displayIp, '192.168.42.5');
    });

    test('builds broadcast targets and prefixes for every link', () async {
      final provider = _FakeProvider([
        const LinkInterface(
          name: 'usb0',
          ip: '192.168.42.5',
          kind: LinkKind.usb,
        ),
        const LinkInterface(
          name: 'bnep0',
          ip: '10.0.0.5',
          kind: LinkKind.bluetooth,
        ),
      ]);
      final manager = LinkManager(provider: provider);
      await manager.refresh();

      expect(manager.subnetPrefixes, {'192.168.42', '10.0.0'});
      expect(
        manager.broadcastTargets,
        containsAll({
          '192.168.42.255',
          '10.0.0.255',
          '255.255.255.255',
          '224.0.0.167',
        }),
      );
    });

    test('resolves the highest-ranked link for an address', () async {
      final provider = _FakeProvider([
        const LinkInterface(
          name: 'usb0',
          ip: '192.168.42.5',
          kind: LinkKind.usb,
        ),
        const LinkInterface(
          name: 'wlan0',
          ip: '192.168.1.5',
          kind: LinkKind.wifi,
        ),
      ]);
      final manager = LinkManager(provider: provider);
      await manager.refresh();

      expect(manager.linkForIp('192.168.42.9')?.kind, LinkKind.usb);
      expect(manager.linkForIp('192.168.1.9')?.kind, LinkKind.wifi);
      expect(manager.linkForIp('172.16.0.9'), isNull);
    });

    test('recognizes every address that belongs to this device', () async {
      final provider = _FakeProvider([
        const LinkInterface(
          name: 'usb0',
          ip: '192.168.42.5',
          kind: LinkKind.usb,
        ),
        const LinkInterface(
          name: 'wlan0',
          ip: '192.168.1.5',
          kind: LinkKind.wifi,
        ),
      ]);
      final manager = LinkManager(provider: provider);
      await manager.refresh();

      expect(manager.isLocalAddress('192.168.42.5'), isTrue);
      expect(manager.isLocalAddress('192.168.1.5'), isTrue);
      expect(manager.isLocalAddress('192.168.42.9'), isFalse);
    });

    test('notifies only when the set changes', () async {
      final provider = _FakeProvider([
        const LinkInterface(
          name: 'usb0',
          ip: '192.168.42.5',
          kind: LinkKind.usb,
        ),
      ]);
      final manager = LinkManager(provider: provider);
      var notifications = 0;
      manager.linksNotifier.addListener(() => notifications++);

      await manager.refresh();
      await manager.refresh();
      expect(notifications, 1);

      provider.next = const [];
      await manager.refresh();
      expect(notifications, 2);
    });
  });
}
