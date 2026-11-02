import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/device_peer.dart';
import '../models/link.dart';
import 'app_store.dart';
import 'link_manager.dart';
import 'peer_merge.dart';
import 'transfer_client.dart';

class ManualPeerResult {
  final bool success;
  final String message;

  const ManualPeerResult(this.success, this.message);
}

class DiscoveryService {
  static const int discoveryPort = 53317;
  static const int defaultHttpPort = 53318;
  static const String multicastAddress = '224.0.0.167';

  final String deviceId;
  final int httpPort;
  final LinkManager linkManager;

  String _deviceName;
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;
  Timer? _scanTimer;

  bool _isScanning = false;

  final Map<String, DevicePeer> _peers = {};
  final Set<String> _rememberedHosts = {};
  final List<String> _subnetPrefixes = [];
  final List<String> _broadcastTargets = [];

  final ValueNotifier<List<DevicePeer>> peersNotifier =
      ValueNotifier<List<DevicePeer>>([]);
  final ValueNotifier<String> localIpNotifier = ValueNotifier<String>(
    'Detecting…',
  );
  final ValueNotifier<bool> isScanningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> deviceNameNotifier = ValueNotifier<String>('');

  DiscoveryService({
    String? deviceId,
    String deviceName = '',
    int? httpPort,
    LinkManager? linkManager,
  }) : deviceId =
           deviceId ??
           'dev_${Platform.operatingSystem}_${Random().nextInt(999999)}',
       // ignore: prefer_initializing_formals
       _deviceName = deviceName,
       httpPort = httpPort ?? defaultHttpPort,
       linkManager = linkManager ?? LinkManager() {
    deviceNameNotifier.value = _deviceName;
  }

  String get deviceName => _deviceName;
  String get localIp => localIpNotifier.value;
  bool get isScanning => _isScanning;

  String get webUrl {
    final ip = localIp;
    if (ip == 'Detecting…' || ip.isEmpty) {
      return 'http://localhost:$httpPort/web';
    }
    return 'http://$ip:$httpPort/web';
  }

