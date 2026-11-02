import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/file_utils.dart';
import '../../core/quickdrop_controller.dart';
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
    final progress = controller.progress;
    if (progress == null) return const SizedBox.shrink();

    final peer = controller.selectedPeer;
    final files = controller.activeBatch;
    final visible = files.take(5).toList();
    final hidden = files.length - visible.length;
    final remainingBytes =
        (progress.totalBytes - progress.sentBytes).clamp(0, progress.totalBytes);
    final eta = progress.bytesPerSecond > 0
        ? Duration(seconds: (remainingBytes / progress.bytesPerSecond).ceil())
        : null;

    final details = controller.isFinishing
        ? <String>['Finishing on ${peer?.name ?? 'the receiver'}…']
        : <String>[
            if (progress.bytesPerSecond > 0)
              FileUtils.formatSpeed(progress.bytesPerSecond),
            if (eta != null) '${FileUtils.formatDuration(eta)} left',
          ];

    return Container(
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuickDropColors.border),
        boxShadow: QuickDropColors.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 212,
              height: 212,
              child: CustomPaint(
                painter: _ProgressRingPainter(progress.overallProgress),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${progress.percent}%',
                        style: const TextStyle(
                          color: QuickDropColors.textPrimary,
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${FileUtils.formatBytes(progress.sentBytes)} of ${FileUtils.formatBytes(progress.totalBytes)}',
                        style: const TextStyle(
                          color: QuickDropColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              details.isEmpty
                  ? 'Preparing transfer…'
                  : details.join('  ·  '),
              style: const TextStyle(
                color: QuickDropColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Files in queue',
                  style: TextStyle(
                    color: QuickDropColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${progress.currentIndex + 1} of ${progress.fileCount}',
                style: const TextStyle(
                  color: QuickDropColors.emeraldDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: QuickDropColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: QuickDropColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: QuickDropColors.surfaceSubtle,
                    ),
                  _queueRow(visible[i], i, progress),
                ],
                if (hidden > 0) ...[
                  const Divider(
                    height: 1,
                    indent: 64,
                    color: QuickDropColors.surfaceSubtle,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(64, 11, 14, 11),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+$hidden more file${hidden == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: QuickDropColors.textMuted,
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
              foregroundColor: QuickDropColors.rose,
              side: const BorderSide(color: QuickDropColors.roseBorder),
              backgroundColor: QuickDropColors.roseSoft,
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
              style: const TextStyle(
                color: QuickDropColors.textFaint,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueRow(SelectedFile file, int index, SendProgress progress) {
    final isCurrent = index == progress.currentIndex;
    final isDone = index < progress.currentIndex;

    Color tileColor;
    Color iconColor;
    IconData icon;
    if (isDone) {
      tileColor = QuickDropColors.emeraldSoft;
      iconColor = QuickDropColors.emeraldDark;
      icon = Icons.check_rounded;
    } else if (isCurrent) {
      tileColor = QuickDropColors.emeraldSoft;
      iconColor = QuickDropColors.emeraldDark;
      icon = Icons.arrow_upward_rounded;
    } else {
      tileColor = QuickDropColors.surfaceSubtle;
      iconColor = QuickDropColors.textMuted;
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
                            ? QuickDropColors.textPrimary
                            : QuickDropColors.textSecondary,
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
                      style: const TextStyle(
                        color: QuickDropColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: status,
                dot: false,
                foreground: isDone
                    ? QuickDropColors.emeraldDark
                    : isCurrent
                        ? QuickDropColors.emeraldDark
                        : QuickDropColors.textMuted,
                background: isDone || isCurrent
                    ? QuickDropColors.emeraldSoft
                    : QuickDropColors.surfaceSubtle,
              ),
            ],
          ),
          if (isCurrent) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.fileProgress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: QuickDropColors.surfaceSubtle,
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

  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 12) / 2;

    final track = Paint()
      ..color = QuickDropColors.surfaceSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final value = progress.clamp(0.0, 1.0);
    if (value <= 0) return;

    final arc = Paint()
      ..color = QuickDropColors.emerald
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
      oldDelegate.progress != progress;
}
