import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes Flutter Riverpod through the Gicho public library', () {
    const scope = ProviderScope(child: SizedBox());

    expect(scope, isA<ProviderScope>());
  });
}
