import 'package:example_everything/app.dart';
import 'package:example_everything/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await moztopiaLog.initialize();
    await moztopiaCore.initialize();
    await moztopiaTheme.initialize();
  });

  Future<Widget> buildApp(GichoRouter router) => moztopiaLocalization.create(
    useOnlyLangCode: true,
    saveLocale: false,
    child: GichoApp(router: router, bootstrap: false),
  );

  Future<void> pumpApp(WidgetTester tester, GichoRouter router) async {
    final application = await tester.runAsync(() => buildApp(router));
    await tester.pumpWidget(application!);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('drawer opens secondary destinations', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Example navigation'), findsOneWidget);
    expect(find.text('DNav1'), findsOneWidget);
    expect(find.text('Logging'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(3));
    expect(
      find.descendant(of: find.byType(Drawer), matching: find.text('FNav1')),
      findsNothing,
    );
    await tester.tap(find.text('DNav1'));
    await tester.pumpAndSettle();
    expect(find.text('Drawer destination one.'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('Logging opens as a complete Material page', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logging'));
    await tester.pumpAndSettle();

    expect(find.text('Logging'), findsOneWidget);
    expect(find.text('Logger showcase'), findsOneWidget);
    expect(find.text('Log every level'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('unknown routes show a recoverable 404 page', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    router.go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
    expect(find.text('404'), findsOneWidget);
    expect(
      find.text('No example page exists at /does-not-exist.'),
      findsOneWidget,
    );
    expect(find.text('Return to FNav1'), findsOneWidget);

    await tester.tap(find.text('Return to FNav1'));
    await tester.pumpAndSettle();
    expect(find.text('FNav1 overview'), findsOneWidget);
  });

  testWidgets('bottom navigation changes primary tabs', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    await tester.tap(find.text('FNav2'));
    await tester.pumpAndSettle();
    expect(find.text('FNav2 item 1'), findsOneWidget);
  });

  testWidgets('config inspector switches features across all three stages', (
    tester,
  ) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    await tester.tap(find.text('Config'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuration inspector'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Configuration inspector'), findsWidgets);
    expect(find.textContaining('debug: green'), findsOneWidget);

    await tester.tap(find.text('App'));
    await tester.pumpAndSettle();
    expect(find.textContaining('debug: purple'), findsOneWidget);

    await tester.tap(find.text('Merged'));
    await tester.pumpAndSettle();
    expect(find.textContaining('debug: purple'), findsOneWidget);

    await tester.tap(find.text('Logging'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Localization').last);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.textContaining('fallbackLanguage: en'), findsOneWidget);
    expect(find.textContaining('localPath:'), findsNothing);

    await tester.tap(find.text('Package'));
    await tester.pumpAndSettle();
    expect(find.textContaining('localPath:'), findsNothing);

    await tester.tap(find.text('App'));
    await tester.pumpAndSettle();
    expect(find.textContaining('remoteEnabled: false'), findsOneWidget);
    expect(find.textContaining('localPath:'), findsNothing);
  });

  testWidgets('global config display opens the aggregate JSON map', (
    tester,
  ) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    expect(find.byIcon(Icons.data_object), findsOneWidget);
    await tester.tap(find.byIcon(Icons.data_object));
    await tester.pumpAndSettle();

    expect(find.text('In-memory configuration'), findsOneWidget);
    expect(find.textContaining('"logging"'), findsOneWidget);
    expect(find.textContaining('"localization"'), findsOneWidget);
    expect(find.textContaining('"fallbackLanguage": "en"'), findsOneWidget);
  });

  testWidgets('global app bar action toggles theme mode', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });

  testWidgets('color wheel opens the theme modal', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    await tester.tap(find.byIcon(Icons.palette_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('Color scheme'), findsOneWidget);
    expect(find.text('Aqua blue'), findsOneWidget);
    expect(find.text('Bangkok sunset'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('translate icon opens language selection', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('English (English)'), findsNothing);
    expect(find.text('Thai (ไทย)'), findsOneWidget);
    expect(find.text('17 of 17 app-enabled languages'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Japanese');
    await tester.pumpAndSettle();
    expect(find.text('Japanese (日本語)'), findsOneWidget);

    final languageContext = tester.element(find.text('Japanese (日本語)'));
    await tester.runAsync(() => languageContext.setLocale(const Locale('ja')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('日本語'), findsOneWidget);
    expect(find.text('英語 (English)'), findsOneWidget);
    expect(find.text('タイ (ไทย) (thai)'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('wide layouts use a navigation rail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('modal pages stack and return', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);
    await pumpApp(tester, router);

    await tester.tap(find.text('Open modal page'));
    await tester.pumpAndSettle();
    expect(find.text('FNav1 modal'), findsOneWidget);
    await tester.tap(find.text('Open another modal'));
    await tester.pumpAndSettle();
    expect(find.text('Modal stack depth: 2'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Modal stack depth: 1'), findsOneWidget);
  });
}
