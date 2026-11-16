import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'missing selected-language app copy falls back to interpolated English',
    () {
      final controller = GichoLocaleController(
        initialLocale: const Locale('th'),
        enabledLocales: const [Locale('en'), Locale('th')],
        appCatalogs: const {
          'en': {'app.greeting': 'Hello, {name}'},
        },
      );
      expect(
        controller.text('app.greeting', variables: {'name': 'Ari'}),
        'Hello, Ari',
      );
      expect(controller.text('app.unknown'), 'app.unknown');
      controller.dispose();
    },
  );

  test('the shared registry uses the approved 20 codes', () {
    expect(
      GichoLocaleController.supportedLocales.map(
        (locale) => locale.toLanguageTag(),
      ),
      [
        'en',
        'th',
        'vi',
        'id',
        'ms',
        'fil',
        'my',
        'km',
        'lo',
        'zh',
        'ja',
        'ko',
        'hi',
        'bn',
        'ar',
        'es',
        'pt',
        'fr',
        'de',
        'ru',
      ],
    );
    for (final locale in GichoLocaleController.supportedLocales) {
      expect(GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
      expect(GlobalCupertinoLocalizations.delegate.isSupported(locale), isTrue);
      expect(GlobalWidgetsLocalizations.delegate.isSupported(locale), isTrue);
    }
  });

  test('app copy overrides package copy and unknown keys stay exact', () {
    final controller = GichoLocaleController(
      appCatalogs: const {
        'en': {
          'gicho.language.label': 'Choose language',
          'example.startup.title': 'Example',
        },
      },
    );
    expect(controller.text('gicho.language.label'), 'Choose language');
    expect(controller.text('gicho.locale.en'), 'English');
    expect(controller.text('example.startup.title'), 'Example');
    expect(controller.text('example.missing'), 'example.missing');
    controller.dispose();
  });

  test('unregistered locales cannot be selected or exposed by an app', () {
    expect(
      () => GichoLocaleController(initialLocale: const Locale('xx')),
      throwsArgumentError,
    );
    expect(
      () => GichoLocaleController(
        appCatalogs: const {
          'xx': {'x': 'y'},
        },
      ),
      throwsArgumentError,
    );
    final controller = GichoLocaleController();
    expect(() => controller.setLocale(const Locale('xx')), throwsArgumentError);
    expect(
      () => controller.setLocale(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
      throwsArgumentError,
    );
    expect(controller.locale, const Locale('en'));
    controller.dispose();
  });

  test('a consumer must enable English alongside any other locale', () {
    expect(
      () => GichoLocaleController(
        initialLocale: const Locale('th'),
        enabledLocales: const [Locale('th')],
      ),
      throwsArgumentError,
    );
    final controller = GichoLocaleController(
      initialLocale: const Locale('th'),
      enabledLocales: const [Locale('en'), Locale('th')],
    );
    expect(controller.locale, const Locale('th'));
    controller.dispose();
  });

  test('registered locales are selectable only when the app enables them', () {
    final controller = GichoLocaleController(
      enabledLocales: GichoLocaleController.supportedLocales,
      appCatalogs: const {
        'th': {'app.greeting': 'สวัสดี'},
        'zh': {'app.greeting': '你好'},
      },
    );
    for (final locale in GichoLocaleController.supportedLocales) {
      controller.setLocale(locale);
      expect(controller.locale, locale);
      expect(
        controller.text('gicho.language.label'),
        isNot('gicho.language.label'),
      );
      expect(
        controller.text('gicho.navigation.open'),
        isNot('gicho.navigation.open'),
      );
      expect(
        controller.text('gicho.navigation.close'),
        isNot('gicho.navigation.close'),
      );
      expect(
        controller.text('gicho.navigation.title'),
        isNot('gicho.navigation.title'),
      );
      expect(
        controller.text('gicho.locale.${locale.toLanguageTag()}'),
        isNot('gicho.locale.${locale.toLanguageTag()}'),
      );
    }
    controller.setLocale(const Locale('th'));
    expect(controller.text('app.greeting'), 'สวัสดี');
    controller.setLocale(const Locale('zh'));
    expect(controller.text('app.greeting'), '你好');
    expect(controller.text('app.missing'), 'app.missing');
    controller.dispose();

    final englishOnly = GichoLocaleController();
    expect(
      () => englishOnly.setLocale(const Locale('th')),
      throwsArgumentError,
    );
    englishOnly.dispose();
  });

  testWidgets('language picker lists only package-registered locales', (
    tester,
  ) async {
    final controller = GichoLocaleController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GichoLanguagePicker(controller: controller)),
      ),
    );
    expect(find.text('Language'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    final choices = tester
        .widgetList<DropdownMenuItem<Locale>>(
          find.byType(DropdownMenuItem<Locale>),
        )
        .map((item) => item.value)
        .toSet();
    expect(choices, {const Locale('en')});
    expect(find.text('English'), findsWidgets);
    controller.dispose();
  });
}
