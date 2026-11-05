import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/file_utils.dart';
import '../../core/platform_integrations.dart';
import '../../models/device_peer.dart';
import '../quickdrop_motion.dart';
import '../quickdrop_theme.dart';
import 'file_thumb.dart';
import 'top_notice.dart';

class TransferHistoryTile extends StatefulWidget {
  final TransferItem item;
  final bool animate;
  final VoidCallback? onAnimated;

  const TransferHistoryTile({
    super.key,
    required this.item,
    this.animate = false,
    this.onAnimated,
  });

  @override
  State<TransferHistoryTile> createState() => _TransferHistoryTileState();
}

class _TransferHistoryTileState extends State<TransferHistoryTile> {
  late bool _animate = widget.animate;

  TransferItem get item => widget.item;

  String get _title {
    if (item.kind != TransferKind.text) return item.fileName;
    final preview = item.preview?.trim();
    if (preview == null || preview.isEmpty) return 'Text snippet';
    final firstLine = preview.split('\n').first.trim();
    return firstLine.isEmpty ? 'Text snippet' : firstLine;
  }

  void _finishEntry() {
    if (!mounted || !_animate) return;
    setState(() => _animate = false);
    widget.onAnimated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile(context);
    if (!_animate) return tile;

    final duration = QuickDropMotion.duration(
      context,
      const Duration(milliseconds: 220),
    );
    if (duration == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishEntry());
      return tile;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      onEnd: _finishEntry,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: value,
              child: child,
            ),
          ),
        );
      },
      child: tile,
    );
  }

  Widget _buildTile(BuildContext context) {
    final p = context.qd;
    // Android files live in public Downloads through MediaStore. A scoped
    // path may not be stat-able, but the content URI is still valid.
    final hasFile =
        (item.contentUri?.isNotEmpty ?? false) ||
        (item.filePath.isNotEmpty && File(item.filePath).existsSync());
    final kindLabel = item.isText ? 'Text' : item.formattedSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasFile ? () => _open(context) : null,
        hoverColor: p.surfaceMuted,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 6, 11),
          child: Row(
            children: [
              item.isText
                  ? Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.emeraldSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notes_rounded,
                        color: p.emeraldDark,
                        size: 19,
                      ),
                    )
                  : Opacity(
                      opacity: hasFile ? 1 : 0.45,
                      child: FileThumb(
                        path: item.filePath,
                        size: 40,
                        radius: 10,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasFile || item.isText
                            ? p.textPrimary
                            : p.textMuted,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.isIncoming ? 'From' : 'To'} ${item.senderName}  ·  $kindLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textMuted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(
                    label: item.success ? 'Complete' : 'Failed',
                    dot: false,
                    foreground: item.success ? p.emeraldDark : p.roseDark,
                    background: item.success ? p.emeraldSoft : p.roseSoft,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    FileUtils.friendlyTime(item.timestamp),
                    style: TextStyle(
                      color: p.textFaint,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              if (!item.isText && !hasFile)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: 'File was moved or deleted',
                    child: Icon(
                      Icons.link_off_rounded,
                      color: p.textFaint,
                      size: 15,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'File actions',
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: p.textMuted,
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) => _action(context, value),
                itemBuilder: (context) => [
                  if (item.isText)
                    const PopupMenuItem(
                      value: 'copy_text',
                      child: _MenuRow(
                        icon: Icons.content_copy_rounded,
                        label: 'Copy text',
                      ),
                    ),
                  if (item.filePath.isNotEmpty)
                    const PopupMenuItem(
                      value: 'copy_path',
                      child: _MenuRow(
                        icon: Icons.link_rounded,
                        label: 'Copy file path',
                      ),
                    ),
                  if (hasFile)
                    const PopupMenuItem(
                      value: 'open',
                      child: _MenuRow(
                        icon: Icons.open_in_new_rounded,
                        label: 'Open file',
                      ),
                    ),
                  if (hasFile)
                    PopupMenuItem(
                      value: 'folder',
                      child: _MenuRow(
                        icon: Icons.folder_open_rounded,
                        label: Platform.isAndroid
                            ? 'Show in Downloads'
                            : 'Show in folder',
                      ),
                    ),
                  if (!item.isText &&
                      hasFile &&
                      (Platform.isLinux || Platform.isWindows) &&
                      item.isImage)
                    const PopupMenuItem(
                      value: 'copy_image',
                      child: _MenuRow(
                        icon: Icons.copy_all_rounded,
                        label: 'Copy image',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _action(BuildContext context, String value) async {
    switch (value) {
      case 'copy_text':
        var text = item.preview ?? '';
        if (item.filePath.isNotEmpty && File(item.filePath).existsSync()) {
          try {
            text = File(item.filePath).readAsStringSync();
          } catch (_) {}
        }
        if (text.trim().isEmpty) {
          if (context.mounted) {
            _notify(
              context,
              'Text is no longer available',
              tone: TopNoticeTone.error,
            );
          }
          return;
        }
        final ok = await PlatformIntegrations.copyTextToClipboard(text);
        if (context.mounted) {
          _notify(
            context,
            ok ? 'Text copied to clipboard' : 'Could not copy text',
            tone: ok ? TopNoticeTone.success : TopNoticeTone.error,
          );
        }
        return;
      case 'copy_path':
        await Clipboard.setData(ClipboardData(text: item.filePath));
        if (context.mounted) {
          _notify(context, 'File path copied');
        }
        return;
      case 'open':
        await _open(context);
        return;
      case 'folder':
        if (Platform.isAndroid) {
          final ok = await PlatformIntegrations.openDownloads();
          if (!ok && context.mounted) {
            _notify(
              context,
              'Files are in Download/QuickDrop',
              tone: TopNoticeTone.info,
            );
          }
          return;
        }
        final index = item.filePath.lastIndexOf(Platform.pathSeparator);
        if (index > 0) {
          final opened = await PlatformIntegrations.openFolder(
            item.filePath.substring(0, index),
          );
          if (!opened && context.mounted) {
            _notify(
              context,
              'Could not open the file folder',
              tone: TopNoticeTone.error,
            );
          }
        }
        return;
      case 'copy_image':
        final ok = await PlatformIntegrations.copyImageToClipboard(
          item.filePath,
        );
        if (context.mounted) {
          _notify(
            context,
            ok ? 'Image copied to clipboard' : 'Could not copy image',
            tone: ok ? TopNoticeTone.success : TopNoticeTone.error,
          );
        }
        return;
    }
  }

  Future<void> _open(BuildContext context) async {
    if (Platform.isAndroid) {
      final target = (item.contentUri?.isNotEmpty ?? false)
          ? item.contentUri!
          : item.filePath;
      final ok = await PlatformIntegrations.openFile(
        target,
        mimeType: FileUtils.mimeType(item.fileName),
      );
      if (!ok && context.mounted) {
        _notify(
          context,
          'No app can open this file',
          tone: TopNoticeTone.error,
        );
      }
      return;
    }
    final opened = await PlatformIntegrations.openFile(item.filePath);
    if (!opened && context.mounted) {
      _notify(context, 'No app can open this file', tone: TopNoticeTone.error);
    }
  }

  void _notify(
    BuildContext context,
    String message, {
    TopNoticeTone tone = TopNoticeTone.success,
  }) {
    if (!context.mounted) return;
    showTopNotice(context, TopNotice(message: message, tone: tone));
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    return Row(
      children: [
        Icon(icon, size: 16, color: p.textSecondary),
        const SizedBox(width: 9),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }
}
