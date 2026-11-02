import 'package:flutter/material.dart';

import '../../models/link.dart';
import '../quickdrop_theme.dart';

/// Small pill that names the network path a peer was discovered on.
class LinkChip extends StatelessWidget {
  final LinkKind kind;
  final bool compact;

  const LinkChip({super.key, required this.kind, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isUsb = kind == LinkKind.usb;
    final foreground = isUsb
        ? QuickDropColors.emeraldDark
        : QuickDropColors.textSecondary;
    final background = isUsb
        ? QuickDropColors.emeraldSoft
        : QuickDropColors.surfaceSubtle;
    final border = isUsb
        ? QuickDropColors.emeraldBorder
        : QuickDropColors.border;

    return Container(
      height: compact ? 18 : 20,
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(kind), size: compact ? 10 : 11, color: foreground),
          const SizedBox(width: 3),
          Text(
            kind.label,
            style: TextStyle(
              color: foreground,
              fontSize: compact ? 9 : 9.5,
              height: 1.1,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(LinkKind kind) => switch (kind) {
    LinkKind.usb => Icons.usb_rounded,
    LinkKind.bluetooth => Icons.bluetooth_rounded,
    LinkKind.wifi => Icons.wifi_rounded,
    LinkKind.ethernet => Icons.settings_ethernet_rounded,
    LinkKind.unknown => Icons.lan_rounded,
  };
}
