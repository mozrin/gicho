> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Minimal Gicho example

This is the absolute-minimum simple-mode adoption of Gicho. It contains:

- a three-line executable entry point;
- one consumer-owned `GichoApp` widget;
- one `GichoRouter` with one Dart route;
- one `GichoBootstrap` around `GichoMaterialApp`;
- one ordinary Flutter `Scaffold`.

It has no application YAML overrides and does not use `GichoPageShell` or
`GichoAppBar`. Package themes, core defaults, logging, and routing are
initialized by the standard application foundation. Localization and
notifications are off by default.

To enable localization later, set `localizationsEnabled: true` and add
`assets/gicho/en.json`; `{}` is valid when the app has no consumer-owned
translation keys. To enable notifications, set `notificationsEnabled: true`.

The project includes Flutter targets for Android, iOS, Linux, macOS, web, and
Windows. The Gicho-specific application code remains entirely under `lib/`
and `assets/gicho/`.

```shell
flutter analyze
flutter run
```
