import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gicho/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tagged package supplies its own configuration and catalogs', () async {
    final configuration = await const GichoConfigurationService()
        .loadApplication();
    expect(GichoBrand.fromConfiguration(configuration).name, 'Gicho');
    final locales = GichoLocaleController(
      enabledLocales: const [Locale('en'), Locale('th'), Locale('ar')],
      appCatalogs: const {
        'en': {'app.message': 'Public consumer'},
        'th': {'gicho.language.label': 'App-owned override'},
      },
    );
    locales.setLocale(const Locale('th'));
    expect(locales.text('gicho.language.label'), 'App-owned override');
    expect(locales.text('app.message'), 'Public consumer');
    expect(
      locales.text('gicho.navigation.open'),
      isNot('gicho.navigation.open'),
    );
    locales.dispose();
  });

  testWidgets('public entry composes an Arabic RTL application shell', (
    tester,
  ) async {
    final locales = GichoLocaleController(
      initialLocale: const Locale('ar'),
      enabledLocales: const [Locale('en'), Locale('ar')],
    );
    await tester.pumpWidget(
      GichoMaterialApp(
        locales: locales,
        title: () => 'Public consumer',
        theme: gichoTheme(seedColor: Colors.orange),
        home: GichoAppShell(
          title: 'Public consumer',
          locales: locales,
          body: const Text('Tagged Gicho works'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tagged Gicho works'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Tagged Gicho works'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    locales.dispose();
  });
}
