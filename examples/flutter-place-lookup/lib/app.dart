import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

import 'features/place_choice/index.dart';

Widget buildApp() {
  final locales = GichoLocaleController();
  final theme = gichoTheme(seedColor: Colors.indigo);

  return GichoBootstrap<Map<String, dynamic>>(
    load: const GichoConfigurationService().loadApplication,
    title: 'Place lookup map',
    theme: theme,
    failureMessage: 'Could not load place lookup configuration.',
    retryLabel: 'Retry',
    readyBuilder: (_, configuration) => GichoMaterialApp(
      locales: locales,
      title: () => 'Place lookup map',
      theme: theme,
      home: GichoAppShell(
        title: 'Place lookup map',
        locales: locales,
        body: PlaceLookupMapScreen(configuration: configuration),
      ),
    ),
  );
}
