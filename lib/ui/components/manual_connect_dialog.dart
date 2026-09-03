import 'package:flutter/material.dart';
import '../quickdrop_theme.dart';

class ManualConnectDialog extends StatefulWidget {
  final String myIp;
  final int myPort;
  final void Function(String ip) onConnect;

  const ManualConnectDialog({
    super.key,
    required this.myIp,
    required this.myPort,
    required this.onConnect,
  });

  @override
  State<ManualConnectDialog> createState() => _ManualConnectDialogState();
}

class _ManualConnectDialogState extends State<ManualConnectDialog> {
  final _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: QuickDropColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: QuickDropColors.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.link_rounded, color: QuickDropColors.cyan),
          SizedBox(width: 10),
          Text(
            'Direct IP Connect',
            style: TextStyle(
              color: QuickDropColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'If your router blocks UDP broadcast, enter your other device\'s IP address directly:',
            style: TextStyle(color: QuickDropColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ipController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: QuickDropColors.textPrimary,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 192.168.1.50',
              hintStyle: const TextStyle(color: QuickDropColors.textMuted),
              filled: true,
              fillColor: QuickDropColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: QuickDropColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: QuickDropColors.cyan),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: QuickDropColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: QuickDropColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: QuickDropColors.cyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This device: ${widget.myIp}:${widget.myPort}',
                    style: const TextStyle(
                      color: QuickDropColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: QuickDropColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: QuickDropColors.cyan,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final ip = _ipController.text.trim();
            if (ip.isNotEmpty) {
              widget.onConnect(ip);
              Navigator.pop(context);
            }
          },
          child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
