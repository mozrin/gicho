import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

import 'features/about_flow/index.dart';

GichoMaterialApp buildApp() {
  final locales = GichoLocaleController();

  return GichoMaterialApp(
    locales: locales,
    title: () => 'Page flow',
    theme: gichoTheme(seedColor: Colors.teal),
    home: GichoAppShell(
      title: 'Page flow',
      locales: locales,
      body: const AboutFlow(),
    ),
  );
}
