import 'package:flutter/material.dart';

import '../../core/quickdrop_controller.dart';
import '../../models/device_peer.dart';
import '../quickdrop_theme.dart';
import 'file_thumb.dart';

class SendPanel extends StatelessWidget {
  final QuickDropController controller;
  final VoidCallback onPickFiles;
  final VoidCallback onPickImages;
  final VoidCallback onConnect;
  final VoidCallback onSend;

  const SendPanel({
    super.key,
    required this.controller,
    required this.onPickFiles,
    required this.onPickImages,
    required this.onConnect,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    final files = controller.selectedFiles;
    final peer = controller.selectedPeer;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(files, p),
          const SizedBox(height: 16),
          if (files.isEmpty) _dropZone(context) else _selection(files, p),
          const SizedBox(height: 18),
          _sendButton(peer, p),
          if (peer == null) ...[
            const SizedBox(height: 10),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'Select a nearby device first.',
                    style: TextStyle(color: p.textMuted, fontSize: 11.5),
                  ),
                  TextButton(
                    onPressed: onConnect,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(fontSize: 11.5),
                    ),
                    child: const Text('Connect by IP'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(List<SelectedFile> files, QuickDropPalette p) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: p.emeraldSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.upload_file_rounded,
            color: p.emeraldDark,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send files',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Any file type. Multiple files welcome.',
                style: TextStyle(
                  color: p.textMuted,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (files.isNotEmpty)
          TextButton(
            onPressed: controller.clearSelection,
            style: TextButton.styleFrom(
              foregroundColor: p.textMuted,
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Clear'),
          ),
      ],
    );
  }

  Widget _dropZone(BuildContext context) {
    final p = context.qd;
    return CustomPaint(
      painter: _DashedBorderPainter(color: p.borderStrong, radius: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPickFiles,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, color: p.emeraldDark, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                'Drop files here',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'or choose something from this device',
                style: TextStyle(color: p.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onPickFiles,
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    label: const Text('Choose files'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onPickImages,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Photos'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _selection(List<SelectedFile> files, QuickDropPalette p) {
    final visible = files.take(6).toList();
    final hidden = files.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 62, color: p.surfaceSubtle),
                _fileRow(visible[i], p),
              ],
              if (hidden > 0) ...[
                Divider(height: 1, indent: 62, color: p.surfaceSubtle),
                Padding(
                  padding: const EdgeInsets.fromLTRB(62, 10, 14, 10),
                  child: Row(
                    children: [
                      Text(
                        '+$hidden more file${hidden == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: p.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${files.length} file${files.length == 1 ? '' : 's'} · ${controller.totalSelectedSize}',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onPickFiles,
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Add more'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(fontSize: 11.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fileRow(SelectedFile file, QuickDropPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      child: Row(
        children: [
          FileThumb(path: file.path, size: 40, radius: 10),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  file.formattedSize,
                  style: TextStyle(color: p.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove file',
            onPressed: () => controller.removeFile(file),
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              maximumSize: const Size(32, 32),
            ),
            icon: Icon(Icons.close_rounded, size: 16, color: p.textFaint),
          ),
        ],
      ),
    );
  }

  Widget _sendButton(DevicePeer? peer, QuickDropPalette p) {
    final canSend =
        controller.hasSelection && peer != null && !controller.isSending;
    final count = controller.selectedFiles.length;

    final String label;
    if (peer == null) {
      label = 'No device selected';
    } else if (count == 0) {
      label = 'Choose files to send';
    } else {
      label = 'Send ${count == 1 ? 'file' : '$count files'} to ${peer.name}';
    }

    return FilledButton.icon(
      onPressed: canSend ? onSend : null,
      icon: const Icon(Icons.arrow_upward_rounded, size: 19),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
