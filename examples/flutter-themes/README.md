# Gicho named-theme example

This independent Android/Linux consumer demonstrates Gicho's permanent
Default, Ocean and Ember themes. Each theme has light and dark variants. The
app configuration chooses the available subset and default; the shared picker
lets the user select a theme and System, Light or Dark appearance. Gicho
remembers those choices on this device between launches.

## What to expect

The ready page starts in Ocean, following the device's appearance. Select
Default or Ember to change the colors, then choose System, Light or Dark.
Restart the app to check that your choices return. A saved theme that this app
no longer offers is ignored in favor of its configured default.

## Read the app

1. [`lib/main.dart`](lib/main.dart) only starts `buildApp()`.
2. [`assets/gicho/gicho.yaml`](assets/gicho/gicho.yaml) selects the
   three available package themes and Ocean as the default. Gicho owns the
   schema and permanent definitions in [`assets/themes/`](../../assets/themes/README.md).
3. [`lib/app.dart`](lib/app.dart) composes `GichoBootstrap`,
   `GichoMaterialApp`, `GichoAppShell` and `ThemePicker` directly. The
   startup loader resolves configuration, loads `ThemeCatalog`, restores the
   saved preference and hands one `ThemeController` to the app and picker.
4. [`test/app_test.dart`](test/app_test.dart) verifies real bundle loading,
   light/dark variants, picker behavior and phone/tablet/large widths.

This example has no authentication, network or Harmony dependency. It exercises
one package feature in a separate app rather than hiding another entrypoint in
an existing example. Names are proper names; picker copy comes from Gicho's
20 central locale catalogs. Translation wording should receive native-speaker
review before production use.

## Run and verify

From this directory, run `flutter pub get`, `flutter analyze`, and
`flutter test`. Run `flutter run -d linux` for desktop. On an Android device
you control, choose a target shown by `flutter devices` and run
`flutter run -d <device-id>`. The owner handles testing on their physical
devices. Other platforms are outside this focused example.
