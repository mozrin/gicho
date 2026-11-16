import 'package:flutter/widgets.dart';

import '../../../i18n/ar.dart';
import '../../../i18n/bn.dart';
import '../../../i18n/de.dart';
import '../../../i18n/en.dart';
import '../../../i18n/es.dart';
import '../../../i18n/fil.dart';
import '../../../i18n/fr.dart';
import '../../../i18n/hi.dart';
import '../../../i18n/id.dart';
import '../../../i18n/ja.dart';
import '../../../i18n/km.dart';
import '../../../i18n/ko.dart';
import '../../../i18n/lo.dart';
import '../../../i18n/locale_names.dart';
import '../../../i18n/ms.dart';
import '../../../i18n/my.dart';
import '../../../i18n/pt.dart';
import '../../../i18n/ru.dart';
import '../../../i18n/th.dart';
import '../../../i18n/vi.dart';
import '../../../i18n/zh.dart';

class GichoLocaleController extends ChangeNotifier {
  GichoLocaleController({
    Locale initialLocale = const Locale('en'),
    List<Locale> enabledLocales = const [Locale('en')],
    Map<String, Map<String, String>> appCatalogs = const {},
  }) : _locale = initialLocale,
       enabledLocales = List<Locale>.unmodifiable(enabledLocales),
       _appCatalogs = Map<String, Map<String, String>>.unmodifiable({
         for (final entry in appCatalogs.entries)
           entry.key: Map<String, String>.unmodifiable(entry.value),
       }) {
    if (enabledLocales.isEmpty) {
      throw ArgumentError.value(
        enabledLocales,
        'enabledLocales',
        'Cannot be empty',
      );
    }
    if (!enabledLocales.contains(const Locale('en'))) {
      throw ArgumentError.value(
        enabledLocales,
        'enabledLocales',
        'English must be enabled',
      );
    }
    if (enabledLocales.toSet().length != enabledLocales.length) {
      throw ArgumentError.value(
        enabledLocales,
        'enabledLocales',
        'Expected distinct locales',
      );
    }
    for (final locale in enabledLocales) {
      _validateLocale(locale);
    }
    if (!this.enabledLocales.contains(initialLocale)) {
      throw ArgumentError.value(
        initialLocale,
        'initialLocale',
        'Locale is not enabled',
      );
    }
    for (final code in appCatalogs.keys) {
      if (!supportedLocales.any((locale) => locale.toLanguageTag() == code)) {
        throw ArgumentError.value(
          code,
          'appCatalogs',
          'Locale is not registered',
        );
      }
    }
  }

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
    Locale('vi'),
    Locale('id'),
    Locale('ms'),
    Locale('fil'),
    Locale('my'),
    Locale('km'),
    Locale('lo'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('hi'),
    Locale('bn'),
    Locale('ar'),
    Locale('es'),
    Locale('pt'),
    Locale('fr'),
    Locale('de'),
    Locale('ru'),
  ];
  static const _packageCatalogs = <String, Map<String, String>>{
    'en': gichoEnglish,
    'th': gichoThai,
    'vi': gichoVietnamese,
    'id': gichoIndonesian,
    'ms': gichoMalay,
    'fil': gichoFilipino,
    'my': gichoBurmese,
    'km': gichoKhmer,
    'lo': gichoLao,
    'zh': gichoChinese,
    'ja': gichoJapanese,
    'ko': gichoKorean,
    'hi': gichoHindi,
    'bn': gichoBengali,
    'ar': gichoArabic,
    'es': gichoSpanish,
    'pt': gichoPortuguese,
    'fr': gichoFrench,
    'de': gichoGerman,
    'ru': gichoRussian,
  };

  final List<Locale> enabledLocales;
  final Map<String, Map<String, String>> _appCatalogs;
  Locale _locale;

  Locale get locale => _locale;

  String text(String key, {Map<String, String> variables = const {}}) {
    final code = _locale.toLanguageTag();
    var value =
        _appCatalogs[code]?[key] ??
        _packageCatalogs[code]?[key] ??
        _appCatalogs['en']?[key] ??
        _packageCatalogs['en']?[key] ??
        gichoLocaleNames[key];
    if (value == null) {
      return key;
    }
    for (final entry in variables.entries) {
      value = value!.replaceAll('{${entry.key}}', entry.value);
    }
    return value!;
  }

  void setLocale(Locale next) {
    _validateLocale(next);
    if (!enabledLocales.contains(next)) {
      throw ArgumentError.value(next, 'next', 'Locale is not enabled');
    }
    if (next == _locale) {
      return;
    }
    _locale = next;
    notifyListeners();
  }

  static void _validateLocale(Locale locale) {
    if (!supportedLocales.contains(locale)) {
      throw ArgumentError.value(locale, 'locale', 'Locale is not registered');
    }
  }
}
