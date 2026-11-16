> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Core

Core coordinates package-owned features inside Gicho's standard application
shell. It does not duplicate feature configuration: theme palettes remain in
`theme.config.yaml`, languages remain in `localization.config.yaml`, and so on.

Package defaults live in `core.config.yaml`. A consuming application can add
`assets/gicho/core.config.yaml` to enable or disable registered app-bar
actions.

## App-bar settings in plain language

```yaml
appBar:              # Settings for the standard top app bar.
  actions:           # On/off switches for buttons registered in Dart.
    theme:           # The stable ID of one registered action.
      enabled: true  # Allow that action to be shown.
```

All standard app-bar features start off. `enabled: true` makes the matching
Gicho button visible by default in every standard app bar. `enabled: false`
hides it by default. An individual page can reverse that default in Dart.

The supported actions are:

- `brightness`: switch between light and dark mode;
- `theme`: open the theme color selector;
- `language`: open the language selector;
- `configDisplay`: display the complete resolved configuration map.
- `logout`: confirm logout through the active authentication delegate; this is
  visible only while authenticated.

Gicho owns these buttons, icons, and behaviors. The schema rejects other
action names. Application-specific buttons remain ordinary application UI and
do not belong in core configuration.

```yaml
appBar:
  actions:
    theme:
      enabled: true
    language:
      enabled: false
    configDisplay:
      enabled: true
```

This is enough to turn off a package default:

```yaml
appBar:
  actions:
    language:
      enabled: false
```

Initialize core before constructing the standard shell:

```dart
await moztopiaCore.initialize();
```

Check whether configuration permits an action with:

```dart
final enabled = moztopiaCore.configuration.isFeatureEnabled(
  GichoAppBarFeature.configurationDisplay,
);
```

`GichoAppBar` reads the resolved policy and renders the enabled global
actions:

```dart
GichoAppBar(
  title: const Text('Report'),
)
```

Override one global default for one page:

```dart
GichoAppBar(
  title: const Text('Language settings'),
  actionOverrides: const {
    GichoAppBarFeature.languageSelector: true,
  },
)
```
