import 'dart:async';

import 'package:flutter/material.dart';
// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'mode_controller.dart';

void main() {
  test('restores account mode and clears it on sign-out', () async {
    final saved = <String, String>{'theme.a': 'dark'};
    final modes = GichoThemeModeController(
      readPreference: (key) async => saved[key],
      writePreference: (key, value) async => saved[key] = value,
    );
    await modes.bind('theme.a', initialMode: ThemeMode.light);
    expect(modes.mode, ThemeMode.dark);
    await modes.setMode(ThemeMode.light);
    expect(saved['theme.a'], 'light');
    await modes.bind(null, initialMode: ThemeMode.light);
    expect(modes.mode, ThemeMode.light);
    expect(() => modes.setMode(ThemeMode.dark), throwsStateError);
    modes.dispose();
  });

  test(
    'late restore from previous account cannot replace current mode',
    () async {
      final pending = Completer<String?>();
      final modes = GichoThemeModeController(
        readPreference: (key) =>
            key == 'theme.a' ? pending.future : Future.value(null),
        writePreference: (key, value) async {},
      );
      final first = modes.bind('theme.a', initialMode: ThemeMode.dark);
      await modes.bind('theme.b', initialMode: ThemeMode.light);
      pending.complete('dark');
      await first;
      expect(modes.mode, ThemeMode.light);
      modes.dispose();
    },
  );

  test('failed write rolls back only its own account', () async {
    final pending = Completer<void>();
    final modes = GichoThemeModeController(
      readPreference: (key) async => null,
      writePreference: (key, value) => pending.future,
    );
    await modes.bind('theme.a', initialMode: ThemeMode.light);
    final write = modes.setMode(ThemeMode.dark);
    expect(modes.mode, ThemeMode.dark);
    await modes.bind('theme.b', initialMode: ThemeMode.light);
    pending.completeError(StateError('Storage failed'));
    await expectLater(write, throwsStateError);
    expect(modes.mode, ThemeMode.light);
    modes.dispose();
  });

  test('late restore after disposal is ignored', () async {
    final pending = Completer<String?>();
    final modes = GichoThemeModeController(
      readPreference: (key) => pending.future,
      writePreference: (key, value) async {},
    );
    final restore = modes.bind('theme.a', initialMode: ThemeMode.light);
    modes.dispose();
    pending.complete('dark');
    await restore;
  });

  test('a user selection wins over a pending restore', () async {
    final pending = Completer<String?>();
    final modes = GichoThemeModeController(
      readPreference: (key) => pending.future,
      writePreference: (key, value) async {},
    );
    final restore = modes.bind('theme.a', initialMode: ThemeMode.light);
    await modes.setMode(ThemeMode.dark);
    pending.complete('light');
    await restore;
    expect(modes.mode, ThemeMode.dark);
    modes.dispose();
  });
}
