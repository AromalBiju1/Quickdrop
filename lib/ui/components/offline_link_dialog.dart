import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/link_manager.dart';
import '../../core/platform_integrations.dart';
import '../quickdrop_theme.dart';
import 'link_chip.dart';

/// Explains how to keep QuickDrop working when there is no Wi-Fi network.
class OfflineLinkDialog extends StatelessWidget {
  final LinkManager linkManager;

  const OfflineLinkDialog({super.key, required this.linkManager});

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 16, 6),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.emeraldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.usb_rounded, color: p.emeraldDark, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Use USB or Bluetooth',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              maximumSize: const Size(32, 32),
            ),
            icon: Icon(Icons.close_rounded, size: 18, color: p.textMuted),
          ),
        ],
      ),
      content: SizedBox(
        width: 470,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'No Wi-Fi? Tether this device to another one over a cable or '
                'Bluetooth. QuickDrop finds it the same way.',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              _sectionLabel('DETECTED LINKS', p),
              const SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: linkManager.linksNotifier,
                builder: (context, links, _) {
                  if (links.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link_off_rounded,
                            size: 16,
                            color: p.textFaint,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No tethering links detected yet.',
                              style: TextStyle(
                                color: p.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < links.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 12,
                              endIndent: 12,
                              color: p.surfaceSubtle,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            child: Row(
                              children: [
                                LinkChip(kind: links[i].kind),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    links[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: p.textSecondary,
                                      fontSize: 11.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  links[i].ip,
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontSize: 11.5,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _sectionLabel('USB TETHERING', p),
              const SizedBox(height: 8),
              _step(
                1,
                'USB tethering',
                'Connect the phone to this computer with a USB cable, then '
                    'open Android Settings → Hotspot & tethering.',
                p,
              ),
              _step(
                2,
                'Turn it on',
                'Enable USB tethering. Linux detects the new interface '
                    'automatically, usually within a few seconds.',
                p,
              ),
              const SizedBox(height: 18),
              _sectionLabel('BLUETOOTH TETHERING', p),
              const SizedBox(height: 8),
              _step(
                1,
                'Pair once',
                'Pair the phone and computer in their Bluetooth settings.',
                p,
              ),
              _step(
                2,
                'Bluetooth tethering',
                'Enable Bluetooth tethering on Android, then connect the '
                    'phone’s network in Linux Bluetooth or NetworkManager.',
                p,
              ),
              if (Platform.isAndroid) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => PlatformIntegrations.openHotspotSettings(),
                  icon: const Icon(Icons.settings_rounded, size: 17),
                  label: const Text('Open tethering settings'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: p.emeraldDark,
                    side: BorderSide(color: p.emeraldBorder),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 42),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text, QuickDropPalette p) {
    return Text(
      text,
      style: TextStyle(
        color: p.textMuted,
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _step(int number, String title, String body, QuickDropPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: p.emeraldSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                color: p.emeraldDark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: p.textMuted,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
