import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/device_peer.dart';
import 'app_store.dart';
import 'discovery_service.dart';
import 'file_utils.dart';
import 'share_receiver.dart';
import 'transfer_client.dart';
import 'transfer_server.dart';

class SelectedFile {
  final String path;
  final String name;
  final int size;
  final bool fromShare;

  const SelectedFile({
    required this.path,
    required this.name,
    required this.size,
    this.fromShare = false,
  });

  bool get isImage => FileUtils.isImage(name);
  String get mimeType => FileUtils.mimeType(name);
  String get formattedSize => FileUtils.formatBytes(size);
}

class SendProgress {
  final int currentIndex;
  final int fileCount;
  final String fileName;
  final String filePath;
  final double fileProgress;
  final double overallProgress;
  final int sentBytes;
  final int totalBytes;
  final double bytesPerSecond;
  final Duration elapsed;

  const SendProgress({
    required this.currentIndex,
    required this.fileCount,
    required this.fileName,
    required this.filePath,
    required this.fileProgress,
    required this.overallProgress,
    required this.sentBytes,
    required this.totalBytes,
    required this.bytesPerSecond,
    required this.elapsed,
  });

  int get percent => (overallProgress * 100).round().clamp(0, 100);
}

class SendFileResult {
  final String fileName;
  final int fileSize;
  final bool success;
  final String? error;

  const SendFileResult({
    required this.fileName,
    required this.fileSize,
    required this.success,
    this.error,
  });

  String get formattedSize => FileUtils.formatBytes(fileSize);
}

class SendSummary {
  final int sent;
  final int failed;
  final bool canceled;
  final int total;
  final String peerName;
  final String? firstError;
  final List<SendFileResult> files;
  final int totalBytes;
  final Duration elapsed;

  const SendSummary({
    required this.sent,
    required this.failed,
    required this.canceled,
    required this.total,
    required this.peerName,
    required this.files,
    required this.totalBytes,
    required this.elapsed,
    this.firstError,
  });

  bool get allSent => sent == total && failed == 0 && !canceled;
  String get formattedTotalSize => FileUtils.formatBytes(totalBytes);
}

class SelectionResult {
  final int added;
  final int skipped;

  const SelectionResult(this.added, this.skipped);
}

class QuickDropController extends ChangeNotifier {
  final DiscoveryService discovery;
  final TransferServer server;
  final ValueNotifier<SendSummary?> summaryNotifier =
      ValueNotifier<SendSummary?>(null);

  AppSettings settings;
  final List<SelectedFile> _selected = [];
  final Set<String> _selectedPaths = {};
  List<SelectedFile> _activeBatch = const [];

  String? _selectedPeerId;
  bool _isSending = false;
  bool _isFinishing = false;
  String? _sendingPeerId;
  SendProgress? _progress;
  TransferCancelToken? _cancelToken;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  QuickDropController({
    required this.discovery,
    required this.server,
    required this.settings,
  }) {
    server.deviceName = settings.deviceName;
    server.autoCopyImages = settings.autoCopyImages;
    server.notifications = settings.notifications;
    discovery.peersNotifier.addListener(_onPeersChanged);
    discovery.localIpNotifier.addListener(notifyListeners);
    discovery.isScanningNotifier.addListener(notifyListeners);
    server.isRunningNotifier.addListener(notifyListeners);
    ShareReceiver.sharedFilesNotifier.addListener(_onSharedFilesChanged);
    if (ShareReceiver.sharedFilesNotifier.value.isNotEmpty) {
      unawaited(addPaths(ShareReceiver.sharedFilesNotifier.value, fromShare: true));
    }
  }

  List<SelectedFile> get selectedFiles => List.unmodifiable(_selected);
  List<SelectedFile> get activeBatch => List.unmodifiable(_activeBatch);
  bool get hasSelection => _selected.isNotEmpty;
  bool get isSending => _isSending;
  bool get isFinishing => _isFinishing;
  SendProgress? get progress => _progress;
  String? get sendingPeerId => _sendingPeerId;

  int get totalSelectedBytes =>
      _selected.fold(0, (sum, file) => sum + file.size);

