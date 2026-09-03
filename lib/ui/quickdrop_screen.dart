import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/discovery_service.dart';
import '../core/linux_integrations.dart';
import '../core/share_receiver.dart';
import '../core/transfer_client.dart';
import '../core/transfer_server.dart';
import '../models/device_peer.dart';
import 'components/device_card.dart';
import 'components/manual_connect_dialog.dart';
import 'components/radar_scanner.dart';
import 'components/transfer_history_tile.dart';
import 'quickdrop_theme.dart';

class QuickDropScreen extends StatefulWidget {
  final DiscoveryService discoveryService;
  final TransferServer transferServer;

  const QuickDropScreen({
    super.key,
    required this.discoveryService,
    required this.transferServer,
  });

  @override
  State<QuickDropScreen> createState() => _QuickDropScreenState();
}

class _QuickDropScreenState extends State<QuickDropScreen> {
  String? _sendingPeerId;
  double _uploadProgress = 0.0;
  List<String> _pendingSharePaths = [];

  @override
  void initState() {
    super.initState();
    // Listen for incoming Android share sheet intents
    ShareReceiver.sharedFilesNotifier.addListener(_onSharedFilesChanged);
    _pendingSharePaths = List<String>.from(ShareReceiver.sharedFilesNotifier.value);
  }

  @override
  void dispose() {
    ShareReceiver.sharedFilesNotifier.removeListener(_onSharedFilesChanged);
    super.dispose();
  }

  void _onSharedFilesChanged() {
    if (mounted) {
      setState(() {
        _pendingSharePaths = List<String>.from(ShareReceiver.sharedFilesNotifier.value);
      });
    }
  }

  Future<void> _sendToPeer(DevicePeer peer, {String? specificPath}) async {
    File? fileToSend;

    if (specificPath != null) {
      fileToSend = File(specificPath);
    } else if (_pendingSharePaths.isNotEmpty) {
      fileToSend = File(_pendingSharePaths.first);
    } else {
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked != null && picked.path != null) {
        fileToSend = File(picked.path!);
      }
    }

    if (fileToSend == null || !await fileToSend.exists()) return;
    final fileSize = await fileToSend.length();

    setState(() {
      _sendingPeerId = peer.id;
      _uploadProgress = 0.0;
    });

