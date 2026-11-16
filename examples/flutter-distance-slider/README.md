# Flutter distance slider example

This independent Android/Linux app is the single DistanceSlider playground.
The control starts at 10 km with a 100 km maximum. Below the divider, change
the maximum, step size, fine-step threshold, no-limit option, or enabled state.
Apply updates the control; Reset restores the example defaults. Gicho
renders and validates the shared control; the app keeps its chosen value.

## What to expect

The shell opens the **Distance slider** page. Dragging the control changes the
selected maximum distance shown on the screen. The control receives the value
and `onChanged` callback from `DistanceSelection`; the app's `State` retains
the choice while that screen is mounted.

## Read the app

1. [`lib/main.dart`](lib/main.dart) only calls `runApp(buildApp())`.
2. [`lib/app.dart`](lib/app.dart) directly composes `GichoMaterialApp` and
   `GichoAppShell`, then names the app-owned `DistanceSelection` screen.
3. [`lib/features/distance_selection/`](lib/features/distance_selection/README.md)
   holds the screen and its Flutter state. Its `index.dart` is the deliberate
   entry used by `app.dart`.
4. [`test/app_test.dart`](test/app_test.dart) checks that the consumer renders
   the shared slider with its configured initial value and range.

The development panel demonstrates commonly changed options.
[Gicho's control documentation](../../lib/src/ui/distance_slider/README.md)
describes the full API. This app has no authentication or Harmony dependency.
The example does not persist the choice or turn it into a product filter; a
consumer decides those behaviors.

## Run and verify

From this directory, run `flutter pub get`, `flutter analyze` and
`flutter test`. Run `flutter run -d linux` for desktop. For Android, choose a
target from `flutter devices` and run `flutter run -d <device-id>` on a
development device you control. The owner performs physical-device testing.
Only Android and Linux platform scaffolds are included.

## Browser development

Run `flutter run -d chrome` to build and launch this app in a browser. Linux
scaffolding is also available. Choose a connected Android device for native
mobile checks. Build/startup alone does not establish interactive acceptance;
exercise this example's documented scenario and see the root validation record.
