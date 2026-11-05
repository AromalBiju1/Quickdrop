import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/file_utils.dart';
import '../../core/quickdrop_controller.dart';
import '../../models/link.dart';
import '../quickdrop_motion.dart';
import '../quickdrop_theme.dart';
import 'file_thumb.dart';

class ActiveTransferPanel extends StatelessWidget {
  final QuickDropController controller;
  final VoidCallback onCancel;

  const ActiveTransferPanel({
    super.key,
    required this.controller,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    final progress = controller.progress;
    if (progress == null) return const SizedBox.shrink();

    final peer = controller.selectedPeer;
    final files = controller.activeBatch;
    final visible = files.take(5).toList();
    final hidden = files.length - visible.length;
    final remainingBytes = (progress.totalBytes - progress.sentBytes).clamp(
      0,
      progress.totalBytes,
    );
    final eta = progress.bytesPerSecond > 0
        ? Duration(seconds: (remainingBytes / progress.bytesPerSecond).ceil())
        : null;

    final link = peer?.link;
    final details = controller.isFinishing
        ? <String>[
            if (link != null && link != LinkKind.unknown)
              'Finishing over ${link.label}',
            'Finishing on ${peer?.name ?? 'the receiver'}…',
          ]
        : <String>[
            if (link != null && link != LinkKind.unknown)
              'Sending over ${link.label}',
            if (progress.bytesPerSecond > 0)
              FileUtils.formatSpeed(progress.bytesPerSecond),
            if (eta != null) '${FileUtils.formatDuration(eta)} left',
          ];

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 212,
              height: 212,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress.overallProgress),
                duration: QuickDropMotion.duration(
                  context,
                  const Duration(milliseconds: 240),
                ),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CustomPaint(
                    painter: _ProgressRingPainter(
                      value,
                      trackColor: context.qd.surfaceSubtle,
                      arcColor: context.qd.emerald,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).round().clamp(0, 100)}%',
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 44,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${FileUtils.formatBytes(progress.sentBytes)} of ${FileUtils.formatBytes(progress.totalBytes)}',
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              details.isEmpty ? 'Preparing transfer…' : details.join('  ·  '),
              style: TextStyle(color: p.textMuted, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Files in queue',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${progress.currentIndex + 1} of ${progress.fileCount}',
                style: TextStyle(
                  color: p.emeraldDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 64, color: p.surfaceSubtle),
                  _queueRow(context, visible[i], i, progress, p),
                ],
                if (hidden > 0) ...[
                  Divider(height: 1, indent: 64, color: p.surfaceSubtle),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(64, 11, 14, 11),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+$hidden more file${hidden == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: p.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel transfer'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: p.rose,
              side: BorderSide(color: p.roseBorder),
              backgroundColor: p.roseSoft,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Sending directly to ${peer?.name ?? 'the other device'} · no cloud',
              style: TextStyle(color: p.textFaint, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueRow(
    BuildContext context,
    SelectedFile file,
    int index,
    SendProgress progress,
    QuickDropPalette p,
  ) {
    final isCurrent = index == progress.currentIndex;
    final isDone = index < progress.currentIndex;

    Color tileColor;
    Color iconColor;
    IconData icon;
    if (isDone) {
      tileColor = p.emeraldSoft;
      iconColor = p.emeraldDark;
      icon = Icons.check_rounded;
    } else if (isCurrent) {
      tileColor = p.emeraldSoft;
      iconColor = p.emeraldDark;
      icon = Icons.arrow_upward_rounded;
    } else {
      tileColor = p.surfaceSubtle;
      iconColor = p.textMuted;
      icon = Icons.schedule_rounded;
    }

    final status = isDone
        ? 'Done'
        : isCurrent
        ? (controller.isFinishing
              ? 'Saving'
              : '${(progress.fileProgress * 100).round()}%')
        : 'Queued';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
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
                        color: isDone || isCurrent
                            ? p.textPrimary
                            : p.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCurrent
                          ? '${FileUtils.formatBytes((file.size * progress.fileProgress).round())} of ${file.formattedSize}'
                          : file.formattedSize,
                      style: TextStyle(color: p.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: status,
                dot: false,
                foreground: isDone
                    ? p.emeraldDark
                    : isCurrent
                    ? p.emeraldDark
                    : p.textMuted,
                background: isDone || isCurrent
                    ? p.emeraldSoft
                    : p.surfaceSubtle,
              ),
            ],
          ),
          if (isCurrent) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: progress.fileProgress.clamp(0.0, 1.0),
                ),
                duration: QuickDropMotion.duration(
                  context,
                  const Duration(milliseconds: 200),
                ),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: context.qd.surfaceSubtle,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color arcColor;

  _ProgressRingPainter(
    this.progress, {
    required this.trackColor,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 12) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final value = progress.clamp(0.0, 1.0);
    if (value <= 0) return;

    final arc = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.arcColor != arcColor;
}
