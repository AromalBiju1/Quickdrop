import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/models/device_peer.dart';
import 'package:quickdrop/models/link.dart';
import 'package:quickdrop/ui/components/device_card.dart';
import 'package:quickdrop/ui/components/link_chip.dart';

void main() {
  testWidgets('renders a label for every link kind', (tester) async {
    for (final kind in LinkKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: LinkChip(kind: kind)),
          ),
        ),
      );

      expect(
        find.text(kind.label),
        findsOneWidget,
        reason: 'link chip should label ${kind.name}',
      );
    }
  });

  testWidgets('device card shows the peer link', (tester) async {
    final peer = DevicePeer(
      id: 'dev_usb',
      name: 'Pixel',
      deviceType: 'mobile',
      ip: '192.168.42.10',
      httpPort: 53318,
      link: LinkKind.usb,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceCard(peer: peer, onSelect: () {}, onSend: () {}),
        ),
      ),
    );

    expect(find.text('USB'), findsOneWidget);
  });
}
