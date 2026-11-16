> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Logging

Gicho exposes both Logger and the configured `moztopiaLog` instance through
`package:moztopia/gicho.dart`.

Use configured package logging when package defaults and the optional
application override should apply:

```dart
await moztopiaLog.initialize();
await moztopiaLog.info('Application started');
await moztopiaLog.error(
  'A request failed',
  error: error,
  stackTrace: stackTrace,
);
```

The first log call initializes lazily if needed. Initialization reads
`assets/gicho/logging.config.yaml` when the consuming application supplies it.
The configured printer disables level emojis. Severity is represented by the
locked level colors while boxed output remains enabled.

Use Logger directly when the application owns the complete logging policy:

```dart
final log = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

log.i('Application started');
log.w('A recoverable problem occurred');
log.e('A request failed', error: error, stackTrace: stackTrace);
```

Logger supports trace, debug, info, warning, error, and fatal events.
Its filters, printers, console, stream, memory, file, and multi-output features
remain available without a Gicho-specific wrapper.

Keep application policy in the consuming app. That includes minimum levels,
redaction of secrets and personal data, production outputs, log persistence,
and forwarding events to observability or crash-reporting services.

Barrel files are utility-generated and must not be edited manually.

## Configuration reference

The optional application file is `assets/gicho/logging.config.yaml`. Declare it in
the consuming application's `pubspec.yaml` before using an override.

```yaml
boxing: false
colors:
  debug: purple
```

| YAML parameter | Type | Package default | Allowed values | App override | Caveat |
| --- | --- | --- | --- | --- | --- |
| `boxing` | boolean | `true` | `true`, `false` | Yes | `false` selects compact `time [LEVEL] message` output. |
| `colors.debug` | string | `green` | `blue`, `red`, `yellow`, `green`, `purple` | Yes | Applied when the configured logger is initialized. |
| `colors.info` | string | `blue` | N/A | No | Locked; application values are ignored. |
| `colors.warn` | string | `yellow` | N/A | No | Locked; application values are ignored. |
| `colors.error` | string | `red` | N/A | No | Locked; application values are ignored. |

Unknown keys and unsupported values fail validation with
`ConfigurationException`. The application file is optional; omitting it uses
all package defaults. Omit locked parameters from application YAML because
they cannot change the effective configuration. Await
`moztopiaLog.initialize()` before reading
`moztopiaLog.logger`. These parameters configure `moztopiaLog`; they do not
alter independently constructed `Logger` instances.

With `boxing: false`, each event is emitted as one colored line without emojis:

```text
12:30:40.550 [INFO] Application started
12:30:41.120 [WARN] Connection is slow
12:30:42.310 [ERROR] Request failed
```

Multiline messages, errors, and stack traces are flattened onto the same line
with a `↵` separator.

## Configuration schema integration

Logging is the reference consumer of the package configuration engine. Its
package-owned files are:

```text
lib/src/logging/logging.config.yaml
lib/src/logging/logging.config.schema.json
```

`MoztopiaLogging.initialize()` calls
the shared `moztopiaConfig` registry for `logging`. That loads and independently
validates the package defaults and optional `assets/gicho/logging.config.yaml`, then
merges and caches them before constructing the logger. The schema is owned by
Gicho; an application can supply YAML values but cannot replace the schema.

The schema closes both its root and `colors` object with
`additionalProperties: false`, so unknown parameters and color names fail
validation. Its reusable `$defs.color` definition limits colors to `blue`,
`red`, `yellow`, `green`, and `purple`. The `x-moztopia-locked` annotations are
placed directly on each color property: `debug` is unlocked, while `info`,
`warn`, and `error` are locked. `boxing` is also unlocked.

Locked app values are validated before merging even though the package value
wins. Applications should therefore omit locked properties rather than repeat
them. Logging consumes the resolved `boxing` boolean and complete `colors` map
with `ConfigurationDocument.require<T>`, so package defaults must continue to
supply both values.

See the configuration [schema bible](../config/README.md#schema-bible) for the
full YAML rules, supported JSON Schema syntax, exact merge behavior, extension
contract, limitations, and checklist for configurable features.
