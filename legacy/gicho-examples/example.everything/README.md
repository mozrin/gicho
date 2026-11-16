> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Gicho everything example

This application demonstrates how a consuming Flutter app uses
`package:moztopia/gicho.dart` as its integration entry point.

It includes:

- five independent primary navigation stacks (`FNav1`–`FNav5`);
- four generic drawer destinations (`DNav1`–`DNav4`) plus `Logging`;
- compact bottom navigation and adaptive wide-screen navigation rail;
- root modal pages, nested modal stack management, and back navigation;
- package-owned configurable brightness, theme, and language app-bar actions;
- package-configured FlexColorScheme light, dark, and color-scheme selection,
  including an app-owned `Bangkok sunset` palette;
- 17 bundled languages with nonblocking remote catalog updates from the public
  Gicho localization repository;
- centralized navigation, action, framework, and asynchronous error logging;
- package-owned logging defaults with an application-owned configuration
  override and an effective-configuration viewer;
- package-owned language metadata with app-owned translation catalogs;
- 17 app-enabled languages presented through a searchable, lazy language modal;
- a package-owned 38-language display-name matrix used to localize the language
  selector itself;
- a global app-bar action that displays the aggregate in-memory JSON map;
- a Gicho-owned GoRouter facade with all routes still declared in app Dart;
- the optional `GichoPageShell` used for the demonstration layout;
- page-specific app-bar overrides in both directions;
- `GichoNotifications` hiding the selected notification implementation;
- an interactive `Logging` showcase.

## Run

```shell
flutter pub get
flutter run
```

## Validate

```shell
flutter analyze
flutter test
```

The example owns its routes, state, theme selections, translation catalogs,
and permitted feature overrides under `assets/gicho/`. Reusable
integrations, schemas, and package defaults come from `moztopia/gicho`.

## Core app-bar configuration

The example's `assets/gicho/core.config.yaml` contains switches for the
four global app-bar actions supplied by Gicho:

```yaml
appBar:
  actions:
    brightness:
      enabled: true
    theme:
      enabled: true
    language:
      enabled: false
    configDisplay:
      enabled: true
```

In plain language:

- `brightness.enabled: true` shows the light/dark-mode button.
- `theme.enabled: true` shows the button that opens the theme and color-scheme
  selector.
- `language.enabled: false` hides the language selector by default. The Dart
  shell enables it only while FNav1 is visible.
- `configDisplay.enabled: true` shows the button that displays the complete
  resolved configuration map.

Gicho owns the icons and behavior behind these standard actions. Changing an
entry changes the default for that button. Individual pages can reverse the
default with `GichoAppBar.actionOverrides`; FNav1 enables the globally hidden
language action, while FNav2 disables the globally visible configuration
action. Application features such as refreshing data remain on their
corresponding screens rather than becoming core framework configuration.

The drawer, rail, bottom navigation, and page routes in this example remain
example-owned Dart. `GichoPageShell` merely composes the Flutter widgets the
example supplies; consumers can omit it and use an ordinary `Scaffold`, as the
example's not-found page does.
