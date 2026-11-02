import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/link.dart';

/// Supplies the set of interfaces discovery may use.
///
/// Keeping this behind an interface leaves room for future providers (direct
/// USB, RFCOMM, tunnels) without touching discovery or transfer.
abstract class LinkProvider {
  Future<List<LinkInterface>> discover();
}

/// Reads the OS network interfaces and labels the ones that can carry
/// QuickDrop traffic.
class SystemNetworkLinkProvider implements LinkProvider {
  const SystemNetworkLinkProvider();

  static const Set<String> _virtualPrefixes = {
    'lo',
    'docker',
    'veth',
    'br-',
    'virbr',
    'vmnet',
    'vboxnet',
    'zt',
    'tailscale',
    'tun',
    'tap',
    'wg',
    'utun',
    'ham',
    // Cellular links are not reachable from another local device and can
    // report carrier-internal addresses such as 192.0.0.2.
    'rmnet',
    'ccmni',
    'pdp',
    'wwan',
    'clat',
    'dummy',
  };

  @override
  Future<List<LinkInterface>> discover() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    final byIp = <String, LinkInterface>{};
    for (final iface in interfaces) {
      final name = iface.name;
      final lower = name.toLowerCase();
      if (isVirtual(lower)) continue;
      final kind = classify(lower);
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        if (!_looksLikeIpv4(addr.address)) continue;
        byIp.putIfAbsent(
          addr.address,
          () => LinkInterface(name: name, ip: addr.address, kind: kind),
        );
      }
    }
    return byIp.values.toList();
  }

  static bool isVirtual(String interfaceName) {
    final name = interfaceName.toLowerCase();
    return _virtualPrefixes.any(name.startsWith);
  }

  /// Name-based classification. Misnamed interfaces still work as `unknown`.
  static LinkKind classify(String interfaceName) {
    final name = interfaceName.toLowerCase();
    if (name.startsWith('usb') || name.startsWith('rndis')) {
      return LinkKind.usb;
    }
    if (name.startsWith('bnep') ||
        name.startsWith('bt-pan') ||
        name.startsWith('btpan')) {
      return LinkKind.bluetooth;
    }
    if (name.startsWith('wlan') ||
        name.startsWith('wl') ||
        name.startsWith('ap') ||
        name.startsWith('swlan')) {
      return LinkKind.wifi;
    }
    if (name.startsWith('en') || name.startsWith('eth')) {
      return LinkKind.ethernet;
    }
    return LinkKind.unknown;
  }

  static bool _looksLikeIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final n = int.tryParse(part);
      return n != null && n >= 0 && n <= 255;
    });
  }
}

/// Owns the current link set and refreshes it as tethering comes and goes.
class LinkManager {
  static const int multicastPort = 53317;

  final LinkProvider provider;
  final Duration pollInterval;

  final ValueNotifier<List<LinkInterface>> linksNotifier =
      ValueNotifier<List<LinkInterface>>(const []);

  Timer? _timer;
  bool _started = false;

  LinkManager({
    LinkProvider? provider,
    this.pollInterval = const Duration(seconds: 4),
  }) : provider = provider ?? const SystemNetworkLinkProvider();

  List<LinkInterface> get links => linksNotifier.value;

  /// Address shown in the receiver URL. Prefers the LAN-facing link.
  String get displayIp {
    if (links.isEmpty) return 'Detecting…';
    final sorted = List<LinkInterface>.of(links)
      ..sort((a, b) {
        final byPreference = b.displayRank.compareTo(a.displayRank);
        if (byPreference != 0) return byPreference;
        return a.ip.compareTo(b.ip);
      });
    return sorted.first.ip;
  }

  Set<String> get subnetPrefixes => links.map((link) => link.prefix).toSet();

  Set<String> get broadcastTargets => {
        for (final link in links) link.broadcast,
        '255.255.255.255',
        '224.0.0.167',
      };

  Future<void> refresh() async {
    try {
      final discovered = await provider.discover();
      final byIp = <String, LinkInterface>{};
      for (final link in discovered) {
        if (!_looksLikeIpv4(link.ip)) continue;
        byIp.putIfAbsent(link.ip, () => link);
      }
      final sorted = byIp.values.toList()
        ..sort((a, b) {
          final byRank = b.rank.compareTo(a.rank);
          if (byRank != 0) return byRank;
          return a.ip.compareTo(b.ip);
        });
      if (!listEquals(sorted, links)) {
        linksNotifier.value = List<LinkInterface>.unmodifiable(sorted);
      }
    } catch (e) {
      debugPrint('[Links] Failed to inspect interfaces: $e');
    }
  }

  /// Highest-ranked link whose /24 contains [ip].
  LinkInterface? linkForIp(String ip) {
    LinkInterface? best;
    for (final link in links) {
      if (!link.sharesSubnet(ip)) continue;
      if (best == null || link.rank > best.rank) best = link;
    }
    return best;
  }

  bool isLocalAddress(String ip) => links.any((link) => link.ip == ip);

  void start() {
    if (_started) return;
    _started = true;
    unawaited(refresh());
    _timer = Timer.periodic(pollInterval, (_) {
      unawaited(refresh());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  void dispose() {
    stop();
    linksNotifier.dispose();
  }

  static bool _looksLikeIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final n = int.tryParse(part);
      return n != null && n >= 0 && n <= 255;
    });
  }
}
