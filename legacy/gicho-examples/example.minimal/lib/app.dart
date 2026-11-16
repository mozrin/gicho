import 'package:flextension_auth_mock/flextension_auth_mock.dart';
import 'package:flextension_startup_showcase/flextension_startup_showcase.dart';
import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

class ExampleMinimalApp extends StatelessWidget {
  const ExampleMinimalApp({super.key, this.onReady});

  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) => GichoBootstrap(
    // notificationsEnabled: true,
    // localizationsEnabled: true,
    authenticationEnabled: true,
    authenticationDelegate: FlextensionAuthMock(),
    startupEnabled: true,
    startupDelegate: FlextensionStartupShowcase(),
    onReady: onReady,
    child: GichoMaterialApp.router(
      title: 'Minimal Gicho Example',
      router: GichoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              appBar: GichoAppBar(
                title: const Text('Minimal Gicho'),
                actionOverrides: const {
                  GichoAppBarFeature.brightnessToggle: true,
                  GichoAppBarFeature.themeSelector: true,
                  GichoAppBarFeature.languageSelector: false,
                  GichoAppBarFeature.configurationDisplay: false,
                  GichoAppBarFeature.logout: true,
                },
              ),
              body: Center(
                child: Text(
                  'A minimal consumer-owned Gicho page.\n\n'
                  'Localization available: '
                  '${GichoLocalization.of(context).isAvailable}\n'
                  'Notifications available: '
                  '${GichoNotifications.of(context).isAvailable}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
