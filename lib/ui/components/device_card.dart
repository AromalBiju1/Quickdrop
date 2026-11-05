import 'package:flutter/material.dart';

import '../../models/device_peer.dart';
import '../../models/link.dart';
import '../quickdrop_theme.dart';
import 'link_chip.dart';

class DeviceCard extends StatelessWidget {
  final DevicePeer peer;
  final bool selected;
  final bool isSending;
  final VoidCallback onSelect;
  final VoidCallback onSend;

  const DeviceCard({
    super.key,
    required this.peer,
    required this.onSelect,
    required this.onSend,
    this.selected = false,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    return Material(
      color: selected
          ? p.emeraldSoft.withValues(alpha: 0.55)
          : Colors.transparent,
      child: InkWell(
        onTap: isSending ? null : onSelect,
        hoverColor: p.surfaceMuted,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? p.emerald : p.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  peer.isDesktop
                      ? Icons.laptop_mac_rounded
                      : Icons.phone_android_rounded,
                  color: selected ? p.onAccent : p.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${peer.isDesktop ? 'Computer' : 'Phone'} · ${peer.address}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (peer.link != LinkKind.unknown) ...[
                          const SizedBox(width: 5),
                          LinkChip(kind: peer.link, compact: true),
                        ],
                        if (peer.isManual) ...[
                          const SizedBox(width: 5),
                          Tooltip(
                            message: 'Added by IP address',
                            child: Icon(
                              Icons.link_rounded,
                              size: 12,
                              color: p.textFaint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSending)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (selected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: p.emerald,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, size: 15, color: p.onAccent),
                )
              else
                IconButton(
                  tooltip: 'Send files to ${peer.name}',
                  onPressed: onSend,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    maximumSize: const Size(36, 36),
                    backgroundColor: p.surfaceMuted,
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    size: 17,
                    color: p.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
