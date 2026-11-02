import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/discovery_service.dart';
import '../../core/platform_integrations.dart';
import '../quickdrop_theme.dart';

class HelpDialog extends StatelessWidget {
  final DiscoveryService discovery;

  const HelpDialog({super.key, required this.discovery});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
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
              Icons.wifi_off_rounded,
              color: QuickDropColors.emeraldDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection help',
                  style: TextStyle(
                    color: QuickDropColors.textPrimary,
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Offline transfers, explained',
                  style: TextStyle(
                    color: QuickDropColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
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
              _intro(),
              const SizedBox(height: 20),
              _section(
                icon: Icons.wifi_tethering_rounded,
                title: 'Use a hotspot',
                body:
                    'Turn on a phone hotspot, connect both devices to it and keep QuickDrop open. A hotspot without mobile data is enough — the devices only need to reach each other.',
              ),
              if (Platform.isAndroid) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final opened =
                          await PlatformIntegrations.openHotspotSettings();
                      if (!opened && context.mounted) {
                        _toast(
                          context,
                          'Open Wi-Fi settings manually to enable the hotspot.',
                        );
                      }
                    },
                    icon: const Icon(Icons.settings_rounded, size: 15),
                    label: const Text('Open hotspot settings'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      textStyle: const TextStyle(fontSize: 11.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _section(
                icon: Icons.lan_rounded,
                title: 'Same Wi-Fi, different subnet?',
                body:
                    'If discovery does not find the other device, use Connect by IP and enter its address. QuickDrop also scans the local subnet over HTTP when UDP broadcast is blocked.',
              ),
              const SizedBox(height: 18),
              _section(
                icon: Icons.usb_rounded,
                title: 'No network at all',
                body:
                    'USB tethering creates a local network without internet. Or connect the phone by USB and run this on the computer, then use Connect by IP with 127.0.0.1:53318:',
                code: 'adb reverse tcp:53319 tcp:53318',
              ),
              const SizedBox(height: 18),
              _section(
                icon: Icons.shield_outlined,
                title: 'Nothing is connecting?',
                body:
                    'A firewall is the usual culprit. Allow the receiver ports once on Linux, then press scan again in QuickDrop:',
                code: 'sudo ufw allow 53318/tcp && sudo ufw allow 53317/udp',
              ),
              const SizedBox(height: 18),
              _section(
                icon: Icons.language_rounded,
                title: 'No app on the other device',
                body:
                    'Open ${discovery.webUrl} in any browser on the same network and drop files into the page. Nothing to install.',
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, 44),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: QuickDropColors.emeraldSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QuickDropColors.emeraldBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.lock_outline_rounded,
              color: QuickDropColors.emeraldDark,
              size: 17,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'QuickDrop sends files directly between devices. Nothing is uploaded and no internet connection is used. Both devices just need to share a local network — Wi-Fi, a hotspot, or USB tethering.',
              style: TextStyle(
                color: QuickDropColors.emeraldDeep,
                fontSize: 11.5,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String body,
    String? code,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: QuickDropColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 15,
                color: QuickDropColors.emeraldDark,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: QuickDropColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 37),
          child: Text(
            body,
            style: const TextStyle(
              color: QuickDropColors.textMuted,
              fontSize: 11.5,
              height: 1.6,
            ),
          ),
        ),
        if (code != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 37),
            child: _codeBlock(code),
          ),
        ],
      ],
    );
  }

  Widget _codeBlock(String code) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: QuickDropColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: QuickDropColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: const TextStyle(
                color: QuickDropColors.textSecondary,
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy command',
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
            },
            icon: const Icon(
              Icons.copy_rounded,
              size: 14,
              color: QuickDropColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
