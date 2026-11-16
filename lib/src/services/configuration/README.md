# GichoConfigurationService

```dart
final configuration = const GichoConfigurationService().resolve(
  defaults: {'title': 'My app'},
  schema: {
    'type': 'object',
    'properties': {
      'title': {'type': 'string'},
    },
    'required': ['title'],
  },
  consumer: {'title': 'Customer'},
);
```

Generic asset-backed configuration for any consuming package. Supply package defaults YAML, a package-owned JSON Schema (Draft 2020-12), an optional consumer YAML path and schema, and optional programmatic overrides. Resolution is defaults → consumer → argument. An absent optional consumer asset inherits defaults; missing required defaults/schema assets and malformed present assets fail.

Maps merge recursively, lists/scalars replace, and explicit null is validated like any other value. `x-moztopia-locked: true` preserves the inherited package value. Local schema references are resolved for merge annotations; remote references are rejected. Overrides may omit required properties; defaults and the final result must satisfy the complete schema. Unknown keys are governed by additionalProperties. Values are deeply immutable.

Call `load` for caller-supplied asset paths or `resolve` for supplied maps.
`loadApplication()` uses Gicho's bundled
[`assets/gicho.yaml`](../../../../assets/gicho.yaml) and
[`assets/gicho.schema.json`](../../../../assets/gicho.schema.json),
plus optional app assets at `assets/gicho/gicho.yaml` and
`assets/gicho/gicho.schema.json`. The app schema may add keys only under
`app`. Package defaults are validated against the package schema first; app
fragments and runtime overrides are checked against the combined schema, then
the final result is checked and frozen. App-only required keys must appear in
the final result. Unknown keys and attempts to redefine Gicho-owned keys
fail with a configuration error.

```dart
final configuration =
    await const GichoConfigurationService().loadApplication();
```

Asset loading accepts an `AssetBundle` for host tests; no global cache,
environment interpolation, secret handling or authentication awareness. The
temporary `placeLookup.googleApiKey` development option is an explicit owner
exception to the normal rule against credentials in Flutter assets. It is
readable in the installed app. `loadApplication()` rejects it in release mode;
consuming release pipelines need a separate deployment check. See the [asset guide](../../../../assets/README.md)
for app schema and manifest examples. Test with
`flutter test lib/src/services/configuration/configuration_test.dart`.
