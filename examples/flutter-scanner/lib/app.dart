import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

import 'features/scan_demo/index.dart';
import 'i18n/en.dart';

GichoMaterialApp buildApp() {
  final locales = GichoLocaleController(
    appCatalogs: const {'en': exampleEnglish},
  );

  return GichoMaterialApp(
    locales: locales,
    title: () => locales.text('app.title'),
    theme: gichoTheme(seedColor: Colors.teal),
    home: GichoAppShell(
      title: locales.text('app.title'),
      locales: locales,
      body: ScanDemo(locales: locales),
    ),
  );
}
