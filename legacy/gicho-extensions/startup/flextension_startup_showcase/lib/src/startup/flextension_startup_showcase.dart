import 'package:moztopia/gicho.dart';

import 'showcase_animation_overlay.dart';
import 'showcase_frame.dart';
import 'showcase_progress.dart';
import 'showcase_ready_overlay.dart';
import 'showcase_startup_processes.dart';
import 'showcase_visual_overlays.dart';

/// A readable demonstration of everything a Gicho startup can coordinate.
final class FlextensionStartupShowcase implements StartupDelegate {
  FlextensionStartupShowcase();

  // Queue processes update this object. Every overlay frame listens to it.
  final progress = ShowcaseStartupProgress();

  @override
  Duration? get startupPreDelayDuration => null;

  @override
  Duration? get startupPostDelayDuration => null;

  // The overlays control only the changing, large visual area.
  @override
  List<StartupOverlayBuilder> get startupOverlays => [
    _withProgress(buildShowcaseAnimationOverlay),
    _withProgress(buildOrbitingIdeasOverlay),
    _withProgress(buildPackingBoxesOverlay),
    (context, state, complete) =>
        buildShowcaseReadyOverlay(context, state, complete, progress),
  ];

  StartupOverlayBuilder _withProgress(StartupOverlayBuilder overlay) =>
      (context, state, complete) => ShowcaseFrame(
        progress: progress,
        visual: overlay(context, state, complete),
      );

  // The first two processes start together. The synchronous third process
  // waits for both of them, and then runs by itself.
  @override
  List<StartupQueueEntry> get startupQueue => [
    (
      process: () => showcaseLoadConfiguration(progress),
      type: StartupQueueType.asynchronous,
    ),
    (
      process: () => showcaseWarmCache(progress),
      type: StartupQueueType.asynchronous,
    ),
    (
      process: () => showcaseRegisterServices(progress),
      type: StartupQueueType.synchronous,
    ),
  ];
}
