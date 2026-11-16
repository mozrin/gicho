import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme uses consumer seed and a single semantic focus border', () {
    final theme = gichoTheme(seedColor: const Color(0xFF17634F));
    final input = theme.inputDecorationTheme;
    final enabled = input.enabledBorder! as UnderlineInputBorder;
    final focused = input.focusedBorder! as UnderlineInputBorder;

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, isNotNull);
    expect(enabled.borderSide.width, focused.borderSide.width);
    expect(focused.borderSide.color, theme.colorScheme.primary);
    expect(theme.filledButtonTheme.style?.minimumSize?.resolve({})?.height, 48);
  });

  test('theme supports app-selected dark mode without changing tokens', () {
    final theme = gichoTheme(
      seedColor: const Color(0xFF17634F),
      brightness: Brightness.dark,
    );
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(
      (theme.inputDecorationTheme.focusedBorder! as UnderlineInputBorder)
          .borderSide
          .color,
      theme.colorScheme.primary,
    );
  });
}
