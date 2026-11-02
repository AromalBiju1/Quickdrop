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
              color: QuickDropColors.emeraldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.usb_rounded,
              color: QuickDropColors.emeraldDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Use USB or Bluetooth',
              style: TextStyle(
                color: QuickDropColors.textPrimary,
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
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: QuickDropColors.textMuted,
            ),
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
              const Text(
                'No Wi-Fi? Tether this device to another one over a cable or '
                'Bluetooth. QuickDrop finds it the same way.',
                style: TextStyle(
                  color: QuickDropColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              _sectionLabel('DETECTED LINKS'),
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
                        color: QuickDropColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: QuickDropColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.link_off_rounded,
                            size: 16,
                            color: QuickDropColors.textFaint,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No tethering links detected yet.',
                              style: TextStyle(
                                color: QuickDropColors.textMuted,
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
                      color: QuickDropColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: QuickDropColors.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < links.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              indent: 12,
                              endIndent: 12,
                              color: QuickDropColors.surfaceSubtle,
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
                                    style: const TextStyle(
                                      color: QuickDropColors.textSecondary,
                                      fontSize: 11.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  links[i].ip,
                                  style: const TextStyle(
                                    color: QuickDropColors.textPrimary,
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
              _sectionLabel('USB TETHERING'),
              const SizedBox(height: 8),
              _step(
                1,
                'USB tethering',
                'Connect the phone to this computer with a USB cable, then '
                    'open Android Settings → Hotspot & tethering.',
              ),
              _step(
                2,
                'Turn it on',
                'Enable USB tethering. Linux detects the new interface '
                    'automatically, usually within a few seconds.',
              ),
              const SizedBox(height: 18),
              _sectionLabel('BLUETOOTH TETHERING'),
              const SizedBox(height: 8),
              _step(
                1,
                'Pair once',
                'Pair the phone and computer in their Bluetooth settings.',
              ),
              _step(
                2,
                'Bluetooth tethering',
                'Enable Bluetooth tethering on Android, then connect the '
                    'phone’s network in Linux Bluetooth or NetworkManager.',
              ),
              if (Platform.isAndroid) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => PlatformIntegrations.openHotspotSettings(),
                  icon: const Icon(Icons.settings_rounded, size: 17),
                  label: const Text('Open tethering settings'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: QuickDropColors.emeraldDark,
                    side: const BorderSide(
                      color: QuickDropColors.emeraldBorder,
                    ),
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: QuickDropColors.textMuted,
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _step(int number, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: QuickDropColors.emeraldSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: QuickDropColors.emeraldDark,
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
                  style: const TextStyle(
                    color: QuickDropColors.textPrimary,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: QuickDropColors.textMuted,
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
