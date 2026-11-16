import 'dart:async';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'index.dart';

void main() {
  testWidgets('prepares context during the company scene before product', (
    tester,
  ) async {
    final prepared = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: StartupSequence<int>(
          scenes: [
            StartupScene(
              minimumDuration: const Duration(seconds: 1),
              prepare: () => prepared.future,
              builder: (_) => const Text('Company'),
            ),
            StartupScene(
              minimumDuration: const Duration(seconds: 1),
              builder: (_) => const Text('Product'),
            ),
          ],
          jobs: const [],
          loadLabel: 'Load',
          load: (_) async => 1,
          loadingBuilder: (_, _) => const Text('Loading'),
          errorBuilder: (_, _, _) => const Text('Error'),
          readyBuilder: (_, _) => const Text('Ready'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Company'), findsOneWidget);
    prepared.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('Product'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('shows scenes, concurrent work, and waits for the last job', (
    tester,
  ) async {
    final first = Completer<void>();
    final second = Completer<void>();
    final order = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: StartupSequence<String>(
          scenes: [
            StartupScene(
              minimumDuration: const Duration(seconds: 1),
              builder: (_) => const Text('Company'),
            ),
            StartupScene(
              minimumDuration: const Duration(seconds: 1),
              builder: (_) => const Text('Product'),
            ),
          ],
          jobs: [
            StartupJob(
              id: 'first',
              label: 'First',
              run: (progress) async {
                order.add('first');
                await first.future;
              },
            ),
            StartupJob(
              id: 'second',
              label: 'Second',
              run: (progress) async {
                order.add('second');
                await second.future;
              },
            ),
            StartupJob(
              id: 'last',
              label: 'Last',
              type: StartupJobType.synchronous,
              run: (progress) async => order.add('last'),
            ),
          ],
          loadLabel: 'Load',
          load: (_) async => 'ready',
          loadingBuilder: (_, progress) => AnimatedBuilder(
            animation: progress,
            builder: (_, _) => Text('Loading ${progress.status('first').name}'),
          ),
          errorBuilder: (_, _, retry) =>
              TextButton(onPressed: retry, child: const Text('Retry')),
          readyBuilder: (_, value) => Text(value),
        ),
      ),
    );
    expect(find.text('Company'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Product'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Loading running'), findsOneWidget);
    expect(order, ['first', 'second']);

    first.complete();
    await tester.pump();
    expect(find.text('ready'), findsNothing);
    second.complete();
    await tester.pump();
    expect(order, ['first', 'second', 'last']);
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('retry reruns jobs without replaying scenes', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StartupSequence<int>(
          scenes: [StartupScene(builder: (_) => const Text('Intro'))],
          jobs: [
            StartupJob(
              id: 'check',
              label: 'Check',
              run: (_) async {
                if (++attempts == 1) {
                  throw StateError('offline');
                }
              },
            ),
          ],
          loadLabel: 'Load',
          load: (_) async => 7,
          loadingBuilder: (_, _) => const Text('Loading'),
          errorBuilder: (_, _, retry) =>
              TextButton(onPressed: retry, child: const Text('Retry')),
          readyBuilder: (_, value) => Text('Ready $value'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Intro'), findsNothing);
    expect(find.text('Ready 7'), findsOneWidget);
  });
}
