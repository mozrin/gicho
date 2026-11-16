import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('creates typed package language metadata', () {
    final registry = LocalizationLanguageRegistry.fromMap({
      'en': {
        'label': 'EN',
        'iso639': 'en',
        'names': {'en': 'English', 'th': 'อังกฤษ'},
      },
      'th': {
        'label': 'TH',
        'iso639': 'th',
        'names': {'en': 'Thai', 'th': 'ไทย'},
      },
    });

    expect(registry.languages.last.nameIn(const Locale('th')), 'ไทย');
    expect(registry.languages.last.nameIn(const Locale('en')), 'Thai');
  });

  test('registry key must match iso639', () {
    expect(
      () => LocalizationLanguageRegistry.fromMap({
        'th': {
          'label': 'TH',
          'iso639': 'en',
          'names': {'en': 'Thai', 'th': 'ไทย'},
        },
      }),
      throwsA(isA<LocalizationException>()),
    );
  });
}
