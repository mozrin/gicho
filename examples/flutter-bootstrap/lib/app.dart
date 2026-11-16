import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

GichoBootstrap<Map<String, dynamic>> buildApp({
  Future<Map<String, dynamic>> Function()? load,
}) {
  final theme = gichoTheme(seedColor: Colors.teal);
  final locales = GichoLocaleController();

  return GichoBootstrap<Map<String, dynamic>>(
    load: load ?? const GichoConfigurationService().loadApplication,
    title: 'Bootstrap',
    theme: theme,
    failureMessage: 'Could not start.',
    retryLabel: 'Retry',
    readyBuilder: (_, configuration) {
      final brand = GichoBrand.fromConfiguration(configuration);
      return GichoMaterialApp(
        locales: locales,
        title: () => brand.name,
        theme: theme,
        home: GichoAppShell(
          title: brand.name,
          brand: brand,
          locales: locales,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GichoBrandHeader.branded(brand: brand),
                const SizedBox(height: 24),
                Text((configuration['app'] as Map)['startupMessage'] as String),
              ],
            ),
          ),
        ),
      );
    },
  );
}
