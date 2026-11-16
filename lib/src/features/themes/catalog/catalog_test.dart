// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads three stable named themes with light and dark variants',
    () async {
      final catalog = await ThemeCatalog.load();

      expect(ThemeCatalog.names, ['default', 'ocean', 'ember']);
      expect(catalog.displayName('ocean'), 'Ocean');
      for (final name in ThemeCatalog.names) {
        expect(
          catalog.theme(name, Brightness.light).brightness,
          Brightness.light,
        );
        expect(
          catalog.theme(name, Brightness.dark).brightness,
          Brightness.dark,
        );
      }
      expect(
        catalog.theme('ocean', Brightness.light).colorScheme.primary,
        isNot(catalog.theme('ember', Brightness.light).colorScheme.primary),
      );
    },
  );
}
