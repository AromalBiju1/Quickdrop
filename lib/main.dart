import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_store.dart';
import 'core/discovery_service.dart';
import 'core/share_receiver.dart';
import 'core/transfer_server.dart';
import 'ui/components/top_notice.dart';
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

  runApp(
    QuickDropApp(
      discoveryService: discoveryService,
      transferServer: transferServer,
      settings: settings,
    ),
  );
}

class QuickDropApp extends StatefulWidget {
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
  State<QuickDropApp> createState() => _QuickDropAppState();
}

class _QuickDropAppState extends State<QuickDropApp> {
  final TopNoticeCenter _notices = TopNoticeCenter();
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.settings.themeMode;
  }

  @override
  void dispose() {
    _notices.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TopNoticeScope(
      controller: _notices,
      child: MaterialApp(
        title: 'QuickDrop',
        debugShowCheckedModeBanner: false,
        theme: QuickDropTheme.light,
        darkTheme: QuickDropTheme.dark,
        themeMode: _themeMode,
        builder: (context, child) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value:
                (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                    .copyWith(
                      statusBarColor: Colors.transparent,
                      systemNavigationBarColor: context.qd.background,
                      systemNavigationBarIconBrightness: dark
                          ? Brightness.light
                          : Brightness.dark,
                    ),
            child: TopNoticeHost(
              controller: _notices,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: QuickDropScreen(
          discoveryService: widget.discoveryService,
          transferServer: widget.transferServer,
          settings: widget.settings,
          onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        ),
      ),
    );
  }
}
