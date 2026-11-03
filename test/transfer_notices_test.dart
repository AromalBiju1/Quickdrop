import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/quickdrop_controller.dart';
import 'package:quickdrop/models/device_peer.dart';
import 'package:quickdrop/ui/components/top_notice.dart';
import 'package:quickdrop/ui/transfer_notices.dart';

TransferItem _item(String name, {String sender = 'Laptop', String? id}) {
  return TransferItem(
    id: id ?? 'rx_$name',
    fileName: name,
    fileSize: 1024,
    filePath: '/tmp/$name',
    senderName: sender,
    isIncoming: true,
    timestamp: DateTime(2026, 11, 2),
    success: true,
  );
}

SendSummary _summary({
  int sent = 1,
  int failed = 0,
  bool canceled = false,
  int total = 1,
  String? firstError,
}) {
  return SendSummary(
    sent: sent,
    failed: failed,
    canceled: canceled,
    total: total,
    peerName: 'Pixel',
    firstError: firstError,
    files: const [],
    totalBytes: 2048,
    elapsed: const Duration(seconds: 1),
  );
}

void main() {
  test('single received file notice names the file and sender', () {
    final notice = buildReceiveNotice([_item('photo.png')]);

    expect(notice.message, 'File received');
    expect(notice.detail, 'photo.png from Laptop');
    expect(notice.actionLabel, 'View');
    expect(notice.tone, TopNoticeTone.success);
    expect(notice.duration, const Duration(seconds: 6));
  });

  test('a batch of received files becomes one grouped notice', () {
    final notice = buildReceiveNotice([
      _item('photo.png'),
      _item('clip.mov'),
      _item('notes.pdf'),
    ]);

    expect(notice.message, '3 files received');
    expect(notice.detail, 'from Laptop');
    expect(notice.actionLabel, 'View');
  });

  test('successful send notice summarizes the transfer', () {
    final notice = buildSendNotice(_summary(sent: 3, total: 3));

    expect(notice.message, 'Sent 3 files');
    expect(notice.detail, 'to Pixel');
    expect(notice.tone, TopNoticeTone.success);
    expect(notice.actionLabel, 'View');
  });

  test('canceled send notice reports partial delivery', () {
    final notice = buildSendNotice(_summary(
      sent: 2,
      total: 4,
      canceled: true,
    ));

    expect(notice.message, 'Transfer canceled');
    expect(notice.detail, '2 of 4 files sent to Pixel');
    expect(notice.tone, TopNoticeTone.warning);
  });

  test('failed send notice surfaces the first error', () {
    final notice = buildSendNotice(_summary(
      sent: 1,
      failed: 2,
      total: 3,
      firstError: 'Connection reset',
    ));

    expect(notice.message, 'Sent 1 of 3 files');
    expect(notice.detail, 'Connection reset');
    expect(notice.tone, TopNoticeTone.error);
  });
}
