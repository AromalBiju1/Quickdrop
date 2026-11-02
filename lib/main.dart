import 'package:flutter/material.dart';

import 'core/app_store.dart';
import 'core/discovery_service.dart';
import 'core/share_receiver.dart';
import 'core/transfer_server.dart';
import 'ui/quickdrop_screen.dart';
import 'ui/quickdrop_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = await AppStore.loadSettings();

  final discoveryService = DiscoveryService(deviceName: settings.deviceName);
  final transferServer = TransferServer(
    deviceName: settings.deviceName,
    deviceId: discoveryService.deviceId,
  );

  await transferServer.start();
  await discoveryService.start();
  ShareReceiver.init();

  runApp(QuickDropApp(
    discoveryService: discoveryService,
    transferServer: transferServer,
    settings: settings,
  ));
}

class QuickDropApp extends StatelessWidget {
  final DiscoveryService discoveryService;
  final TransferServer transferServer;
  final AppSettings settings;

  const QuickDropApp({
    super.key,
    required this.discoveryService,
    required this.transferServer,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickDrop',
      debugShowCheckedModeBanner: false,
      theme: QuickDropTheme.lightTheme,
      home: QuickDropScreen(
        discoveryService: discoveryService,
        transferServer: transferServer,
        settings: settings,
      ),
    );
  }
}
