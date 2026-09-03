import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/linux_integrations.dart';
import '../../models/device_peer.dart';
import '../quickdrop_theme.dart';

class TransferHistoryTile extends StatelessWidget {
  final TransferItem item;

  const TransferHistoryTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final file = File(item.filePath);
    final fileExists = file.existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QuickDropColors.border),
      ),
      child: Row(
        children: [
          // Image thumbnail or icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: fileExists
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  style: const TextStyle(
                    color: QuickDropColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      item.isIncoming
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                      size: 13,
                      color: item.isIncoming
                          ? QuickDropColors.emerald
                          : QuickDropColors.cyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.isIncoming ? "From" : "To"} ${item.senderName} • ${item.formattedSize}',
                      style: const TextStyle(
                        color: QuickDropColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          if (Platform.isLinux && fileExists) ...[
            IconButton(
              tooltip: 'Copy to Clipboard',
              icon: const Icon(Icons.copy_rounded, color: QuickDropColors.cyan, size: 19),
              onPressed: () async {
                final ok = await LinuxIntegrations.copyImageToClipboard(item.filePath);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? '✓ Image copied to system clipboard!'
                          : 'Failed to copy image'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: ok ? QuickDropColors.emerald : QuickDropColors.rose,
                    ),
                  );
                }
              },
            ),
            IconButton(
              tooltip: 'Open Image',
              icon: const Icon(Icons.visibility_outlined,
                  color: QuickDropColors.textSecondary, size: 19),
              onPressed: () => LinuxIntegrations.openFile(item.filePath),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: QuickDropColors.surfaceLight,
      child: const Icon(
        Icons.image_outlined,
        color: QuickDropColors.textSecondary,
      ),
    );
  }
}
