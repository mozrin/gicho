> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Storage

Gicho exposes Shared Preferences and Flutter Secure Storage through
`package:moztopia/gicho.dart`.

## Application settings

```dart
final preferences = SharedPreferencesAsync();

await preferences.setBool('darkMode', true);
final darkMode = await preferences.getBool('darkMode');
```

Prefer `SharedPreferencesAsync` for new code. Use this package only for simple,
non-critical key-value settings; it is not a database or secure storage.

## Secrets

Use Flutter Secure Storage for credentials, authentication tokens, encryption
keys, and other sensitive values:

```dart
const secureStorage = FlutterSecureStorage();

await secureStorage.write(key: 'accessToken', value: token);
final token = await secureStorage.read(key: 'accessToken');
```

Secure Storage uses platform-specific protected storage. Review its platform
setup requirements before shipping, particularly Android backup configuration,
Apple Keychain accessibility, Linux dependencies, and HTTPS requirements on
the web.

Barrel files are utility-generated and must not be edited manually.

## Configuration reference

Storage currently has no Gicho YAML parameters and no `storage.config.yaml`.
Storage keys, platform options, encryption settings, backup policy, and data
migration remain application-owned. Adding `assets/gicho/storage.config.yaml` has no
effect.
