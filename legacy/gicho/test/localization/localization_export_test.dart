import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test(
    'exposes Flutter localization and intl through the Gicho public library',
    () {
      expect(GlobalMaterialLocalizations.delegate, isNotNull);
      expect(translate, isA<String Function(String)>());
      expect(Intl.canonicalizedLocale('en-us'), 'en_US');
    },
  );
}
