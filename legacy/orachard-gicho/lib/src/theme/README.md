> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Theme

Gicho owns the application's simple theme engine and builds standard
Material `ThemeData`. Package defaults live in `theme.config.yaml`; validation
and override rules live in `theme.config.schema.json`.

The simple tier supplies eight named palettes. Flutter's
`ColorScheme.fromSeed` turns each palette into light and dark `ThemeData`, so
every widget below the app root—including future screens—uses the selected
theme without screen-specific work.

## Consumer setup

Use the package app wrapper instead of initializing and wiring theme properties
manually:

```dart
GichoMaterialApp.router(
  title: 'My app',
  router: router,
)
```

The wrapper automatically supplies `theme`, `darkTheme`, and `themeMode`, and
rebuilds when `selectTheme`, `selectMode`, or `toggleMode` changes the shared
controller. It also accepts locale delegates, supported locales, and a locale.

## Adding an app theme

Create `assets/gicho/theme.config.yaml` and declare themes by stable ID:

```yaml
themes:
  sunset:
    name: Bangkok sunset
    primary: "#D84315"
    secondary: "#F57C00"
    tertiary: "#6A1B9A"
```

App themes are merged with package themes. `name` and `primary` are required;
`secondary` and `tertiary` are optional catalog metadata. The current simple
tier derives its Material color scheme from `primary`; applying independently
configured color roles belongs to the future advanced tier. Colors use
six-digit `#RRGGBB` syntax. Set `defaultTheme` to any package or app theme ID to
change the initial selection.

`level` is package-locked to `simple`. Advanced component and typography
configuration will be a separate future tier rather than silently changing
the simple schema.

## Material UI migration

Gicho exports the Flutter-compatible `material_ui` surface through
`package:moztopia/gicho.dart`. The former experimental FlexColorScheme names
are not part of the current package API because that dependency was removed.
Applications should prefer `moztopiaTheme` and `GichoMaterialApp.router` so
configuration remains centralized.
