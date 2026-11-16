import 'package:flutter_test/flutter_test.dart';
import 'package:gicho/src/i18n/ar.dart';
import 'package:gicho/src/i18n/bn.dart';
import 'package:gicho/src/i18n/de.dart';
import 'package:gicho/src/i18n/en.dart';
import 'package:gicho/src/i18n/es.dart';
import 'package:gicho/src/i18n/fil.dart';
import 'package:gicho/src/i18n/fr.dart';
import 'package:gicho/src/i18n/hi.dart';
import 'package:gicho/src/i18n/id.dart';
import 'package:gicho/src/i18n/ja.dart';
import 'package:gicho/src/i18n/km.dart';
import 'package:gicho/src/i18n/ko.dart';
import 'package:gicho/src/i18n/lo.dart';
import 'package:gicho/src/i18n/ms.dart';
import 'package:gicho/src/i18n/my.dart';
import 'package:gicho/src/i18n/pt.dart';
import 'package:gicho/src/i18n/ru.dart';
import 'package:gicho/src/i18n/th.dart';
import 'package:gicho/src/i18n/vi.dart';
import 'package:gicho/src/i18n/zh.dart';

void main() {
  test(
    'all bundled catalogs have English keys and interpolation placeholders',
    () {
      final catalogs = <String, Map<String, String>>{
        'ar': gichoArabic,
        'bn': gichoBengali,
        'de': gichoGerman,
        'en': gichoEnglish,
        'es': gichoSpanish,
        'fil': gichoFilipino,
        'fr': gichoFrench,
        'hi': gichoHindi,
        'id': gichoIndonesian,
        'ja': gichoJapanese,
        'km': gichoKhmer,
        'ko': gichoKorean,
        'lo': gichoLao,
        'ms': gichoMalay,
        'my': gichoBurmese,
        'pt': gichoPortuguese,
        'ru': gichoRussian,
        'th': gichoThai,
        'vi': gichoVietnamese,
        'zh': gichoChinese,
      };
      expect(catalogs.length, 20);
      final placeholders = RegExp(r'\{[^{}]+\}');
      for (final entry in catalogs.entries) {
        expect(
          entry.value.keys.toSet(),
          gichoEnglish.keys.toSet(),
          reason: entry.key,
        );
        for (final key in gichoEnglish.keys) {
          expect(
            entry.value[key]!.trim(),
            isNotEmpty,
            reason: '${entry.key}:$key',
          );
          expect(
            placeholders
                .allMatches(entry.value[key]!)
                .map((match) => match.group(0))
                .toSet(),
            placeholders
                .allMatches(gichoEnglish[key]!)
                .map((match) => match.group(0))
                .toSet(),
            reason: '${entry.key}:$key',
          );
        }
      }
    },
  );
}
