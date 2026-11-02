import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../quickdrop_theme.dart';

class ReceiveCard extends StatelessWidget {
  final String webUrl;
  final String deviceName;
  final VoidCallback onCopy;
  final VoidCallback onOpenBrowser;
  final VoidCallback onShowQr;
  final VoidCallback onOpenFolder;
  final VoidCallback onHelp;

  const ReceiveCard({
    super.key,
    required this.webUrl,
    required this.deviceName,
    required this.onCopy,
    required this.onOpenBrowser,
    required this.onShowQr,
    required this.onOpenFolder,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuickDropColors.border),
        boxShadow: QuickDropColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: QuickDropColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
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
                      'Receive without the app',
                      style: TextStyle(
                        color: QuickDropColors.textPrimary,
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Use any browser on the same network.',
                      style: TextStyle(
                        color: QuickDropColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final qr = _qr();
              final details = _details();
              if (constraints.maxWidth < 390) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [qr, const SizedBox(height: 16), details],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  qr,
                  const SizedBox(width: 18),
                  Expanded(child: details),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 15,
                color: QuickDropColors.textMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Files save to the received folder',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: QuickDropColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenFolder,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(fontSize: 11.5),
                ),
                child: const Text('Open folder'),
              ),
              IconButton(
                tooltip: 'Connection help',
                onPressed: onHelp,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  maximumSize: const Size(32, 32),
                ),
                icon: const Icon(
                  Icons.help_outline_rounded,
                  size: 17,
                  color: QuickDropColors.textFaint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qr() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onShowQr,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: QuickDropColors.border),
        ),
        child: QrImageView(
          data: webUrl,
          version: QrVersions.auto,
          size: 116,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: QuickDropColors.onyx,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: QuickDropColors.onyx,
          ),
        ),
      ),
    );
  }

  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BROWSER ADDRESS',
          style: TextStyle(
            color: QuickDropColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onCopy,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: QuickDropColors.surfaceMuted,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: QuickDropColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    webUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: QuickDropColors.emeraldDark,
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: QuickDropColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Open this address in a browser on the other device, then drop files into the page. Nothing to install.',
          style: QuickDropText.small,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onOpenBrowser,
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('Open here'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onShowQr,
              icon: const Icon(Icons.qr_code_2_rounded, size: 16),
              label: const Text('Show QR'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Receiving on $deviceName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: QuickDropColors.textFaint,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