  String get totalSelectedSize => FileUtils.formatBytes(totalSelectedBytes);

  DevicePeer? get selectedPeer {
    final peers = discovery.peersNotifier.value;
    if (peers.isEmpty) return null;
    if (_selectedPeerId != null) {
      for (final peer in peers) {
        if (peer.id == _selectedPeerId) return peer;
      }
    }
    return peers.first;
  }

  String get localAddress => '${discovery.localIp}:${discovery.httpPort}';
  String get webUrl => discovery.webUrl;

  void _onPeersChanged() {
    _ensureSelectedPeer();
    notifyListeners();
  }

  void _ensureSelectedPeer() {
    final peers = discovery.peersNotifier.value;
    if (peers.isEmpty) {
      _selectedPeerId = null;
      return;
    }
    if (_selectedPeerId == null ||
        !peers.any((peer) => peer.id == _selectedPeerId)) {
      _selectedPeerId = peers.first.id;
    }
  }

  void _onSharedFilesChanged() {
    final paths = ShareReceiver.sharedFilesNotifier.value;
    if (paths.isEmpty) return;
    unawaited(addPaths(paths, fromShare: true));
  }

  void selectPeer(DevicePeer? peer) {
    _selectedPeerId = peer?.id;
    notifyListeners();
  }

  Future<SelectionResult> addPaths(
    List<String> paths, {
    bool fromShare = false,
  }) async {
    var added = 0;
    var skipped = 0;

    for (final rawPath in paths) {
      final path = rawPath.trim();
      if (path.isEmpty || _selectedPaths.contains(path)) {
        skipped++;
        continue;
      }
      try {
        final file = File(path);
        if (!await file.exists()) {
          skipped++;
          continue;
        }
        final size = await file.length();
        _selected.add(SelectedFile(
          path: path,
          name: FileUtils.fileName(path),
          size: size,
          fromShare: fromShare,
        ));
        _selectedPaths.add(path);
        added++;
      } catch (_) {
        skipped++;
      }
    }

    if (added > 0) {
      _ensureSelectedPeer();
      notifyListeners();
    }
    return SelectionResult(added, skipped);
  }

  Future<SelectionResult> pickFiles({bool imagesOnly = false}) async {
    try {
      final files = await FilePicker.pickFiles(
        type: imagesOnly ? FileType.image : FileType.any,
        dialogTitle: imagesOnly ? 'Choose photos' : 'Choose files to send',
      );
      final paths = files
          .map((file) => file.path)
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .toList();
      return await addPaths(paths);
    } catch (e) {
      debugPrint('[Controller] File picker failed: $e');
      return const SelectionResult(0, 0);
    }
  }

  void removeFile(SelectedFile file) {
    _selected.removeWhere((item) => item.path == file.path);
    _selectedPaths.remove(file.path);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    _selectedPaths.clear();
    notifyListeners();
  }

