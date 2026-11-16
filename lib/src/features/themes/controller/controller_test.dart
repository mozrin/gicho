import 'package:flutter/material.dart';
// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import '../catalog/index.dart';
import 'controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores only an allowed choice and saves theme and mode', () async {
    final saved = <String, String>{'gicho.theme.name': 'ember'};
    final catalog = await ThemeCatalog.load();
    final themes = ThemeController(
      catalog: catalog,
      available: ['default', 'ocean'],
      defaultName: 'ocean',
      readPreference: (key) async => saved[key],
      writePreference: (key, value) async {
        saved[key] = value;
      },
    );

    await themes.restore();
    expect(themes.name, 'ocean');
    expect(themes.mode, ThemeMode.system);

    await themes.select('default');
    await themes.setMode(ThemeMode.dark);
    expect(saved['gicho.theme.name'], 'default');
    expect(saved['gicho.theme.mode'], 'dark');
    expect(themes.darkTheme.brightness, Brightness.dark);
    expect(() => themes.select('ember'), throwsArgumentError);

    final restored = ThemeController(
      catalog: catalog,
      available: ['default', 'ocean'],
      defaultName: 'ocean',
      readPreference: (key) async => saved[key],
      writePreference: (key, value) async {
        saved[key] = value;
      },
    );
    await restored.restore();
    expect(restored.name, 'default');
    expect(restored.mode, ThemeMode.dark);
  });
}
