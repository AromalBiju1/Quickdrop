import 'package:flutter/material.dart';

import '../../core/discovery_service.dart';
import '../quickdrop_theme.dart';

class ManualConnectDialog extends StatefulWidget {
  final DiscoveryService discovery;

  const ManualConnectDialog({super.key, required this.discovery});

  @override
  State<ManualConnectDialog> createState() => _ManualConnectDialogState();
}

class _ManualConnectDialogState extends State<ManualConnectDialog> {
  final _ipController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final input = _ipController.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Enter the other device’s IP address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.discovery.addManualPeer(input);
    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context, result);
      return;
    }
    setState(() {
      _loading = false;
      _error = result.message;
    });
  }

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
              color: context.qd.emeraldSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.add_link_rounded,
              color: context.qd.emeraldDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect by IP',
                  style: TextStyle(
                    color: context.qd.textPrimary,
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'For networks that block discovery.',
                  style: TextStyle(
                    color: context.qd.textMuted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open QuickDrop on the other device and read its address from the Receive tab. Enter the address here.',
                style: TextStyle(
                  color: context.qd.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                autofocus: true,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                enabled: !_loading,
                onSubmitted: (_) => _connect(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: TextStyle(
                  color: context.qd.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: '192.168.1.42 or 192.168.1.42:53318',
                  labelText: 'Device address',
                  errorText: _error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.qd.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.qd.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.computer_rounded,
                      color: context.qd.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This device · ${widget.discovery.localIp}:${widget.discovery.httpPort}',
                        style: TextStyle(
                          color: context.qd.textSecondary,
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: context.qd.textSecondary,
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _connect,
          style: FilledButton.styleFrom(
            minimumSize: const Size(110, 44),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _loading
              ? SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.qd.onAccent,
                  ),
                )
              : const Text('Connect'),
        ),
      ],
    );
  }
}
