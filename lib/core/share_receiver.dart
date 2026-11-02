import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareReceiver {
  static StreamSubscription? _intentSub;
  static final ValueNotifier<List<String>> sharedFilesNotifier =
      ValueNotifier<List<String>>([]);

  static void init({void Function(List<String> paths)? onFilesShared}) {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
          _publish(value, onFilesShared);
        },
        onError: (err) {
          debugPrint('[ShareReceiver] Stream error: $err');
        },
      );

      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        _publish(value, onFilesShared);
        if (value.isNotEmpty) {
          ReceiveSharingIntent.instance.reset();
        }
      }).catchError((err) {
        debugPrint('[ShareReceiver] Initial media error: $err');
      });
    } catch (e) {
      debugPrint('[ShareReceiver] Failed to init: $e');
    }
  }

  static void _publish(
    List<SharedMediaFile> value,
    void Function(List<String> paths)? onFilesShared,
  ) {
    if (value.isEmpty) return;
    final paths = <String>[];
    for (final file in value) {
      if (file.path.isNotEmpty && !paths.contains(file.path)) {
        paths.add(file.path);
      }
    }
    if (paths.isEmpty) return;
    sharedFilesNotifier.value = paths;
    onFilesShared?.call(paths);
  }

  static void removePath(String path) {
    final next = List<String>.from(sharedFilesNotifier.value)..remove(path);
    sharedFilesNotifier.value = next;
  }

  static void clear() {
    sharedFilesNotifier.value = [];
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        ReceiveSharingIntent.instance.reset();
      } catch (_) {}
    }
  }

  static void dispose() {
    _intentSub?.cancel();
    _intentSub = null;
  }
}
