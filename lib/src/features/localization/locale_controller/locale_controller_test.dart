import 'package:flutter/widgets.dart';
// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'locale_controller.dart';

void main() {
  test('interpolates selected-locale app copy and preserves missing keys', () {
    final locales = GichoLocaleController(
      enabledLocales: const [Locale('en'), Locale('th')],
      appCatalogs: const {
        'en': {'app.greeting': 'Hello, {name}'},
        'th': {'app.greeting': 'สวัสดี {name}'},
      },
    );
    expect(
      locales.text('app.greeting', variables: {'name': 'Ari'}),
      'Hello, Ari',
    );
    locales.setLocale(const Locale('th'));
    expect(
      locales.text('app.greeting', variables: {'name': 'Ari'}),
      'สวัสดี Ari',
    );
    expect(
      locales.text('app.missing', variables: {'name': 'Ari'}),
      'app.missing',
    );
    locales.dispose();
  });
}
