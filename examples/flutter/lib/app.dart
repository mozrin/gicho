import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

import 'features/component_gallery/index.dart';
import 'i18n/en.dart';

GichoMaterialApp buildApp() {
  final locales = GichoLocaleController(
    appCatalogs: const {'en': startupDemoEnglish},
  );

  return GichoMaterialApp(
    locales: locales,
    title: () => 'Gicho gallery',
    theme: gichoTheme(seedColor: Colors.teal),
    home: ComponentGallery(locales: locales),
  );
}