    final res = await TransferClient.sendPhoto(
      targetPeer: peer,
      file: fileToSend,
      senderName: widget.discoveryService.deviceName,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      },
    );

    if (!mounted) return;

    setState(() {
      _sendingPeerId = null;
      _uploadProgress = 0.0;
    });

    if (res.success) {
      // Clear pending share path once sent
      if (_pendingSharePaths.isNotEmpty) {
        ShareReceiver.clear();
      }

      // Add to transfer server history
      widget.transferServer.addOutgoingHistory(
        TransferItem(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          fileName: fileToSend.path.split(Platform.isWindows ? '\\' : '/').last,
          fileSize: fileSize,
          filePath: fileToSend.path,
          senderName: peer.name,
          isIncoming: false,
          timestamp: DateTime.now(),
          success: true,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✓ ${res.message}! Sent to ${peer.name}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: QuickDropColors.emerald,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✕ ${res.message}'),
          backgroundColor: QuickDropColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAndSendBroadcast() async {
    final peers = widget.discoveryService.peersNotifier.value;
    if (peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No peers discovered yet. Waiting for device on Wi-Fi...'),
          backgroundColor: QuickDropColors.amber,
        ),
      );
      return;
    }

    final picked = await FilePicker.pickFile(type: FileType.image);
    if (!mounted) return;

    if (picked != null && picked.path != null) {
      if (peers.length == 1) {
        await _sendToPeer(peers.first, specificPath: picked.path);
      } else {
        _showPeerSelectionDialog(picked.path!);
      }
    }
  }

  void _showPeerSelectionDialog(String filePath) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: QuickDropColors.surface,
          title: const Text('Select Destination Device',
              style: TextStyle(color: QuickDropColors.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: ValueListenableBuilder<List<DevicePeer>>(
              valueListenable: widget.discoveryService.peersNotifier,
              builder: (context, peers, _) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: peers.length,
                  itemBuilder: (context, i) {
                    final p = peers[i];
                    return ListTile(
                      leading: Icon(
                        p.isDesktop
                            ? Icons.laptop_chromebook_rounded
                            : Icons.phone_android_rounded,
                        color: QuickDropColors.cyan,
                      ),
                      title: Text(p.name,
                          style: const TextStyle(color: QuickDropColors.textPrimary)),
                      subtitle: Text('${p.ip}:${p.httpPort}',
                          style: const TextStyle(color: QuickDropColors.textSecondary)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendToPeer(p, specificPath: filePath);
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: QuickDropColors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: QuickDropColors.cyan.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: QuickDropColors.cyan, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QuickDrop',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: widget.discoveryService.localIpNotifier,
                  builder: (context, ip, _) {
                    return Text(
                      '${widget.discoveryService.deviceName} • $ip',
                      style: const TextStyle(
                        fontSize: 11,
                        color: QuickDropColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Open Screenshots Folder on Linux
          if (Platform.isLinux)
            IconButton(
              tooltip: 'Open Screenshots Folder',
              icon: const Icon(Icons.folder_open_rounded,
                  color: QuickDropColors.textSecondary),
              onPressed: () async {
                final dir = await widget.transferServer.getSaveDirectory();
                await LinuxIntegrations.openFolder(dir.path);
              },
            ),
          // Direct IP Connect Dialog
          IconButton(
            tooltip: 'Direct IP Connect',
            icon: const Icon(Icons.add_link_rounded,
                color: QuickDropColors.textSecondary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ManualConnectDialog(
                  myIp: widget.discoveryService.localIpNotifier.value,
                  myPort: widget.discoveryService.httpPort,
                  onConnect: (ip) {
                    widget.discoveryService.addManualPeer(ip);
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Radar scanner header
                  ValueListenableBuilder<List<DevicePeer>>(
                    valueListenable: widget.discoveryService.peersNotifier,
                    builder: (context, peers, _) {
                      return RadarScanner(
                        isScanning: true,
                        discoveredCount: peers.length,
                        onRefresh: () {
                          widget.discoveryService.broadcastPresence();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Broadcasting discovery beacon...'),
                              duration: Duration(seconds: 1),
                              backgroundColor: QuickDropColors.surfaceLight,
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // 2. Pending Android Share Sheet Banner
                  if (_pendingSharePaths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPendingShareBanner(),
                  ],

                  // 3. Upload Progress Indicator
                  if (_sendingPeerId != null) ...[
                    const SizedBox(height: 16),
                    _buildUploadProgressBar(),
                  ],

                  // 4. Discovered Peers Section
                  const SizedBox(height: 24),
                  const Text(
                    'DISCOVERED PEERS',
                    style: TextStyle(
                      color: QuickDropColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Discovered Peers List
          ValueListenableBuilder<List<DevicePeer>>(
            valueListenable: widget.discoveryService.peersNotifier,
            builder: (context, peers, _) {
              if (peers.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildEmptyPeersCard(),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final peer = peers[index];
                      return DeviceCard(
                        peer: peer,
                        isSending: _sendingPeerId == peer.id,
                        onSend: () => _sendToPeer(peer),
                      );
                    },
                    childCount: peers.length,
                  ),
                ),
              );
            },
          ),

          // Transfer History Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT TRANSFERS',
                    style: TextStyle(
                      color: QuickDropColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (Platform.isLinux)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        final dir = await widget.transferServer.getSaveDirectory();
                        await LinuxIntegrations.openFolder(dir.path);
                      },
                      child: const Text(
                        'Open Folder',
                        style: TextStyle(
                          color: QuickDropColors.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // History List
          ValueListenableBuilder<List<TransferItem>>(
            valueListenable: widget.transferServer.historyNotifier,
            builder: (context, history, _) {
              if (history.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: QuickDropColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: QuickDropColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No screenshots sent or received yet.',
                          style: TextStyle(
                            color: QuickDropColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return TransferHistoryTile(item: history[index]);
                    },
                    childCount: history.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: QuickDropColors.cyan,
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text(
          'Pick Screenshot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _pickAndSendBroadcast,
      ),
    );
  }

  Widget _buildPendingShareBanner() {
    final path = _pendingSharePaths.first;
    final file = File(path);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuickDropColors.indigo.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuickDropColors.indigo.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : const Icon(Icons.image, color: QuickDropColors.indigo),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Screenshot Ready to Beam',
                  style: TextStyle(
                    color: QuickDropColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  path.split(Platform.isWindows ? '\\' : '/').last,
                  style: const TextStyle(
                    color: QuickDropColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.close_rounded,
                color: QuickDropColors.textSecondary, size: 20),
            onPressed: () {
              ShareReceiver.clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuickDropColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Beaming screenshot...',
                style: TextStyle(
                  color: QuickDropColors.cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: QuickDropColors.cyan,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              backgroundColor: QuickDropColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(QuickDropColors.cyan),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPeersCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuickDropColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QuickDropColors.surfaceLight,
              border: Border.all(color: QuickDropColors.border),
            ),
            child: const Icon(
              Icons.devices_other_rounded,
              size: 32,
              color: QuickDropColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No nearby devices detected yet',
            style: TextStyle(
              color: QuickDropColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep QuickDrop open on your other device.\nMake sure both devices are on the same Wi-Fi or phone hotspot.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: QuickDropColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: QuickDropColors.cyan,
              side: const BorderSide(color: QuickDropColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_link_rounded, size: 16),
            label: const Text('Connect via IP manually'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ManualConnectDialog(
                  myIp: widget.discoveryService.localIpNotifier.value,
                  myPort: widget.discoveryService.httpPort,
                  onConnect: (ip) {
                    widget.discoveryService.addManualPeer(ip);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
