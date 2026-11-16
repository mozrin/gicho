> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Flextension Startup Showcase

This package is intentionally demonstration code. Open the files under
`lib/src/startup/` and change them while learning how Gicho startup works.
It is not intended to be copied unchanged into a production application.

## Run it

```dart
import 'package:flextension_startup_showcase/flextension_startup_showcase.dart';

GichoBootstrap(
  startupEnabled: true,
  startupDelegate: FlextensionStartupShowcase(),
  child: app,
)
```

## What it demonstrates

The delegate in `flextension_startup_showcase.dart` is the table of contents.
It deliberately spells out this startup sequence:

1. Gicho holds the native launch screen using its configured duration.
2. `showcaseLoadConfiguration` and `showcaseWarmCache` start together.
3. The labeled Lottie overlay plays once and reports its own completion.
4. Large visual overlays continue changing independently of the queue.
5. A persistent checklist, phrase, and progress bar reflect queue state below
   every visual.
6. Each delayed process continuously updates its portion of the progress bar.
7. `showcaseRegisterServices` waits for both asynchronous processes, then runs.
8. The final visual waits for the queue and completes immediately with it.
9. Gicho waits its configured two-second completion delay after both
   branches are complete.
10. Gicho then continues to authentication or the app.

The showcase takes about 45 seconds end to end. The first queue jobs take 22
and 31 seconds concurrently; the final synchronous job takes 12 seconds, and
the configured completion delay adds the final two seconds.

The visual and process branches run independently. Change their durations and
watch the slower branch determine when startup completes.

## Files to explore

- `flextension_startup_showcase.dart` lists the overlays and process queue.
- `showcase_animation_overlay.dart` demonstrates media-driven completion.
- `showcase_progress.dart` is the shared checklist state.
- `showcase_progress_panel.dart` displays queue progress below every overlay.
- `showcase_visual_overlays.dart` contains the large timed visuals.
- `showcase_ready_overlay.dart` demonstrates timer-driven completion.
- `showcase_startup_processes.dart` demonstrates asynchronous batching and a
  synchronous barrier.
- `showcase_frame.dart` shares Gicho's configured theme across overlays.

Replace `assets/animations/startup.json` to experiment with another Lottie
animation. The showcase visibly falls back and continues if that asset is not
valid.
