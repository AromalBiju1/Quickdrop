import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/models/device_peer.dart';

void main() {
  test('old history entries default to file', () {
    final item = TransferItem.fromJson({
      'id': 'rx_1',
      'file_name': 'photo.png',
      'file_size': 1024,
      'file_path': '/tmp/photo.png',
      'sender_name': 'Laptop',
      'is_incoming': true,
      'timestamp': '2026-11-02T10:00:00.000',
      'success': true,
    });
    expect(item.kind, TransferKind.file);
    expect(item.preview, isNull);
    expect(item.isText, isFalse);
  });

  test('text entries round-trip kind and preview', () {
    final original = TransferItem(
      id: 'tx_1',
      fileName: 'QuickDrop-text-test.txt',
      fileSize: 12,
      filePath: '/tmp/QuickDrop-text-test.txt',
      senderName: 'Pixel',
      isIncoming: false,
      timestamp: DateTime(2026, 11, 5, 10, 30),
      success: true,
      kind: TransferKind.text,
      preview: 'hello world',
    );
    final restored = TransferItem.fromJson(original.toJson());
    expect(restored.kind, TransferKind.text);
    expect(restored.preview, 'hello world');
    expect(restored.isText, isTrue);
  });
}
