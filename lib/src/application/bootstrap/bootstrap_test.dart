import 'dart:async';

import 'package:flutter/material.dart';
// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'index.dart';

void main() {
  testWidgets('native launch hold releases to configured app', (tester) async {
    final configuration = Completer<String>();
    await tester.pumpWidget(
      GichoBootstrap<String>(
        load: () => configuration.future,
        title: 'Example',
        theme: ThemeData(),
        holdNativeLaunch: true,
        failureMessage: 'Failed',
        retryLabel: 'Retry',
        readyBuilder: (_, value) =>
            MaterialApp(home: Scaffold(body: Text(value))),
      ),
    );
    configuration.complete('configured');
    await tester.pump();
    expect(find.text('configured'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('holds a consumer splash for its configured minimum', (
    tester,
  ) async {
    await tester.pumpWidget(
      GichoBootstrap<String>(
        load: () async => 'configured',
        title: 'Example',
        theme: ThemeData(),
        loadingScreen: const Scaffold(body: Center(child: Text('Company'))),
        minimumDurationFor: (_) => const Duration(seconds: 2),
        failureMessage: 'Failed',
        retryLabel: 'Retry',
        readyBuilder: (_, value) =>
            MaterialApp(home: Scaffold(body: Text(value))),
      ),
    );
    expect(find.text('Company'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Company'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('configured'), findsOneWidget);
  });

  testWidgets('shows startup, retries failure and hands off the result', (
    tester,
  ) async {
    final first = Completer<String>();
    final second = Completer<String>();
    var attempts = 0;
    final theme = ThemeData(colorSchemeSeed: Colors.teal);

    await tester.pumpWidget(
      GichoBootstrap<String>(
        load: () => attempts++ == 0 ? first.future : second.future,
        title: 'Example',
        theme: theme,
        failureMessage: 'Could not start',
        retryLabel: 'Try again',
        readyBuilder: (_, value) =>
            MaterialApp(home: Scaffold(body: Text('Ready: $value'))),
      ),
    );

    expect(find.text('Example'), findsOneWidget);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).theme, theme);

    first.completeError(StateError('offline'));
    await tester.pump();

    expect(find.text('Could not start'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Example'), findsOneWidget);

    second.complete('configured');
    await tester.pump();
    expect(find.text('Ready: configured'), findsOneWidget);
  });
}
