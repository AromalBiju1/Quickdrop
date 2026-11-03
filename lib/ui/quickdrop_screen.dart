import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_store.dart';
import '../core/discovery_service.dart';
import '../core/file_utils.dart';
import '../core/linux_integrations.dart';
import '../core/platform_integrations.dart';
import '../core/quickdrop_controller.dart';
import '../core/transfer_server.dart';
import '../models/device_peer.dart';
import 'components/active_transfer_panel.dart';
import 'components/device_card.dart';
import 'components/file_thumb.dart';
import 'components/help_dialog.dart';
import 'components/manual_connect_dialog.dart';
import 'components/offline_link_dialog.dart';
import 'components/qr_dialog.dart';
import 'components/receive_card.dart';
import 'components/send_panel.dart';
import 'components/send_result_panel.dart';
import 'components/settings_dialog.dart';
import 'components/top_notice.dart';
import 'components/transfer_history_tile.dart';
import 'quickdrop_theme.dart';
import 'transfer_notices.dart';

class QuickDropScreen extends StatefulWidget {
  final DiscoveryService discoveryService;
  final TransferServer transferServer;
  final AppSettings settings;

  const QuickDropScreen({
    super.key,
    required this.discoveryService,
    required this.transferServer,
    required this.settings,
  });

  @override
  State<QuickDropScreen> createState() => _QuickDropScreenState();
}

class _QuickDropScreenState extends State<QuickDropScreen> {
  late final QuickDropController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _dragging = false;
  int _tab = 0;
  int _historyFilter = 0;
  SendSummary? _lastSummary;
  final Set<String> _seenIncomingIds = {};
  final Map<String, TransferItem> _pendingIncoming = {};
  Timer? _receiveNoticeTimer;

