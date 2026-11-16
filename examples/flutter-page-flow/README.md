# Flutter page flow example

This independent Android/Linux app demonstrates a regular shell page opening
a full-screen `GichoModalPage`. The About page uses the same Gicho page
frame as the shell, shows Back, and omits the shell's ancillary navigation.
Tapping Back returns to the original page.

## What to expect

The shell shows **Open About**. Selecting it pushes a dedicated **About** page
with an accessible Back action. Back pops that route and reveals the original
shell page. The app owns the route push; `GichoModalPage` supplies the page
frame and Back presentation.

## Read the app

1. [`lib/main.dart`](lib/main.dart) only calls `runApp(buildApp())`.
2. [`lib/app.dart`](lib/app.dart) directly composes `GichoMaterialApp` and
   `GichoAppShell`; its `body:` names the app-owned `AboutFlow` feature.
3. [`lib/features/about_flow/`](lib/features/about_flow/README.md) owns the
   route into About. It uses Gicho's modal page presentation but keeps
   navigation decisions in the consumer.
4. [`test/app_test.dart`](test/app_test.dart) opens About and verifies Back
   restores the shell page.

This app demonstrates a route origin and full-page modal presentation. It
does not implement a multi-section stack, deep-link restoration, business
scope or authentication. Those are separate consumer/navigation decisions;
Gicho #31 tracks the broader shell contract.
See the [shell API guide](../../lib/src/application/app_shell/README.md) and
[modal-page API guide](../../lib/src/application/modal_page/README.md) for
their supported options.

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
