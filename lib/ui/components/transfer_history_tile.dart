import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/file_utils.dart';
import '../../core/platform_integrations.dart';
import '../../models/device_peer.dart';
import '../quickdrop_theme.dart';
import 'file_thumb.dart';
import 'top_notice.dart';

class TransferHistoryTile extends StatelessWidget {
  final TransferItem item;

  const TransferHistoryTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    // Android files live in public Downloads through MediaStore. A scoped
    // path may not be stat-able, but the content URI is still valid.
    final exists =
        (item.contentUri?.isNotEmpty ?? false) ||
        (item.filePath.isNotEmpty && File(item.filePath).existsSync());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: exists ? () => _open(context) : null,
        hoverColor: p.surfaceMuted,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 6, 11),
          child: Row(
            children: [
              Opacity(
                opacity: exists ? 1 : 0.45,
                child: FileThumb(path: item.filePath, size: 40, radius: 10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: exists ? p.textPrimary : p.textMuted,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.isIncoming ? 'From' : 'To'} ${item.senderName}  ·  ${item.formattedSize}',
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
              if (!exists)
                Padding(
                  padding: EdgeInsets.only(left: 6),
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
                onSelected: (value) => _action(context, value, exists),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy_path',
                    child: _MenuRow(
                      icon: Icons.link_rounded,
                      label: 'Copy file path',
                    ),
                  ),
                  if (exists)
                    const PopupMenuItem(
                      value: 'open',
                      child: _MenuRow(
                        icon: Icons.open_in_new_rounded,
                        label: 'Open file',
                      ),
                    ),
                  if (exists)
                    PopupMenuItem(
                      value: 'folder',
                      child: _MenuRow(
                        icon: Icons.folder_open_rounded,
                        label: Platform.isAndroid
                            ? 'Show in Downloads'
                            : 'Show in folder',
                      ),
                    ),
                  if (exists &&
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

  Future<void> _action(BuildContext context, String value, bool exists) async {
    switch (value) {
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
