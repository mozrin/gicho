import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes FlexColorScheme through the Gicho public library', () {
    final theme = FlexThemeData.light(scheme: FlexScheme.blue);

    expect(theme, isA<ThemeData>());
    expect(theme.brightness, Brightness.light);
  });
}
