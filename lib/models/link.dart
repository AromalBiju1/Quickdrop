enum LinkKind { wifi, usb, bluetooth, ethernet, unknown }

extension LinkKindX on LinkKind {
  String get label => switch (this) {
        LinkKind.wifi => 'Wi-Fi',
        LinkKind.usb => 'USB',
        LinkKind.bluetooth => 'Bluetooth',
        LinkKind.ethernet => 'Wired',
        LinkKind.unknown => 'Network',
      };

  /// Preference used when the same device is reachable on several links.
  int get rank => switch (this) {
        LinkKind.usb => 400,
        LinkKind.ethernet => 300,
        LinkKind.wifi => 200,
        LinkKind.bluetooth => 100,
        LinkKind.unknown => 50,
      };

  /// Preference used for the address shown to browsers. A browser on another
  /// device usually reaches the LAN address, not a point-to-point tether.
  int get displayRank => switch (this) {
        LinkKind.wifi => 500,
        LinkKind.ethernet => 400,
        LinkKind.usb => 300,
        LinkKind.bluetooth => 200,
        LinkKind.unknown => 100,
      };
}

/// One usable IPv4 interface that discovery and transfers can run on.
class LinkInterface {
  final String name;
  final String ip;
  final LinkKind kind;

  const LinkInterface({
    required this.name,
    required this.ip,
    required this.kind,
  });

  int get rank => kind.rank;

  int get displayRank => kind.displayRank;

  /// The /24 network prefix, e.g. `192.168.31` for `192.168.31.65`.
  String get prefix {
    final parts = ip.split('.');
    if (parts.length != 4) return ip;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  /// Broadcast address for the /24, e.g. `192.168.31.255`.
  String get broadcast => '$prefix.255';

  bool sharesSubnet(String otherIp) {
    final parts = otherIp.split('.');
    if (parts.length != 4) return false;
    return '${parts[0]}.${parts[1]}.${parts[2]}' == prefix;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkInterface &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          ip == other.ip &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(name, ip, kind);

  @override
  String toString() => 'LinkInterface($name, $ip, ${kind.name})';
}
