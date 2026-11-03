import 'package:flutter/foundation.dart';

import '../core/quickdrop_controller.dart';
import '../models/device_peer.dart';
import 'components/top_notice.dart';

/// Builds the grouped banner for one or more incoming files.
TopNotice buildReceiveNotice(
  List<TransferItem> items, {
  VoidCallback? onView,
}) {
  assert(items.isNotEmpty);
  final first = items.first;
  final count = items.length;
  final sender = first.senderName.isEmpty ? 'another device' : first.senderName;

  return TopNotice(
    message: count == 1 ? 'File received' : '$count files received',
    detail: count == 1
        ? '${first.fileName} from $sender'
        : 'from $sender',
    tone: TopNoticeTone.success,
    duration: const Duration(seconds: 6),
    actionLabel: 'View',
    onAction: onView,
  );
}

/// Builds the banner shown when an outgoing transfer finishes.
TopNotice buildSendNotice(
  SendSummary summary, {
  VoidCallback? onView,
}) {
  if (summary.canceled) {
    return TopNotice(
      message: 'Transfer canceled',
      detail:
          '${summary.sent} of ${summary.total} files sent to ${summary.peerName}',
      tone: TopNoticeTone.warning,
      duration: const Duration(seconds: 6),
      actionLabel: 'View',
      onAction: onView,
    );
  }

  if (summary.failed > 0) {
    return TopNotice(
      message: 'Sent ${summary.sent} of ${summary.total} files',
      detail: summary.firstError ?? '${summary.failed} files failed',
      tone: TopNoticeTone.error,
      duration: const Duration(seconds: 6),
      actionLabel: 'View',
      onAction: onView,
    );
  }

  return TopNotice(
    message: 'Sent ${summary.sent} file${summary.sent == 1 ? '' : 's'}',
    detail: 'to ${summary.peerName}',
    tone: TopNoticeTone.success,
    duration: const Duration(seconds: 6),
    actionLabel: 'View',
    onAction: onView,
  );
}
