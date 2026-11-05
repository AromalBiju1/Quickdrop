import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/quickdrop_controller.dart';
import '../../core/text_transfer.dart';
import '../quickdrop_theme.dart';

class TextComposerSheet extends StatefulWidget {
  final QuickDropController controller;

  const TextComposerSheet({super.key, required this.controller});

  static Future<bool?> show(
    BuildContext context,
    QuickDropController controller,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TextComposerSheet(controller: controller),
    );
  }

  @override
  State<TextComposerSheet> createState() => _TextComposerSheetState();
}

class _TextComposerSheetState extends State<TextComposerSheet> {
  final TextEditingController _field = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.isEmpty) {
        setState(() => _error = 'The clipboard is empty.');
        return;
      }
      _field.text = text;
      _field.selection = TextSelection.collapsed(offset: text.length);
      setState(() => _error = null);
    } catch (_) {
      setState(() => _error = 'Could not read the clipboard.');
    }
  }

  Future<void> _send() async {
    final peer = widget.controller.selectedPeer;
    if (peer == null) {
      setState(() => _error = 'Select a nearby device first.');
      return;
    }
    final text = _field.text;
    final validation = TextTransfer.validate(text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final result = await widget.controller.sendTextToPeer(peer, text);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _sending = false;
      _error = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    final peer = widget.controller.selectedPeer;
    final overLimit = _field.text.length > TextTransfer.maxCharacters;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        Icons.notes_rounded,
                        color: p.emeraldDark,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Send text', style: context.text.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            peer == null
                                ? 'Select a nearby device first.'
                                : 'To ${peer.name}',
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _sending
                          ? null
                          : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _field,
                  enabled: !_sending,
                  minLines: 6,
                  maxLines: 10,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) {
                    setState(() {
                      _error = null;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Paste a link or type a snippet…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        overLimit
                            ? 'Too long by '
                                  '${_field.text.length - TextTransfer.maxCharacters}'
                                  ' characters'
                            : 'Copied to the receiver’s clipboard',
                        style: TextStyle(
                          color: overLimit ? p.rose : p.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '${_field.text.length} / ${TextTransfer.maxCharacters}',
                      style: TextStyle(
                        color: overLimit ? p.rose : p.textFaint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(color: p.rose, fontSize: 11.5),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _sending ? null : _paste,
                      icon: const Icon(Icons.content_paste_rounded, size: 16),
                      label: const Text('Paste'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _sending ||
                                peer == null ||
                                _field.text.trim().isEmpty ||
                                overLimit
                            ? null
                            : _send,
                        icon: _sending
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: p.onAccent,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(_sending ? 'Sending…' : 'Send'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
