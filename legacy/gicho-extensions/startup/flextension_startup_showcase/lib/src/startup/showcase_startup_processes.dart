import 'dart:async';

import 'package:flutter/foundation.dart';

import 'showcase_progress.dart';

Future<void> showcaseLoadConfiguration(ShowcaseStartupProgress progress) =>
    _runVisibleTask(
      progress: progress,
      name: 'Load configuration',
      duration: const Duration(seconds: 22),
    );

Future<void> showcaseWarmCache(ShowcaseStartupProgress progress) =>
    _runVisibleTask(
      progress: progress,
      name: 'Warm the cache',
      duration: const Duration(seconds: 31),
    );

/// This synchronous queue entry starts after both asynchronous entries finish.
Future<void> showcaseRegisterServices(ShowcaseStartupProgress progress) =>
    _runVisibleTask(
      progress: progress,
      name: 'Register services',
      duration: const Duration(seconds: 12),
    );

/// Simulates real work and reports a new fraction twice per second.
Future<void> _runVisibleTask({
  required ShowcaseStartupProgress progress,
  required String name,
  required Duration duration,
}) async {
  debugPrint('STARTUP: $name started');
  progress.start(name);

  const updateEvery = Duration(milliseconds: 500);
  final updates = duration.inMilliseconds ~/ updateEvery.inMilliseconds;
  for (var update = 1; update <= updates; update++) {
    await Future<void>.delayed(updateEvery);
    progress.report(name, update / updates);
  }

  progress.complete(name);
  debugPrint('STARTUP: $name complete');
}
