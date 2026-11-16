import 'dart:async';

import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows splash then app-owned signed-out destination', (
    tester,
  ) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate<bool>(
          load: () => pending.future,
          loadingBuilder: (_) => const StartupSplash(title: 'Example'),
          errorBuilder: (_, _, _) => const Text('Failed'),
          readyBuilder: (_, signedIn) =>
              Text(signedIn ? 'Account home' : 'Sign in'),
        ),
      ),
    );
    expect(find.text('Example'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Example'), findsNothing);
  });

  testWidgets('retry ignores an older completion', (tester) async {
    final stale = Completer<String>();
    final fresh = Completer<String>();
    var call = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate<String>(
          load: () async {
            call++;
            if (call == 1) {
              throw StateError('offline');
            }
            if (call == 2) {
              return stale.future;
            }
            return fresh.future;
          },
          loadingBuilder: (_) => const Text('Loading'),
          errorBuilder: (_, _, retry) =>
              TextButton(onPressed: retry, child: const Text('Retry')),
          readyBuilder: (_, value) => Text(value),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Loading'), findsOneWidget);

    // A new gate replaces the old context while its request is pending.
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate<String>(
          key: const ValueKey('new-account'),
          load: () => fresh.future,
          loadingBuilder: (_) => const Text('New account loading'),
          errorBuilder: (_, _, _) => const Text('New account failed'),
          readyBuilder: (_, value) => Text(value),
        ),
      ),
    );
    stale.complete('Old account');
    await tester.pump();
    expect(find.text('Old account'), findsNothing);
    fresh.complete('New account');
    await tester.pumpAndSettle();
    expect(find.text('New account'), findsOneWidget);
  });
}
