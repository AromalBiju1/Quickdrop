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
      // Listen to incoming shares while the app is in memory
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            final paths = value.map((f) => f.path).toList();
            sharedFilesNotifier.value = paths;
            if (onFilesShared != null) onFilesShared(paths);
          }
        },
        onError: (err) {
          debugPrint('[ShareReceiver] Stream error: $err');
        },
      );

      // Check for share that launched the app from cold start
      ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          final paths = value.map((f) => f.path).toList();
          sharedFilesNotifier.value = paths;
          if (onFilesShared != null) onFilesShared(paths);
          ReceiveSharingIntent.instance.reset();
        }
      }).catchError((err) {
        debugPrint('[ShareReceiver] Initial media error: $err');
      });
    } catch (e) {
      debugPrint('[ShareReceiver] Failed to init: $e');
    }
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
  }
}
