import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../quickdrop_theme.dart';
import 'top_notice.dart';

class QrDialog extends StatelessWidget {
  final String webUrl;
  final String deviceName;
  final VoidCallback onOpenBrowser;

  const QrDialog({
    super.key,
    required this.webUrl,
    required this.deviceName,
    required this.onOpenBrowser,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 16, 6),
      contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Receive from any device',
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
            style: IconButton.styleFrom(
              minimumSize: const Size(34, 34),
              maximumSize: const Size(34, 34),
            ),
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan this code with the other device’s camera. The browser receiver opens instantly, with no app or account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: QuickDropColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: QuickDropColors.border),
                ),
                child: QrImageView(
                  data: webUrl,
                  version: QrVersions.auto,
                  size: 220,
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
              const SizedBox(height: 14),
              SelectableText(
                webUrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: QuickDropColors.emeraldDark,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Receiving on $deviceName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: QuickDropColors.textMuted,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 13,
                    color: QuickDropColors.textFaint,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'No internet or installation needed',
                    style: TextStyle(
                      color: QuickDropColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: webUrl));
            if (context.mounted) {
              showTopNotice(
                context,
                const TopNotice(
                  message: 'Receiver URL copied',
                  icon: Icons.copy_rounded,
                ),
              );
            }
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy URL'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
        FilledButton.icon(
          onPressed: onOpenBrowser,
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Open here'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
