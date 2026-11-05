import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/models/device_peer.dart';
import 'package:quickdrop/ui/components/transfer_history_tile.dart';
import 'package:quickdrop/ui/quickdrop_theme.dart';

TransferItem _textItem({String preview = 'https://example.com\nsecond line'}) {
  return TransferItem(
    id: 'tx_text',
    fileName: 'QuickDrop-text-test.txt',
    fileSize: 24,
    filePath: '',
    senderName: 'Pixel',
    isIncoming: false,
    timestamp: DateTime(2026, 11, 5, 10, 30),
    success: true,
    kind: TransferKind.text,
    preview: preview,
  );
}

void main() {
  testWidgets('text history tile shows the first preview line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuickDropTheme.light,
        home: Scaffold(body: TransferHistoryTile(item: _textItem())),
      ),
    );

    expect(find.text('https://example.com'), findsOneWidget);
    expect(find.byIcon(Icons.notes_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Copy text'), findsOneWidget);
  });

  testWidgets('copy text reads a saved .txt into the clipboard', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('quickdrop_tile_text_');
    final file = File('${dir.path}/saved.txt');
    file.writeAsStringSync('full saved text');
    addTearDown(() => dir.deleteSync(recursive: true));

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final item = TransferItem(
      id: 'rx_text',
      fileName: 'saved.txt',
      fileSize: 15,
      filePath: file.path,
      senderName: 'Laptop',
      isIncoming: true,
      timestamp: DateTime(2026, 11, 5),
      success: true,
      kind: TransferKind.text,
      preview: 'short preview',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: QuickDropTheme.light,
        home: Scaffold(body: TransferHistoryTile(item: item)),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy text'));
    await tester.pumpAndSettle();

    expect(copied, 'full saved text');
  });
}
