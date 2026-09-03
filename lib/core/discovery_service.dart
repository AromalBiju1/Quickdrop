import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/device_peer.dart';

class DiscoveryService {
  static const int discoveryPort = 53317;
  static const int defaultHttpPort = 53318;
  static const String multicastAddress = '224.0.0.167';

  final String deviceId;
  final String deviceName;
  final String deviceType;
  final int httpPort;

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  final Map<String, DevicePeer> _peers = {};
  final ValueNotifier<List<DevicePeer>> peersNotifier = ValueNotifier<List<DevicePeer>>([]);
  final ValueNotifier<String> localIpNotifier = ValueNotifier<String>('Detecting...');

  DiscoveryService({
    String? deviceId,
    String? deviceName,
    int? httpPort,
  })  : deviceId = deviceId ?? 'dev_${Platform.operatingSystem}_${Random().nextInt(999999)}',
        deviceName = deviceName ?? _getDefaultDeviceName(),
        deviceType = Platform.isLinux || Platform.isMacOS || Platform.isWindows ? 'desktop' : 'mobile',
        httpPort = httpPort ?? defaultHttpPort;

  static String _getDefaultDeviceName() {
    try {
      final host = Platform.localHostname;
      if (host.isNotEmpty && host != 'localhost') {
        return Platform.isLinux ? '$host (Linux)' : host;
      }
    } catch (_) {}
    return Platform.isLinux ? 'Linux Laptop' : 'Android Phone';
  }

  Future<void> start() async {
    await _detectLocalIp();

    try {
      try {
        _socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          discoveryPort,
          reuseAddress: true,
          reusePort: false,
        );
      } catch (_) {
        _socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          0,
          reuseAddress: true,
        );
      }
      _socket?.broadcastEnabled = true;
      _socket?.multicastLoopback = false;

      try {
        _socket?.joinMulticast(InternetAddress(multicastAddress));
      } catch (_) {}

      _socket?.listen(_handleDatagram, onError: (e) {
        debugPrint('[Discovery] Socket error: $e');
      });

      // Periodic broadcast
      _broadcastTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        broadcastPresence();
      });

      // Periodic pruning of stale peers
      _cleanupTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _pruneStalePeers();
      });

      // Immediate first broadcast
      broadcastPresence();
    } catch (e) {
      debugPrint('[Discovery] Failed to bind UDP socket: $e');
    }
  }

  Future<void> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.isNotEmpty) {
            localIpNotifier.value = addr.address;
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[Discovery] Failed to detect IP: $e');
    }
  }

  Future<List<String>> _getBroadcastAddresses() async {
    final list = <String>{'255.255.255.255', multicastAddress};
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              list.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
            }
          }
        }
      }
    } catch (_) {}
    return list.toList();
  }

  Future<void> broadcastPresence() async {
    if (_socket == null) return;
    try {
      final myIp = localIpNotifier.value != 'Detecting...' ? localIpNotifier.value : '';
      final payload = jsonEncode({
        'protocol': 'quickdrop_v1',
        'id': deviceId,
        'name': deviceName,
        'device_type': deviceType,
        'ip': myIp,
        'http_port': httpPort,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final bytes = utf8.encode(payload);
      final targets = await _getBroadcastAddresses();

      for (final target in targets) {
        try {
          _socket?.send(bytes, InternetAddress(target), discoveryPort);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[Discovery] Broadcast error: $e');
    }
  }

  void _handleDatagram(RawSocketEvent event) {
    if (event != RawSocketEvent.read || _socket == null) return;
    final datagram = _socket!.receive();
    if (datagram == null) return;

    try {
      final text = utf8.decode(datagram.data);
      final map = jsonDecode(text) as Map<String, dynamic>;

      if (map['protocol'] != 'quickdrop_v1') return;
      final remoteId = map['id'] as String?;
      if (remoteId == null || remoteId == deviceId) return; // Ignore self

      final senderIp = datagram.address.address;
      final peer = DevicePeer.fromJson(map, senderIp);

      _peers[peer.id] = peer;
      _updatePeerList();
    } catch (_) {
      // Ignore malformed packet
    }
  }

  void _pruneStalePeers() {
    final now = DateTime.now();
    bool changed = false;
    _peers.removeWhere((id, peer) {
      final isStale = now.difference(peer.lastSeen).inSeconds > 8;
      if (isStale) changed = true;
      return isStale;
    });
    if (changed) {
      _updatePeerList();
    }
  }

  void _updatePeerList() {
    peersNotifier.value = _peers.values.toList();
  }

  void addManualPeer(String ip, {int port = defaultHttpPort, String? name}) {
    final id = 'manual_$ip';
    final peer = DevicePeer(
      id: id,
      name: name ?? 'Device ($ip)',
      deviceType: 'unknown',
      ip: ip,
      httpPort: port,
      lastSeen: DateTime.now().add(const Duration(minutes: 60)),
    );
    _peers[id] = peer;
    _updatePeerList();
  }

  void stop() {
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}
