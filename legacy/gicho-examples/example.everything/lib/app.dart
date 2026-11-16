import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

import 'navigation/app_router.dart';

final GichoRouter appRouter = createRouter();

/// The consumer-owned application seam.
///
/// Add application-specific wrappers here. Gicho owns the standard
/// startup and MaterialApp setup inside [GichoMaterialApp].
class GichoApp extends StatelessWidget {
  const GichoApp({
    super.key,
    this.router,
    this.bootstrap = true,
    this.onReady,
  });

  final GichoRouter? router;
  final bool bootstrap;
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) {
    final application = GichoMaterialApp.router(
      title: 'Moztopia Navigation',
      router: router ?? appRouter,
    );
    return ProviderScope(
      child: bootstrap
          ? GichoBootstrap(
              localizationsEnabled: true,
              notificationsEnabled: true,
              saveLocale: false,
              onReady: onReady,
              child: application,
            )
          : application,
    );
  }
}
