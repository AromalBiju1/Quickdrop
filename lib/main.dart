import 'package:flutter/material.dart';
import 'core/discovery_service.dart';
import 'core/share_receiver.dart';
import 'core/transfer_server.dart';
import 'ui/quickdrop_screen.dart';
import 'ui/quickdrop_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize core network services
  final discoveryService = DiscoveryService();
  final transferServer = TransferServer(deviceName: discoveryService.deviceName);

  await transferServer.start();
  await discoveryService.start();

  // 2. Initialize Android system share listener
  ShareReceiver.init();

  runApp(QuickDropApp(
    discoveryService: discoveryService,
    transferServer: transferServer,
  ));
}

class QuickDropApp extends StatelessWidget {
  final DiscoveryService discoveryService;
  final TransferServer transferServer;

  const QuickDropApp({
    super.key,
    required this.discoveryService,
    required this.transferServer,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickDrop',
      debugShowCheckedModeBanner: false,
      theme: QuickDropTheme.darkTheme,
      home: QuickDropScreen(
        discoveryService: discoveryService,
        transferServer: transferServer,
      ),
    );
  }
}
