import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/text_transfer.dart';

void main() {
  test('filename is timestamped and ends in .txt', () {
    final name = TextTransfer.fileName(at: DateTime(2026, 11, 5, 9, 7, 3));
    expect(name, 'QuickDrop-text-20261105-090703.txt');
    expect(name, endsWith('.txt'));
  });

  test('validation rejects empty, long and oversized text', () {
    expect(TextTransfer.validate('   '), isNotNull);
    expect(
      TextTransfer.validate(
        List.filled(TextTransfer.maxCharacters + 1, 'a').join(),
      ),
      isNotNull,
    );
    expect(TextTransfer.validate('hello'), isNull);
  });

  test('preview truncates and notification preview flattens whitespace', () {
    final long = List.filled(600, 'a').join();
    expect(TextTransfer.preview(long).length, 501);
    expect(
      TextTransfer.notificationPreview('  hello\n\nworld  '),
      'hello world',
    );
    expect(
      TextTransfer.notificationPreview(List.filled(100, 'a').join()).length,
      81,
    );
  });
}