  @override
  void initState() {
    super.initState();
    _controller = QuickDropController(
      discovery: widget.discoveryService,
      server: widget.transferServer,
      settings: widget.settings,
    );
    _controller.summaryNotifier.addListener(_onSendSummary);
    _seenIncomingIds.addAll(
      widget.transferServer.historyNotifier.value
          .where((item) => item.isIncoming && item.success)
          .map((item) => item.id),
    );
    widget.transferServer.historyNotifier.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    _controller.summaryNotifier.removeListener(_onSendSummary);
    widget.transferServer.historyNotifier.removeListener(_onHistoryChanged);
    _receiveNoticeTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSendSummary() {
    final summary = _controller.summaryNotifier.value;
    if (summary == null) return;
    _controller.summaryNotifier.value = null;
    if (!mounted) return;
    setState(() => _lastSummary = summary);
    _showNotice(
      buildSendNotice(
        summary,
        onView: () => _viewAllTransfers(filter: 1),
      ),
    );
  }

  void _onHistoryChanged() {
    final items = widget.transferServer.historyNotifier.value;
    final fresh = <TransferItem>[];
    for (final item in items) {
      if (!item.isIncoming || !item.success) continue;
      if (_seenIncomingIds.add(item.id)) fresh.add(item);
    }
    if (fresh.isEmpty) return;

    for (final item in fresh) {
      _pendingIncoming[item.id] = item;
    }
    _receiveNoticeTimer?.cancel();
    _receiveNoticeTimer = Timer(
      const Duration(milliseconds: 700),
      _flushReceiveNotice,
    );
  }

  void _flushReceiveNotice() {
    if (!mounted || _pendingIncoming.isEmpty) return;
    final items = _pendingIncoming.values.toList();
    _pendingIncoming.clear();
    _showNotice(
      buildReceiveNotice(
        items,
        onView: () => _viewAllTransfers(filter: 2),
      ),
    );
  }

  void _showNotice(TopNotice notice) {
    if (!mounted) return;
    showTopNotice(context, notice);
  }

  Future<void> _pickFiles({bool imagesOnly = false}) async {
    final result = await _controller.pickFiles(imagesOnly: imagesOnly);
    if (!mounted) return;
    if (result.added > 0) {
      setState(() => _lastSummary = null);
      _notify(
        '${result.added} file${result.added == 1 ? '' : 's'} ready to send',
        icon: Icons.attach_file_rounded,
        tone: TopNoticeTone.success,
      );
    } else if (result.skipped > 0) {
      _notify(
        'Some files could not be added',
        icon: Icons.warning_amber_rounded,
        tone: TopNoticeTone.warning,
      );
    }
  }

  Future<void> _addPaths(List<String> paths) async {
    final result = await _controller.addPaths(paths);
    if (!mounted) return;
    if (result.added > 0) {
      setState(() => _lastSummary = null);
      _notify(
        '${result.added} file${result.added == 1 ? '' : 's'} added',
        icon: Icons.add_rounded,
        tone: TopNoticeTone.success,
      );
    }
  }

  Future<void> _sendToPeer(DevicePeer peer) async {
    _controller.selectPeer(peer);
    if (!_controller.hasSelection) {
      await _controller.pickFiles();
      if (!_controller.hasSelection) return;
    }
    if (!mounted) return;
    setState(() => _lastSummary = null);
    await _controller.sendToPeer(peer);
  }

  void _sendSelected() {
    final peer = _controller.selectedPeer;
    if (peer == null) return;
    setState(() => _lastSummary = null);
    _controller.sendToPeer(peer);
  }

  Future<void> _openManualConnect() async {
    final result = await showDialog<ManualPeerResult>(
      context: context,
      builder: (context) =>
          ManualConnectDialog(discovery: _controller.discovery),
    );
    if (!mounted || result == null) return;
    _notify(
      result.message,
      icon: result.success ? Icons.link_rounded : Icons.error_outline_rounded,
      tone: result.success ? TopNoticeTone.success : TopNoticeTone.error,
    );
  }

  Future<void> _openSettings() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => SettingsDialog(
        controller: _controller,
        onOpenFolder: _openReceivedFolder,
      ),
    );
    if (saved == true && mounted) {
      _notify(
        'Settings saved',
        icon: Icons.check_rounded,
        tone: TopNoticeTone.success,
      );
    }
  }

  void _openHelp() {
    showDialog(
      context: context,
      builder: (context) => HelpDialog(discovery: _controller.discovery),
    );
  }

  void _openOfflineLinks() {
    showDialog(
      context: context,
      builder: (context) =>
          OfflineLinkDialog(linkManager: _controller.discovery.linkManager),
    );
  }

  Future<void> _openBrowser() async {
    final opened = await PlatformIntegrations.openUrl(_controller.webUrl);
    if (!opened && mounted) {
      _notify(
        'Open ${_controller.webUrl} on the other device',
        icon: Icons.language_rounded,
        tone: TopNoticeTone.info,
      );
    }
  }

  void _showQr() {
    showDialog(
      context: context,
      builder: (context) => QrDialog(
        webUrl: _controller.webUrl,
        deviceName: _controller.settings.deviceName,
        onOpenBrowser: () {
          Navigator.pop(context);
          _openBrowser();
        },
      ),
    );
  }

  Future<void> _openReceivedFolder() async {
    if (Platform.isAndroid) {
      final opened = await PlatformIntegrations.openDownloads();
      if (!mounted) return;
      if (!opened) {
        _notify(
          'Received files: Download/QuickDrop',
          icon: Icons.folder_rounded,
          tone: TopNoticeTone.info,
        );
      }
      return;
    }
    final dir = await _controller.server.getLastSaveDirectory();
    if (!mounted) return;
    if (Platform.isLinux) {
      await LinuxIntegrations.openFolder(dir.path);
    } else {
      _notify(
        'Received files: ${dir.path}',
        icon: Icons.folder_rounded,
        tone: TopNoticeTone.info,
      );
    }
  }

  Future<void> _confirmClearHistory() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Clear transfer history?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        content: const Text(
          'This only clears the list. Files already received stay on disk.',
          style: TextStyle(
            color: QuickDropColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: QuickDropColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: QuickDropColors.rose,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 42),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear == true) {
      _controller.clearHistory();
      if (mounted) {
        _notify(
          'History cleared',
          icon: Icons.delete_outline_rounded,
          tone: TopNoticeTone.info,
        );
      }
    }
  }

  Future<void> _confirmCancelTransfer() async {
    final progress = _controller.progress;
    final canceled = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cancel transfer?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        content: Text(
          progress == null
              ? 'Files already delivered stay on the other device.'
              : '${FileUtils.formatBytes(progress.sentBytes)} of ${FileUtils.formatBytes(progress.totalBytes)} already sent. Files already delivered stay on the other device.',
          style: const TextStyle(
            color: QuickDropColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: QuickDropColors.textSecondary,
            ),
            child: const Text('Keep transferring'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: QuickDropColors.rose,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 42),
            ),
            child: const Text('Cancel transfer'),
          ),
        ],
      ),
    );
    if (canceled == true) _controller.cancelTransfer();
  }

  void _selectTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _viewAllTransfers({int filter = 0}) {
    setState(() {
      _historyFilter = filter;
      _tab = 2;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _notify(
    String message, {
    IconData icon = Icons.info_outline_rounded,
    TopNoticeTone tone = TopNoticeTone.success,
    String? detail,
  }) {
    _showNotice(
      TopNotice(
        message: message,
        detail: detail,
        icon: icon,
        tone: tone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuickDropColors.background,
      body: SafeArea(
        bottom: false,
        child: DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: (details) async {
            setState(() => _dragging = false);
            await _addPaths(details.files.map((file) => file.path).toList());
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final width = MediaQuery.sizeOf(context).width;
              final compact = width < 820;
              final twoColumn = width >= 980;
              final peers = _controller.discovery.peersNotifier.value;

              return Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(compact, peers, width),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            compact ? 16 : 32,
                            compact ? 20 : 28,
                            compact ? 16 : 32,
                            compact ? 28 : 40,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: _buildTabContent(twoColumn),
                            ),
                          ),
                        ),
                      ),
                      if (compact) _buildBottomNav(),
                    ],
                  ),
                  if (_dragging) _buildDropOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact, List<DevicePeer> peers, double width) {
    final running = _controller.server.isRunningNotifier.value;
    final scanning = _controller.discovery.isScanningNotifier.value;

    String status;
    Color statusFg;
    Color statusBg;
    if (!running) {
      status = compact ? 'Offline' : 'Receiver offline';
      statusFg = QuickDropColors.roseDark;
      statusBg = QuickDropColors.roseSoft;
    } else if (peers.isNotEmpty) {
      status = compact
          ? '${peers.length} nearby'
          : '${peers.length} device${peers.length == 1 ? '' : 's'} nearby';
      statusFg = QuickDropColors.emeraldDark;
      statusBg = QuickDropColors.emeraldSoft;
    } else if (scanning) {
      status = compact ? 'Scanning' : 'Scanning nearby';
      statusFg = QuickDropColors.emeraldDark;
      statusBg = QuickDropColors.emeraldSoft;
    } else {
      status = compact ? 'Ready' : 'Ready to receive';
      statusFg = QuickDropColors.emeraldDark;
      statusBg = QuickDropColors.emeraldSoft;
    }

    return Container(
      decoration: const BoxDecoration(
        color: QuickDropColors.surface,
        border: Border(bottom: BorderSide(color: QuickDropColors.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      height: compact ? 64 : 72,
      child: Row(
        children: [
          const QuickDropLogo(size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QuickDrop',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: QuickDropColors.textPrimary,
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                if (!compact)
                  const Text(
                    'Local file transfer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: QuickDropColors.textMuted,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          if (!compact) ...[const SizedBox(width: 20), _buildDesktopNav()],
          const SizedBox(width: 8),
          StatusPill(label: status, foreground: statusFg, background: statusBg),
          const SizedBox(width: 6),
          _headerIcon(
            icon: Icons.help_outline_rounded,
            tooltip: 'Offline & connection help',
            onTap: _openHelp,
          ),
          _headerIcon(
            icon: Icons.tune_rounded,
            tooltip: 'Settings',
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNav() {
    const labels = ['Send', 'Receive', 'Transfers'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: QuickDropColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _selectTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _tab == i
                      ? QuickDropColors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _tab == i
                        ? QuickDropColors.border
                        : Colors.transparent,
                  ),
                  boxShadow: _tab == i ? QuickDropColors.cardShadow : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: _tab == i
                        ? QuickDropColors.textPrimary
                        : QuickDropColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          maximumSize: const Size(36, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: Icon(icon, size: 19, color: QuickDropColors.textSecondary),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (label: 'Send', icon: Icons.near_me_rounded),
      (label: 'Receive', icon: Icons.download_for_offline_rounded),
      (label: 'Transfers', icon: Icons.sync_alt_rounded),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: QuickDropColors.surface,
        border: Border(top: BorderSide(color: QuickDropColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTab(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].icon,
                          size: 22,
                          color: _tab == i
                              ? QuickDropColors.emeraldDark
                              : QuickDropColors.textMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            color: _tab == i
                                ? QuickDropColors.emeraldDark
                                : QuickDropColors.textMuted,
                            fontSize: 11,
                            height: 1.2,
                            fontWeight: _tab == i
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool twoColumn) {
    switch (_tab) {
      case 1:
        return _buildReceiveTab();
      case 2:
        return _buildTransfersTab();
      default:
        return _buildSendTab(twoColumn);
    }
  }

  Widget _buildSendTab(bool twoColumn) {
    final peers = _controller.discovery.peersNotifier.value;

    if (_controller.isSending && _controller.progress != null) {
      final peer = _controller.selectedPeer;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageHeading(
            'Sending to ${peer?.name ?? 'device'}',
            'Keep both devices on the same network until the transfer finishes.',
            trailing: const StatusPill(label: 'Active'),
          ),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ActiveTransferPanel(
                controller: _controller,
                onCancel: _confirmCancelTransfer,
              ),
            ),
          ),
        ],
      );
    }

    if (_lastSummary != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageHeading('Send', 'Transfer finished. Review the result below.'),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SendResultPanel(
                summary: _lastSummary!,
                onDone: () => setState(() => _lastSummary = null),
                onSecondary: () {
                  final success = _lastSummary!.allSent;
                  setState(() => _lastSummary = null);
                  if (success) _pickFiles();
                },
              ),
            ),
          ),
        ],
      );
    }

    final filesPanel = SendPanel(
      controller: _controller,
      onPickFiles: () => _pickFiles(),
      onPickImages: () => _pickFiles(imagesOnly: true),
      onConnect: _openManualConnect,
      onSend: _sendSelected,
    );
    final devices = _buildDevicesSection(peers);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeading(
          'Send',
          'Move files directly to a device on your network.',
        ),
        const SizedBox(height: 20),
        if (twoColumn)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: filesPanel),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: devices),
            ],
          )
        else ...[
          filesPanel,
          const SizedBox(height: 26),
          devices,
        ],
      ],
    );
  }

  Widget _buildDevicesSection(List<DevicePeer> peers) {
    final scanning = _controller.discovery.isScanningNotifier.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          title: 'Nearby devices',
          subtitle: peers.isEmpty
              ? 'Both devices need to be on the same Wi-Fi or hotspot.'
              : 'Select a device, then send when you are ready.',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _outlineIcon(
                icon: Icons.refresh_rounded,
                tooltip: 'Scan again',
                onTap: () async {
                  await _controller.refresh();
                  if (mounted) {
                    _notify(
                      'Scanning the local network…',
                      icon: Icons.wifi_find_rounded,
                      tone: TopNoticeTone.info,
                    );
                  }
                },
              ),
              const SizedBox(width: 6),
              _outlineIcon(
                icon: Icons.add_link_rounded,
                tooltip: 'Connect by IP',
                onTap: _openManualConnect,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (peers.isEmpty)
          _buildEmptyDevices(scanning)
        else
          Container(
            decoration: BoxDecoration(
              color: QuickDropColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QuickDropColors.border),
              boxShadow: QuickDropColors.cardShadow,
            ),
            child: Column(
              children: [
                for (var i = 0; i < peers.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 66,
                      color: QuickDropColors.surfaceSubtle,
                    ),
                  DeviceCard(
                    peer: peers[i],
                    selected:
                        _controller.hasSelection &&
                        _controller.selectedPeer?.id == peers[i].id,
                    isSending: _controller.sendingPeerId == peers[i].id,
                    onSelect: () => _controller.selectPeer(peers[i]),
                    onSend: () => _sendToPeer(peers[i]),
                  ),
                ],
              ],
            ),
          ),
        if (peers.isNotEmpty && scanning)
          Padding(
            padding: const EdgeInsets.only(top: 9, left: 2),
            child: Row(
              children: [
                const SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(strokeWidth: 1.4),
                ),
                const SizedBox(width: 7),
                Text(
                  'Still looking for more devices…',
                  style: TextStyle(
                    color: QuickDropColors.textMuted.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyDevices(bool scanning) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuickDropColors.border),
        boxShadow: QuickDropColors.cardShadow,
      ),
      child: Column(
        children: [
          const EmptyStateIcon(icon: Icons.devices_other_rounded, size: 84),
          const SizedBox(height: 16),
          const Text(
            'No devices found',
            style: TextStyle(
              color: QuickDropColors.textPrimary,
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Make sure QuickDrop is open on the other device and both are on the same Wi-Fi or hotspot.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: QuickDropColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (scanning) ...[
            const SizedBox(height: 12),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                SizedBox(width: 7),
                Text(
                  'Scanning your network…',
                  style: TextStyle(
                    color: QuickDropColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _openManualConnect,
                icon: const Icon(Icons.add_link_rounded, size: 16),
                label: const Text('Connect by IP'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => _controller.refresh(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Scan again'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _selectTab(1),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Receive files instead'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pageHeading(
              'Receive',
              'Let another device send files to this one. No app needed.',
              trailing: StatusPill(
                label: _controller.server.isRunningNotifier.value
                    ? 'Ready to receive'
                    : 'Receiver offline',
                foreground: _controller.server.isRunningNotifier.value
                    ? QuickDropColors.emeraldDark
                    : QuickDropColors.roseDark,
                background: _controller.server.isRunningNotifier.value
                    ? QuickDropColors.emeraldSoft
                    : QuickDropColors.roseSoft,
              ),
            ),
            const SizedBox(height: 20),
            ReceiveCard(
              webUrl: _controller.webUrl,
              deviceName: _controller.settings.deviceName,
              onCopy: () async {
                await Clipboard.setData(
                  ClipboardData(text: _controller.webUrl),
                );
                if (mounted) {
                  _notify(
                    'Receiver URL copied',
                    icon: Icons.copy_rounded,
                    tone: TopNoticeTone.success,
                  );
                }
              },
              onOpenBrowser: _openBrowser,
              onShowQr: _showQr,
              onOpenFolder: _openReceivedFolder,
              onHelp: _openHelp,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.wifi_rounded,
                    size: 15,
                    color: QuickDropColors.textFaint,
                  ),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Devices must share a Wi-Fi network or hotspot, or use USB/Bluetooth tethering. No internet connection is involved.',
                    style: TextStyle(
                      color: QuickDropColors.textMuted,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openOfflineLinks,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('No Wi-Fi?'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildRecentReceived(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReceived() {
    return ValueListenableBuilder<List<TransferItem>>(
      valueListenable: _controller.server.historyNotifier,
      builder: (context, history, _) {
        final incoming = history
            .where((item) => item.isIncoming)
            .take(4)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(
              title: 'Recently received',
              subtitle: incoming.isEmpty
                  ? 'Incoming files will appear here.'
                  : '${incoming.length} latest file${incoming.length == 1 ? '' : 's'} on this device.',
              trailing: history.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => _viewAllTransfers(filter: 2),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 11.5),
                      ),
                      child: const Text('View all'),
                    ),
            ),
            const SizedBox(height: 10),
            if (incoming.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: QuickDropColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: QuickDropColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      color: QuickDropColors.textFaint,
                      size: 22,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Nothing received yet. Share the browser address or QR code above to get started.',
                        style: TextStyle(
                          color: QuickDropColors.textMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: QuickDropColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: QuickDropColors.border),
                  boxShadow: QuickDropColors.cardShadow,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < incoming.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: 66,
                          color: QuickDropColors.surfaceSubtle,
                        ),
                      TransferHistoryTile(item: incoming[i]),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTransfersTab() {
    return ValueListenableBuilder<List<TransferItem>>(
      valueListenable: _controller.server.historyNotifier,
      builder: (context, history, _) {
        final filtered = switch (_historyFilter) {
          1 => history.where((item) => !item.isIncoming).toList(),
          2 => history.where((item) => item.isIncoming).toList(),
          _ => history,
        };

        final groups = _groupHistory(filtered);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _pageHeading(
                  'Transfers',
                  'Files sent and received on this device.',
                  trailing: history.isEmpty
                      ? null
                      : _outlineIcon(
                          icon: Icons.delete_sweep_outlined,
                          tooltip: 'Clear history',
                          onTap: _confirmClearHistory,
                        ),
                ),
                const SizedBox(height: 18),
                _buildFilterBar(),
                const SizedBox(height: 22),
                if (filtered.isEmpty)
                  _buildEmptyHistory()
                else
                  for (var i = 0; i < groups.length; i++) ...[
                    if (i > 0) const SizedBox(height: 22),
                    _buildHistoryGroup(groups[i]),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    const labels = ['All', 'Sent', 'Received'];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: QuickDropColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _historyFilter = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _historyFilter == i
                          ? QuickDropColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _historyFilter == i
                            ? QuickDropColors.border
                            : Colors.transparent,
                      ),
                      boxShadow: _historyFilter == i
                          ? QuickDropColors.cardShadow
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: _historyFilter == i
                            ? QuickDropColors.textPrimary
                            : QuickDropColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryGroup(_HistoryGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            group.label.toUpperCase(),
            style: const TextStyle(
              color: QuickDropColors.textMuted,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: QuickDropColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: QuickDropColors.border),
            boxShadow: QuickDropColors.cardShadow,
          ),
          child: Column(
            children: [
              for (var i = 0; i < group.items.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 66,
                    color: QuickDropColors.surfaceSubtle,
                  ),
                TransferHistoryTile(item: group.items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    final received = _historyFilter == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 28),
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuickDropColors.border),
        boxShadow: QuickDropColors.cardShadow,
      ),
      child: Column(
        children: [
          const EmptyStateIcon(icon: Icons.sync_alt_rounded, size: 84),
          const SizedBox(height: 16),
          Text(
            received ? 'No received files yet' : 'No transfers yet',
            style: const TextStyle(
              color: QuickDropColors.textPrimary,
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            received
                ? 'Files sent to this device will show up here with a quick open action.'
                : 'Send a file to a nearby device, or receive one through the browser receiver.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: QuickDropColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _selectTab(received ? 1 : 0),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(received ? 'Open Receive' : 'Send files'),
          ),
        ],
      ),
    );
  }

  Widget _pageHeading(String title, String subtitle, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: QuickDropColors.textPrimary,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: QuickDropColors.textMuted,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Padding(padding: const EdgeInsets.only(top: 3), child: trailing),
        ],
      ],
    );
  }

  Widget _outlineIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          maximumSize: const Size(36, 36),
          backgroundColor: QuickDropColors.surface,
          side: const BorderSide(color: QuickDropColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        icon: Icon(icon, size: 17, color: QuickDropColors.textSecondary),
      ),
    );
  }

  Widget _buildDropOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: QuickDropColors.background.withValues(alpha: 0.86),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 36),
              decoration: BoxDecoration(
                color: QuickDropColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: QuickDropColors.emerald,
                  width: 1.5,
                ),
                boxShadow: QuickDropColors.raisedShadow,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    color: QuickDropColors.emeraldDark,
                    size: 36,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Drop to add files',
                    style: TextStyle(
                      color: QuickDropColors.textPrimary,
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Multiple files are supported',
                    style: TextStyle(
                      color: QuickDropColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_HistoryGroup> _groupHistory(List<TransferItem> items) {
    final now = DateTime.now();
    final today = <TransferItem>[];
    final yesterday = <TransferItem>[];
    final earlier = <TransferItem>[];

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final yesterdayDate = now.subtract(const Duration(days: 1));
    for (final item in items) {
      if (sameDay(item.timestamp, now)) {
        today.add(item);
      } else if (sameDay(item.timestamp, yesterdayDate)) {
        yesterday.add(item);
      } else {
        earlier.add(item);
      }
    }

    return [
      if (today.isNotEmpty) _HistoryGroup('Today', today),
      if (yesterday.isNotEmpty) _HistoryGroup('Yesterday', yesterday),
      if (earlier.isNotEmpty) _HistoryGroup('Earlier', earlier),
    ];
  }
}

class _HistoryGroup {
  final String label;
  final List<TransferItem> items;

  const _HistoryGroup(this.label, this.items);
}
