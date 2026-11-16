# Configuration

Gicho loads package-owned feature defaults, validates package and
application values with JSON Schema Draft 2020-12, and merges permitted
application overrides.

## File convention

A configurable feature owns these package assets:

```text
lib/src/<feature>/
├── <feature>.config.yaml
└── <feature>.config.schema.json
```

A consuming application may add this optional override:

```text
assets/gicho/<feature>.config.yaml
```

Declare an application override in its `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/gicho/
```

Package assets are declared by Gicho and are loaded through the Dart package
name `moztopia`, for example
`packages/moztopia/lib/src/logging/logging.config.yaml`.

## Loading a feature

```dart
import 'package:moztopia/gicho.dart';

const service = ConfigurationService(
  loader: FlutterAssetConfigurationLoader(),
);

final configuration = await service.loadFeature('logging');
final debugColor = configuration.require<String>('colors.debug');
```

`loadFeature` loads the package YAML, package JSON Schema, and optional
application YAML concurrently. It validates both YAML documents and returns an
immutable `ConfigurationDocument`. Use `value(path)` for optional values,
`require<T>(path)` for required typed values, and `values` for a defensive copy.

The default configured features load through the shared `moztopiaConfig`
registry. It caches each resolved feature and exposes an aggregate map keyed by
feature name:

```dart
final allConfiguration = moztopiaConfig.values;
final logging = moztopiaConfig.feature('logging');
```

## Validation and merging

Feature schemas use standard JSON Schema keywords such as `type`, `properties`,
`enum`, `$defs`, `$ref`, and `additionalProperties`.

Gicho also recognizes the annotation:

```json
"x-moztopia-locked": true
```

- A locked property retains the package value.
- An unlocked property uses the application value when supplied.
- Values omitted by the application retain their package defaults.
- Invalid YAML, invalid JSON Schema input, unsupported values, and invalid
  overrides throw `ConfigurationException`.

## Current implementations

Core coordinates how feature-owned controls appear in the standard application
shell without taking ownership of feature settings. For example, an app can
globally disable the language action in `assets/gicho/core.config.yaml`.
Core currently exposes only the brightness, theme color, language, and
configuration-display switches. See the
[core configuration reference](../lib/src/core/README.md) for its typed Dart
API and YAML shape.

Logging defaults lock the info, warning, and error colors while allowing an
application to override the debug color:

```yaml
colors:
  debug: purple
```

`moztopiaLog.initialize()` loads this configuration and constructs the logger.
The asynchronous initialization should complete before startup code relies on
the synchronous `moztopiaLog.logger` getter.

Localization requires bundled English and always falls back through English to
the translation key. Applications may enable public Git catalog updates:

```yaml
remoteEnabled: false
```

The package defaults supply the public localization repository, the
`example.everything`
application directory, the `main` reference, and background loading policy.

`moztopiaLocalization.create(...)` loads the configuration before constructing
the `EasyLocalization` widget. Local and remote work starts concurrently;
`remoteLoadMode` selects background or blocking remote resolution. English is
locked and must be present locally. Language metadata comes from the
package-owned registry rather than application configuration or catalogs. See the
[localization configuration reference](../lib/src/localization/README.md#configuration-reference)
for the complete behavior and API.
