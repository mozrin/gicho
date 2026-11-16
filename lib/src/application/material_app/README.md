# GichoMaterialApp

`GichoMaterialApp` owns the generic `MaterialApp` setup for a Flutter
consumer. Supply the app's `GichoLocaleController`, localized `title`
callback, theme and home widget. Optional dark theme and theme mode remain
consumer choices. The wrapper listens to locale changes and rebuilds the
application without taking ownership of the controller's lifetime.
Flutter's Material, Cupertino and Widgets localization delegates are installed
for the enabled locales.

```dart
GichoMaterialApp(
  locales: locales,
  title: () => locales.text('app.title'),
  theme: appTheme,
  home: const AppHome(),
)
```

For an app-owned Router configuration, use the named constructor instead:

```dart
GichoMaterialApp.router(
  locales: locales,
  title: () => locales.text('app.title'),
  theme: appTheme,
  routerConfig: routerConfig,
)
```

Both constructors apply the same locale and theme choices. The app owns its
route map, deep links, navigation state and authorization. New Flutter apps use
this wrapper with `GichoBootstrap` and `GichoAppShell` unless the owner
explicitly directs an exception.

The public API is exported by [index.dart](index.dart). This construct does
not load configuration, choose routes, restore a session, authenticate a user
or create the app's pages. Those responsibilities remain explicit in the
consumer or a later generic bootstrap stage.
