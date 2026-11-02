import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_store.dart';
import '../../core/quickdrop_controller.dart';
import '../quickdrop_theme.dart';
import 'file_thumb.dart';

class SettingsDialog extends StatefulWidget {
  final QuickDropController controller;
  final VoidCallback onOpenFolder;

  const SettingsDialog({
    super.key,
    required this.controller,
    required this.onOpenFolder,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _nameController;
  late bool _autoCopy;
  late bool _notifications;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.settings;
    _nameController = TextEditingController(text: settings.deviceName);
    _autoCopy = settings.autoCopyImages;
    _notifications = settings.notifications;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give this device a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await widget.controller.updateSettings(AppSettings(
      deviceName: name,
      autoCopyImages: _autoCopy,
      notifications: _notifications,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final discovery = widget.controller.discovery;
    final running = widget.controller.server.isRunningNotifier.value;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      title: Row(
        children: [
          const QuickDropLogo(size: 36),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
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
                  'QuickDrop 2.0',
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
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel('DEVICE'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                maxLength: 32,
                enabled: !_saving,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: const TextStyle(
                  color: QuickDropColors.textPrimary,
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: 'My laptop',
                  errorText: _error,
                  counterStyle: const TextStyle(
                    color: QuickDropColors.textFaint,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Shown to nearby devices and in the browser receiver.',
                style: TextStyle(
                  color: QuickDropColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 18),
              _sectionLabel('RECEIVING'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: QuickDropColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: QuickDropColors.border),
                ),
                child: Column(
                  children: [
                    _toggleRow(
                      title: 'Copy received images',
                      subtitle: 'Put the latest image on the clipboard.',
                      value: _autoCopy,
                      onChanged: (value) => setState(() => _autoCopy = value),
                    ),
                    const Divider(),
                    _toggleRow(
                      title: 'Desktop notifications',
                      subtitle: 'Show a notification when a file arrives.',
                      value: _notifications,
                      onChanged: (value) =>
                          setState(() => _notifications = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder(
                future: widget.controller.server.getLastSaveDirectory(),
                builder: (context, snapshot) {
                  final path = Platform.isAndroid
                      ? 'Download/QuickDrop'
                      : (snapshot.data?.path ?? '…');
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: QuickDropColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: QuickDropColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          color: QuickDropColors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SAVE LOCATION',
                                style: TextStyle(
                                  color: QuickDropColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                path,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: QuickDropColors.textSecondary,
                                  fontSize: 10.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open folder',
                          onPressed: widget.onOpenFolder,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(30, 30),
                            maximumSize: const Size(30, 30),
                          ),
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 18),
              _sectionLabel('CONNECTION'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: QuickDropColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: QuickDropColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Receiver',
                            style: TextStyle(
                              color: QuickDropColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: running ? 'Online' : 'Offline',
                          foreground: running
                              ? QuickDropColors.emeraldDark
                              : QuickDropColors.roseDark,
                          background: running
                              ? QuickDropColors.emeraldSoft
                              : QuickDropColors.roseSoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const SizedBox(
                          width: 82,
                          child: Text(
                            'Local address',
                            style: TextStyle(
                              color: QuickDropColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            '${discovery.localIp}:${discovery.httpPort}',
                            style: const TextStyle(
                              color: QuickDropColors.textPrimary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const SizedBox(
                          width: 82,
                          child: Text(
                            'Device ID',
                            style: TextStyle(
                              color: QuickDropColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            discovery.deviceId,
                            maxLines: 1,
                            style: const TextStyle(
                              color: QuickDropColors.textMuted,
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 14,
                    color: QuickDropColors.textFaint,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Works offline on a local network or hotspot.',
                      style: TextStyle(
                        color: QuickDropColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: QuickDropColors.textSecondary,
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, 44),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _saving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save changes'),
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

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: QuickDropColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: QuickDropColors.textMuted,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
