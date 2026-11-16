import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

import 'features/distance_selection/index.dart';

GichoMaterialApp buildApp() {
  final locales = GichoLocaleController();

  return GichoMaterialApp(
    locales: locales,
    title: () => 'Distance slider',
    theme: gichoTheme(seedColor: Colors.teal),
    home: GichoAppShell(
      title: 'Distance slider',
      locales: locales,
      body: const DistanceSelection(),
    ),
  );
}
