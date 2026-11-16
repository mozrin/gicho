import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes Material theme types through the Gicho public library', () {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    final theme = ThemeData(colorScheme: colorScheme);

    expect(theme, isA<ThemeData>());
    expect(theme.colorScheme.primary, colorScheme.primary);
    expect(TextDirection.ltr, isA<TextDirection>());
  });
}
