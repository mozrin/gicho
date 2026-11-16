import 'package:flutter/material.dart';
// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import '../../features/localization/locale_controller/index.dart';
import 'index.dart';

void main() {
  testWidgets('uses the consumer theme and updates title and locale', (
    tester,
  ) async {
    final locales = GichoLocaleController(
      enabledLocales: const [Locale('en'), Locale('th')],
      appCatalogs: const {
        'en': {'app.title': 'My app'},
        'th': {'app.title': 'แอปของฉัน'},
      },
    );
    addTearDown(locales.dispose);
    final theme = ThemeData(colorSchemeSeed: Colors.teal);

    await tester.pumpWidget(
      GichoMaterialApp(
        locales: locales,
        title: () => locales.text('app.title'),
        theme: theme,
        home: const Scaffold(body: Text('Home')),
      ),
    );

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'My app',
    );
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).theme, theme);
    expect(find.text('Home'), findsOneWidget);

    locales.setLocale(const Locale('th'));
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'แอปของฉัน');
    expect(app.locale, const Locale('th'));
    expect(app.supportedLocales, const [Locale('en'), Locale('th')]);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('an enabled Arabic locale gives the application RTL direction', (
    tester,
  ) async {
    final locales = GichoLocaleController(
      initialLocale: const Locale('ar'),
      enabledLocales: const [Locale('en'), Locale('ar')],
    );
    addTearDown(locales.dispose);

    await tester.pumpWidget(
      GichoMaterialApp(
        locales: locales,
        title: () => 'Example',
        theme: ThemeData(),
        home: const Scaffold(body: Text('مرحبا')),
      ),
    );

    expect(
      Directionality.of(tester.element(find.text('مرحبا'))),
      TextDirection.rtl,
    );
  });
}
