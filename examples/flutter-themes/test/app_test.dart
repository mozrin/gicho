import 'package:gicho/gicho.dart';
import 'package:gicho_themes_example/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ThemeCatalog catalog;
  setUpAll(() async {
    catalog = await ThemeCatalog.load();
  });

  test('loads app theme choices from package and consumer assets', () async {
    final configuration = await const GichoConfigurationService()
        .loadApplication();
    final themes = ThemeController.fromConfiguration(
      catalog: catalog,
      configuration: configuration,
      readPreference: (_) async => null,
      writePreference: (_, _) async {},
    );

    expect(themes.available, ['default', 'ocean', 'ember']);
    expect(themes.name, 'ocean');
    expect(themes.lightTheme.brightness, Brightness.light);
    expect(themes.darkTheme.brightness, Brightness.dark);
  });

  testWidgets('theme picker works at phone, tablet and large widths', (
    tester,
  ) async {
    final saved = <String, String>{};
    final themes = ThemeController(
      catalog: catalog,
      available: ['default', 'ocean', 'ember'],
      defaultName: 'ocean',
      readPreference: (key) async => saved[key],
      writePreference: (key, value) async {
        saved[key] = value;
      },
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final width in [390.0, 900.0, 1400.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(buildApp(load: () async => themes));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ocean'), findsOneWidget);
    }

    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ember').last);
    await tester.pumpAndSettle();
    expect(themes.name, 'ember');
    expect(saved['gicho.theme.name'], 'ember');
  });
}
