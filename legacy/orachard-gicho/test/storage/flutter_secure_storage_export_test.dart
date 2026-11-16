import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test(
    'exposes Flutter Secure Storage through the Gicho public library',
    () {
      const storage = FlutterSecureStorage();

      expect(storage, isA<FlutterSecureStorage>());
    },
  );
}
