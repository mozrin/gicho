# Gicho

Gicho is Moztopia's generic Flutter foundation: configuration inheritance,
localization, startup and splash, themes, shared controls and application frames.
It is one package at this repository's root, with the public entry
`package:gicho/gicho.dart`.

## Quick start

Add the development branch (unreleased; validation is in progress):

```yaml
dependencies:
  flutter:
    sdk: flutter

  gicho:
    git:
      url: https://github.com/mozrin/gicho.git
      ref: develop
```

Run `flutter pub get`, then import the public API:

```dart
import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

final locales = GichoLocaleController(
  appCatalogs: const {'en': {'app.title': 'My app'}},
);

GichoMaterialApp(
  locales: locales,
  title: () => locales.text('app.title'),
  theme: gichoTheme(seedColor: const Color(0xFF17634F)),
  home: const StartupSplash(title: 'My app'),
);
```

That snippet shows the Material wrapper in isolation. A new application uses
`GichoBootstrap`, `GichoMaterialApp` and `GichoAppShell` together;
see the [bootstrap example](examples/flutter-bootstrap/lib/app.dart) for the
full composition. The owner must explicitly direct an exception to omit one.

Use `GichoBootstrap` to load consumer configuration with shared splash and
retry behavior, `GichoMaterialApp` for locale and theme setup,
`GichoStartup` for YAML-configured company, product and live initialization
screens (or `StartupSequence` for custom orchestration),
`GichoAppShell` for application navigation, and
`GichoModalPage` for a full-screen guided page with optional Back.
The shell accepts an app-owned title prefix and a tappable title callback when
a page title also opens a destination, while retaining its shared app-bar layout.
Shell destinations preserve `NavigationDestination.enabled` in both the
drawer and rail, allowing an app to show unavailable sections as disabled.
`GichoScanner` provides an embeddable square QR and barcode camera viewport
that reports raw code data and format to the caller.
Gicho also supplies Default, Ocean and Ember named themes with light/dark
variants. An app chooses its available subset and default; `ThemePicker` lets
the user change themes and appearance with a device-local saved preference.
Applications with their own palettes can use `GichoThemeModeController` to
persist only the appearance mode under an account-scoped preference key. The
locale controller also interpolates named catalog values through `text(key,
variables: {'name': value})`.
The [asset guide](assets/README.md) shows how `loadApplication()` inherits
Gicho defaults, resolves generic branding and validates an app-owned `app`
subtree.
Applications provide their content, translations, configured services and
navigation callbacks. Specialized authentication belongs to Authackage, which
may use Gicho's generic APIs; Gicho never depends on Authackage or Harmony.
Gicho's [20 supported languages](docs/languages.md) are available to apps;
each app enables its own subset and must include English.

Contact editors can use `StructuredPostalAddressFields` with country rules supplied
by Contackage and `ContactPhoneField` with a phone formatter, country choices
and owner-declared capabilities supplied by the consumer. `ContactEmailField`
accepts a syntax validator and verified state. Gicho displays
verification state only after the consumer confirms a delivered challenge.

See [the documentation index](docs/README.md) for the full API guide, package
boundary and migration instructions. Start with the
[focused examples](examples/README.md) for bootstrap, themes, a shared control,
and page navigation. The older [interactive gallery](examples/flutter/README.md)
remains as a multi-scenario reference. Legacy snapshots remain under `legacy/`
as references.

The [0.0.10 checkpoint note](docs/0.0.10-checkpoint.md) records the QR scanner
addition and remaining device acceptance. The earlier
[0.0.9 note](docs/0.0.9-checkpoint.md) remains a historical checkpoint.
