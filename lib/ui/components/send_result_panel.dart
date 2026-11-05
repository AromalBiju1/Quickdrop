import 'package:flutter/material.dart';

import '../../core/file_utils.dart';
import '../../core/quickdrop_controller.dart';
import '../quickdrop_theme.dart';

class SendResultPanel extends StatelessWidget {
  final SendSummary summary;
  final VoidCallback onDone;
  final VoidCallback onSecondary;

  const SendResultPanel({
    super.key,
    required this.summary,
    required this.onDone,
    required this.onSecondary,
  });

  bool get _success => summary.allSent;
  bool get _canceled => summary.canceled && !summary.allSent;

  Color _accent(QuickDropPalette p) {
    if (_success) return p.emerald;
    if (_canceled) return p.amber;
    return p.rose;
  }

  Color _soft(QuickDropPalette p) {
    if (_success) return p.emeraldSoft;
    if (_canceled) return p.amberSoft;
    return p.roseSoft;
  }

  IconData get _icon {
    if (_success) return Icons.check_rounded;
    if (_canceled) return Icons.stop_rounded;
    return Icons.priority_high_rounded;
  }

  String get _headline {
    if (_success) return 'Sent to ${summary.peerName}';
    if (_canceled) return 'Transfer canceled';
    if (summary.sent == 0) return 'Transfer failed';
    return 'Some files did not send';
  }

  String get _subtitle {
    final files =
        '${summary.sent} of ${summary.total} file${summary.total == 1 ? '' : 's'} delivered';
    return '$files  ·  ${summary.formattedTotalSize}  ·  ${FileUtils.formatDuration(summary.elapsed)}';
  }

  String get _secondaryLabel => _success ? 'Send another' : 'Review files';

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: _soft(p),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: _accent(p),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: p.onAccent, size: 34),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 21,
              height: 1.3,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (!_success) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _soft(p),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent(p).withValues(alpha: 0.22)),
              ),
              child: Text(
                summary.firstError?.trim().isNotEmpty == true
                    ? summary.firstError!
                    : 'The other device may have gone offline. Files already delivered stay on disk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _accent(p) == p.amber ? p.amber : p.roseDark,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _Details(summary: summary),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Done'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onSecondary,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(_secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatefulWidget {
  final SendSummary summary;

  const _Details({required this.summary});

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final p = context.qd;
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: p.emeraldDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'View details',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 19,
                      color: p.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  _row('Recipient', summary.peerName, p),
                  _row(
                    'Files delivered',
                    '${summary.sent} of ${summary.total}',
                    p,
                  ),
                  _row('Total size', summary.formattedTotalSize, p),
                  _row(
                    'Duration',
                    FileUtils.formatDuration(summary.elapsed),
                    p,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'FILES',
                      style: TextStyle(
                        color: p.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final file in summary.files)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            file.success
                                ? Icons.check_circle_rounded
                                : file.error == 'Canceled'
                                ? Icons.remove_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            size: 15,
                            color: file.success
                                ? p.emeraldDark
                                : file.error == 'Canceled'
                                ? p.textFaint
                                : p.rose,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            file.formattedSize,
                            style: TextStyle(
                              color: p.textFaint,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, QuickDropPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: p.textMuted, fontSize: 11.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