  Future<void> sendToPeer(DevicePeer peer) async {
    if (_isSending) return;
    if (_selected.isEmpty) {
      await pickFiles();
      if (_selected.isEmpty) return;
    }
    if (_isSending) return;

    final files = List<SelectedFile>.from(_selected);
    final totalBytes = files.fold<int>(0, (sum, file) => sum + file.size);
    final batchId = 'batch_${DateTime.now().microsecondsSinceEpoch}';
    final startTime = DateTime.now();
    final token = TransferCancelToken();

    _isSending = true;
    _sendingPeerId = peer.id;
    _cancelToken = token;
    _activeBatch = List.unmodifiable(files);
    _progress = SendProgress(
      currentIndex: 0,
      fileCount: files.length,
      fileName: files.first.name,
      filePath: files.first.path,
      fileProgress: 0,
      overallProgress: 0,
      sentBytes: 0,
      totalBytes: totalBytes,
      bytesPerSecond: 0,
      elapsed: Duration.zero,
    );
    notifyListeners();

    var completedBytes = 0;
    var sent = 0;
    var failed = 0;
    String? firstError;
    var canceled = false;
    final results = <SendFileResult>[];

    for (var index = 0; index < files.length; index++) {
      if (token.isCanceled) {
        canceled = true;
        break;
      }
      final file = files[index];

      final result = await TransferClient.sendFile(
        targetPeer: peer,
        file: File(file.path),
        senderName: settings.deviceName,
        batchId: batchId,
        fileIndex: index,
        fileTotal: files.length,
        cancelToken: token,
        onUploadFinished: () {
          _isFinishing = true;
          notifyListeners();
        },
        onProgress: (sentBytes, fileBytes) {
          final elapsed = DateTime.now().difference(startTime);
          final overall = totalBytes == 0
              ? 0.0
              : (completedBytes + sentBytes) / totalBytes;
          _progress = SendProgress(
            currentIndex: index,
            fileCount: files.length,
            fileName: file.name,
            filePath: file.path,
            fileProgress: fileBytes == 0 ? 0 : sentBytes / fileBytes,
            overallProgress: overall.clamp(0.0, 1.0),
            sentBytes: completedBytes + sentBytes,
            totalBytes: totalBytes,
            bytesPerSecond: elapsed.inMilliseconds > 0
                ? (completedBytes + sentBytes) /
                    (elapsed.inMilliseconds / 1000)
                : 0,
            elapsed: elapsed,
          );
          final now = DateTime.now();
          if (now.difference(_lastNotify).inMilliseconds > 40 ||
              sentBytes == fileBytes) {
            _lastNotify = now;
            notifyListeners();
          }
        },
      );

      completedBytes += file.size;
      _isFinishing = false;

      if (result.canceled) {
        canceled = true;
        results.add(SendFileResult(
          fileName: file.name,
          fileSize: file.size,
          success: false,
          error: 'Canceled',
        ));
        break;
      }

      if (result.success) {
        sent++;
        results.add(SendFileResult(
          fileName: file.name,
          fileSize: file.size,
          success: true,
        ));
        _selected.removeWhere((item) => item.path == file.path);
        _selectedPaths.remove(file.path);
        server.addOutgoingHistory(TransferItem(
          id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
          fileName: file.name,
          fileSize: file.size,
          filePath: file.path,
          senderName: peer.name,
          isIncoming: false,
          timestamp: DateTime.now(),
          success: true,
          batchId: batchId,
        ));
      } else {
        failed++;
        firstError ??= result.message;
        results.add(SendFileResult(
          fileName: file.name,
          fileSize: file.size,
          success: false,
          error: result.message,
        ));
      }
    }

    if (canceled && results.length < files.length) {
      for (var index = results.length; index < files.length; index++) {
        final file = files[index];
        results.add(SendFileResult(
          fileName: file.name,
          fileSize: file.size,
          success: false,
          error: 'Canceled',
        ));
      }
    }

    final summary = SendSummary(
      sent: sent,
      failed: failed,
      canceled: canceled,
      total: files.length,
      peerName: peer.name,
      firstError: firstError,
      files: results,
      totalBytes: totalBytes,
      elapsed: DateTime.now().difference(startTime),
    );

    _isSending = false;
    _isFinishing = false;
    _sendingPeerId = null;
    _progress = null;
    _activeBatch = const [];
    _cancelToken = null;
    _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    summaryNotifier.value = summary;
    notifyListeners();
  }

  void cancelTransfer() {
    _cancelToken?.cancel();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings next) async {
    settings = next;
    server.deviceName = next.deviceName;
    server.autoCopyImages = next.autoCopyImages;
    server.notifications = next.notifications;
    discovery.rename(next.deviceName);
    notifyListeners();
    await AppStore.saveSettings(next);
  }

  Future<void> refresh() => discovery.refreshNetwork();

  void clearHistory() => server.clearHistory();

  @override
  void dispose() {
    discovery.peersNotifier.removeListener(_onPeersChanged);
    discovery.localIpNotifier.removeListener(notifyListeners);
    discovery.isScanningNotifier.removeListener(notifyListeners);
    server.isRunningNotifier.removeListener(notifyListeners);
    ShareReceiver.sharedFilesNotifier.removeListener(_onSharedFilesChanged);
    _cancelToken?.cancel();
    super.dispose();
  }
}
