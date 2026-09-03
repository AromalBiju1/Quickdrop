import 'package:flutter/material.dart';
import '../../models/device_peer.dart';
import '../quickdrop_theme.dart';

class DeviceCard extends StatelessWidget {
  final DevicePeer peer;
  final VoidCallback onSend;
  final bool isSending;

  const DeviceCard({
    super.key,
    required this.peer,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = peer.isDesktop;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSending ? QuickDropColors.cyan : QuickDropColors.border,
          width: isSending ? 2 : 1,
        ),
        boxShadow: isSending
            ? [
                BoxShadow(
                  color: QuickDropColors.cyan.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSending ? null : onSend,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Device Icon with Glow
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDesktop
                        ? QuickDropColors.cyan.withValues(alpha: 0.12)
                        : QuickDropColors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDesktop
                          ? QuickDropColors.cyan.withValues(alpha: 0.3)
                          : QuickDropColors.indigo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    isDesktop
                        ? Icons.laptop_chromebook_rounded
                        : Icons.phone_android_rounded,
                    color: isDesktop ? QuickDropColors.cyan : QuickDropColors.indigo,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Device Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              peer.name,
                              style: const TextStyle(
                                color: QuickDropColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: QuickDropColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'READY',
                              style: TextStyle(
                                color: QuickDropColors.emerald,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${peer.ip}:${peer.httpPort}',
                        style: const TextStyle(
                          color: QuickDropColors.textSecondary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Action Button
                FilledButton.icon(
                  onPressed: isSending ? null : onSend,
                  style: FilledButton.styleFrom(
                    backgroundColor: QuickDropColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                    isSending ? 'Sending...' : 'Send',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