  Future<void> start() async {
    if (_deviceName.trim().isEmpty) {
      final settings = await AppStore.loadSettings();
      rename(settings.deviceName);
    }

    linkManager.linksNotifier.addListener(_onLinksChanged);
    await _refreshNetwork();
    await _restoreRememberedPeers();
    await _bindSocket();
    linkManager.start();

    _broadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      broadcastPresence();
    });
    _cleanupTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pruneStalePeers();
    });
    _scanTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_peers.isEmpty && !_isScanning) {
        scanSubnet();
      }
    });

    broadcastPresence();

    // UDP is not available on every network. A quick HTTP sweep of the local
    // subnet makes discovery work even when broadcast/multicast is blocked.
    Timer(const Duration(seconds: 2), scanSubnet);
  }

  Future<void> _bindSocket() async {
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
        _socket?.multicastHops = 2;
      } catch (_) {}

      try {
        _socket?.joinMulticast(InternetAddress(multicastAddress));
      } catch (_) {}

      _socket?.listen(
        _handleDatagram,
        onError: (e) {
          debugPrint('[Discovery] Socket error: $e');
        },
      );
    } catch (e) {
      debugPrint('[Discovery] Failed to bind UDP socket: $e');
    }
  }

  Future<void> _refreshNetwork() async {
    await linkManager.refresh();
    _applyLinks();
  }

  void _applyLinks() {
    final links = linkManager.links;
    if (links.isNotEmpty) {
      localIpNotifier.value = linkManager.displayIp;
    }
    _subnetPrefixes
      ..clear()
      ..addAll(linkManager.subnetPrefixes);
    _broadcastTargets
      ..clear()
      ..addAll(linkManager.broadcastTargets);
  }

  void _onLinksChanged() {
    _applyLinks();
    // A tether may have just come up; probe it immediately because some
    // RNDIS/BNEP drivers drop UDP broadcast.
    broadcastPresence();
    unawaited(scanSubnet());
  }

  bool _looksLikeIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final n = int.tryParse(part);
      return n != null && n >= 0 && n <= 255;
    });
  }

  Future<void> _restoreRememberedPeers() async {
    final hosts = await AppStore.loadRememberedPeers();
    _rememberedHosts.addAll(hosts);
    for (final host in hosts) {
      unawaited(_probeRememberedPeer(host));
    }
  }

  Future<void> _probeRememberedPeer(String host) async {
    final target = _parseHost(host);
    if (target == null) return;
    final peer = await TransferClient.probe(target.$1, port: target.$2);
    if (peer != null && peer.id != deviceId) {
      final link = linkManager.linkForIp(target.$1);
      _peers[peer.id] = mergePeerObservation(
        _peers[peer.id],
        peer.copyWith(isManual: true),
        link?.kind ?? LinkKind.unknown,
      );
      _updatePeerList();
    }
  }

  (String, int)? _parseHost(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    value = value.split('/').first;
    var port = httpPort;
    if (value.contains(':')) {
      final pieces = value.split(':');
      if (pieces.length == 2) {
        value = pieces[0];
        port = int.tryParse(pieces[1]) ?? httpPort;
      }
    }
    if (!_looksLikeIpv4(value)) return null;
    return (value, port);
  }

  Future<ManualPeerResult> addManualPeer(String input) async {
    final target = _parseHost(input);
    if (target == null) {
      return const ManualPeerResult(
        false,
        'Enter a valid IPv4 address, e.g. 192.168.1.42',
      );
    }

    final host = '${target.$1}:${target.$2}';
    final peer = await TransferClient.probe(target.$1, port: target.$2);
    if (peer == null) {
      return ManualPeerResult(
        false,
        'No QuickDrop receiver answered at $host. Check the IP and firewall.',
      );
    }
    if (peer.id == deviceId) {
      return const ManualPeerResult(
        false,
        'That address belongs to this device.',
      );
    }

    final manual = peer.copyWith(isManual: true, lastSeen: DateTime.now());
    _peers[manual.id] = mergePeerObservation(
      _peers[manual.id],
      manual,
      linkManager.linkForIp(target.$1)?.kind ?? LinkKind.unknown,
    );
    _rememberedHosts.add(host);
    await AppStore.saveRememberedPeers(_rememberedHosts.toList());
    _updatePeerList();
    broadcastPresence();
    return ManualPeerResult(true, 'Connected to ${peer.name}');
  }

  void forgetPeer(String id) {
    _peers.remove(id);
    _updatePeerList();
  }

  void rename(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _deviceName) return;
    _deviceName = trimmed;
    deviceNameNotifier.value = trimmed;
    broadcastPresence();
  }

  Future<void> refreshNetwork() async {
    await _refreshNetwork();
    broadcastPresence();
    await scanSubnet();
  }

  Future<void> broadcastPresence() async {
    final socket = _socket;
    if (socket == null) return;
    try {
      final payload = jsonEncode({
        'protocol': 'quickdrop_v1',
        'id': deviceId,
        'name': deviceName,
        'device_type': _deviceType,
        'ip': localIp,
        'http_port': httpPort,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final bytes = utf8.encode(payload);

      if (_broadcastTargets.isEmpty) {
        await _refreshNetwork();
      }

      for (final target in _broadcastTargets) {
        try {
          socket.send(bytes, InternetAddress(target), discoveryPort);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[Discovery] Broadcast error: $e');
    }
  }

  /// Probes the local /24 over HTTP. This is the offline fallback for routers,
  /// hotspots and Android devices that silently drop UDP broadcasts.
  Future<void> scanSubnet() async {
    if (_isScanning || _subnetPrefixes.isEmpty) return;
    _isScanning = true;
    isScanningNotifier.value = true;

    final targets = <String>[];
    for (final prefix in _subnetPrefixes) {
      for (var host = 1; host <= 254; host++) {
        final ip = '$prefix.$host';
        if (linkManager.isLocalAddress(ip)) continue;
        targets.add(ip);
      }
    }

    try {
      var cursor = 0;
      final workerCount = min(48, targets.length);
      final workers = List.generate(workerCount, (_) async {
        while (true) {
          final index = cursor++;
          if (index >= targets.length) return;
          final peer = await TransferClient.probe(
            targets[index],
            port: httpPort,
            timeout: const Duration(milliseconds: 450),
          );
          if (peer != null && peer.id != deviceId) {
            final link = linkManager.linkForIp(targets[index]);
            _peers[peer.id] = mergePeerObservation(
              _peers[peer.id],
              peer,
              link?.kind ?? LinkKind.unknown,
            );
            _updatePeerList();
          }
        }
      });
      await Future.wait(workers);
    } finally {
      _isScanning = false;
      isScanningNotifier.value = false;
    }
  }

  void _handleDatagram(RawSocketEvent event) {
    final socket = _socket;
    if (event != RawSocketEvent.read || socket == null) return;
    final datagram = socket.receive();
    if (datagram == null) return;

    try {
      final map =
          jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      if (map['protocol'] != 'quickdrop_v1') return;
      final remoteId = map['id'] as String?;
      if (remoteId == null || remoteId == deviceId) return;

      final senderIp = datagram.address.address;
      final existing = _peers[remoteId];
      final peer = DevicePeer.fromJson(map, senderIp);
      final link = linkManager.linkForIp(senderIp);

      _peers[peer.id] = mergePeerObservation(
        existing,
        peer,
        link?.kind ?? LinkKind.unknown,
      );
      _broadcastTargets.add(senderIp);
      _updatePeerList();
    } catch (_) {
      // Ignore malformed discovery packets.
    }
  }

  void _pruneStalePeers() {
    final now = DateTime.now();
    bool changed = false;
    _peers.removeWhere((_, peer) {
      if (peer.isManual) {
        // Manual peers stay until the user removes them, but get re-probed.
        if (now.difference(peer.lastSeen).inSeconds > 20) {
          peer.lastSeen = now;
          unawaited(_reprobeManualPeer(peer));
        }
        return false;
      }
      final stale = now.difference(peer.lastSeen).inSeconds > 10;
      if (stale) changed = true;
      return stale;
    });
    if (changed) _updatePeerList();
  }

  Future<void> _reprobeManualPeer(DevicePeer peer) async {
    final result = await TransferClient.probe(peer.ip, port: peer.httpPort);
    if (result == null || result.id == deviceId) {
      _peers.remove(peer.id);
      _updatePeerList();
    } else {
      _peers[result.id] = mergePeerObservation(
        _peers[result.id],
        result.copyWith(isManual: true),
        linkManager.linkForIp(peer.ip)?.kind ?? LinkKind.unknown,
      );
      if (result.id != peer.id) _peers.remove(peer.id);
      _updatePeerList();
    }
  }

  void _updatePeerList() {
    peersNotifier.value = sortPeers(_peers.values);
  }

  String get _deviceType =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows
      ? 'desktop'
      : 'mobile';

  void stop() {
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _scanTimer?.cancel();
    linkManager.linksNotifier.removeListener(_onLinksChanged);
    linkManager.stop();
    _socket?.close();
    _socket = null;
  }
}
