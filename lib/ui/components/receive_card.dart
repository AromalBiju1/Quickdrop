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
    final p = context.qd;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
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
                  color: p.emeraldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: p.emeraldDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receive without the app',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Use any browser on the same network.',
                      style: TextStyle(color: p.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final qr = _qr(p);
              final details = _details(p);
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
              Icon(Icons.folder_outlined, size: 15, color: p.textMuted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Files save to the received folder',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textMuted, fontSize: 11.5),
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
                icon: Icon(
                  Icons.help_outline_rounded,
                  size: 17,
                  color: p.textFaint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qr(QuickDropPalette p) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onShowQr,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: QrImageView(
          data: webUrl,
          version: QrVersions.auto,
          size: 116,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.onyx),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: p.onyx,
          ),
        ),
      ),
    );
  }

  Widget _details(QuickDropPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BROWSER ADDRESS',
          style: TextStyle(
            color: p.textMuted,
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
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    webUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.emeraldDark,
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.copy_rounded, size: 13, color: p.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Open this address in a browser on the other device, then drop files into the page. Nothing to install.',
          style: TextStyle(fontSize: 12, height: 1.5, color: p.textMuted),
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
          style: TextStyle(color: p.textFaint, fontSize: 10.5),
        ),
      ],
    );
  }
}
