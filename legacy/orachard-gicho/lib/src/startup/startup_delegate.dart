import 'package:material_ui/material_ui.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';

import 'startup_state.dart';

typedef StartupProcessCallback = FutureOr<void> Function();

/// Builds one startup overlay and reports when it has finished presenting.
typedef StartupOverlayBuilder =
    Widget Function(
      BuildContext context,
      StartupState state,
      VoidCallback complete,
    );

/// Determines how an entry in [StartupDelegate.startupQueue] is scheduled.
enum StartupQueueType { synchronous, asynchronous }

/// One process and its scheduling behavior in the startup queue.
typedef StartupQueueEntry = ({
  StartupProcessCallback process,
  StartupQueueType type,
});

/// Neutral startup process consumed by [GichoBootstrap].
abstract interface class StartupDelegate {
  /// How long the native launch icon remains visible.
  ///
  /// Null uses `startup.config.yaml`, whose package default is two seconds.
  Duration? get startupPreDelayDuration;

  /// Pause after both overlays and the startup queue have completed.
  ///
  /// Null uses `startup.config.yaml`, whose package default is two seconds.
  Duration? get startupPostDelayDuration;

  /// Visual overlays presented one at a time in list order.
  List<StartupOverlayBuilder> get startupOverlays;

  /// Background processes scheduled using synchronous barriers.
  List<StartupQueueEntry> get startupQueue;
}

/// Standard immutable implementation suitable for consumers and Flextensions.
final class StartupProcess implements StartupDelegate {
  const StartupProcess({
    this.startupPreDelayDuration,
    this.startupPostDelayDuration,
    this.startupOverlays = const [],
    this.startupQueue = const [],
  });

  @override
  final Duration? startupPreDelayDuration;

  @override
  final Duration? startupPostDelayDuration;

  @override
  final List<StartupOverlayBuilder> startupOverlays;

  @override
  final List<StartupQueueEntry> startupQueue;
}

/// Runs asynchronous entries together until a synchronous entry creates a
/// barrier. The queue also waits for any asynchronous entries left at its end.
Future<void> runStartupQueue(Iterable<StartupQueueEntry> queue) async {
  final pending = <Future<void>>[];

  for (final entry in queue) {
    switch (entry.type) {
      case StartupQueueType.asynchronous:
        pending.add(Future<void>.sync(entry.process));
      case StartupQueueType.synchronous:
        if (pending.isNotEmpty) {
          await Future.wait(pending);
          pending.clear();
        }
        await Future<void>.sync(entry.process);
    }
  }

  if (pending.isNotEmpty) await Future.wait(pending);
}
