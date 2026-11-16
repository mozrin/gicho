import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes Shared Preferences through the Gicho public library', () {
    final constructor = SharedPreferencesAsync.new;

    expect(constructor, isA<SharedPreferencesAsync Function()>());
  });
}
