> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Theme

Gicho owns the application's simple theme engine and encapsulates
FlexColorScheme. Package defaults live in `theme.config.yaml`; validation and
override rules live in `theme.config.schema.json`.

The simple tier supplies eight named light/dark theme pairs. FlexColorScheme
turns each configured palette into normal Flutter `ThemeData`, so every widget
below the app root—including future screens—uses the selected theme without
screen-specific work.

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
`secondary` and `tertiary` are optional and are derived by FlexColorScheme when
omitted. Colors use six-digit `#RRGGBB` syntax. Set `defaultTheme` to any
package or app theme ID to change the initial selection.

`level` is package-locked to `simple`. Advanced component and typography
configuration will be a separate future tier rather than silently changing
the simple schema.

## Direct access

The compatible FlexColorScheme API remains exported for advanced experiments,
but applications using the simple tier should prefer `moztopiaTheme` and
`GichoMaterialApp.router` so configuration remains centralized.
