> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Localization

Gicho owns the localization engine, configuration schema, catalog source
adapters, fallback policy, and Easy Localization integration. A consuming app
owns its supported languages, bundled catalogs, and optional remote catalog
location.

Applications import only the package public API:

```dart
import 'package:moztopia/gicho.dart';
```

## Runtime availability

Widgets below `GichoBootstrap` can ask whether localization is actually
available rather than inspecting a setup flag:

```dart
final localization = GichoLocalization.of(context);

if (localization.isAvailable) {
  // Localization has been installed and translation lookup is available.
}
```

`GichoLocalization.of(context)` intentionally fails with a clear error when
the widget is not below `GichoBootstrap`.

## Application setup

An app ships translation catalogs under its Flutter assets:

```text
assets/gicho/
├── en.json
└── th.json
```

English is the fallback language, but `en.json` is optional. When it is absent,
localization starts with available package/system translations or an empty map,
logs a warning, and displays untranslated keys. Each other app-enabled language
has a locale file; that file may contain bundled translations or be an empty
placeholder whose values come from remote catalogs or English fallback.

Declare the configuration and catalog folder in the app `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/gicho/
```

The directory contains all app-owned Gicho augmentation files, including
feature override YAML and locale JSON catalogs.

The app override defines only behavior that differs from the package defaults:

```yaml
remoteEnabled: false
```

Catalog files contain application translations only:

```json
{
  "welcome": "Welcome",
  "language": "Language"
}
```

Language names and labels are baked into the package-owned
`localization.languages.json` registry and validated by
`localization.languages.schema.json`. Apps never repeat that metadata.
Each language entry translates its name into every registered display language,
allowing language-selection interfaces to follow the currently selected locale
while retaining native and English reference names.

The app does not construct loaders or parse this map. It asks the package to
create localization:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final localizedApp = await moztopiaLocalization.create(
    useOnlyLangCode: true,
    saveLocale: false,
    child: const App(),
  );

  runApp(localizedApp);
}
```

The package derives `supportedLocales` from bundled locale filenames and the
package registry. Remote source settings and fallback behavior come from the
resolved feature configuration.

The package registry defines every language Moztopia can understand. An app
enables a subset by bundling `<iso639>.json` files under `assets/gicho/`; no locale
list is duplicated in YAML. Unknown filenames are rejected. The English locale
remains enabled even when `en.json` is absent. An empty non-English catalog
intentionally demonstrates English fallback behavior.

## Catalog resolution

The package starts local and remote work concurrently. Local English is an
optional baseline; remote catalogs are optional updates.

```text
Remote selected-language catalog
              ↓ recursively overlays
Bundled selected-language catalog
              ↓ missing or empty value
Bundled/updated English fallback value
              ↓ missing or empty value
Translation key
```

Rules:

- When present, `assets/gicho/en.json` must contain valid JSON with an object
  root. It may be an empty object.
- Catalogs contain translation keys and values only; language metadata is
  package-owned.
- Registry entries contain `label`, `iso639`, and a `names` map translating
  that language's name into every registered display language.
- Missing local English logs a warning and uses available system translations
  or an empty map. Invalid JSON remains an error because shipped data must be
  trustworthy.
- A locale filename enables that language for the app. Any catalog may be empty
  when the app intentionally relies on remote content, fallback, or package UI
  translations.
- Invalid local catalogs are fatal when read because shipped application data
  must be trustworthy.
- Remote requests start in parallel for every app-enabled language.
- Remote maps recursively overlay matching bundled maps.
- Remote failures and missing remote files are nonfatal.
- A failed remote request leaves the bundled catalog intact.
- Successful remote catalogs are cached in memory for the process.
- Remote blank values remain blank. Easy Localization then tries English; when
  English is also missing or blank, it displays the key.

## Remote load modes

`remoteLoadMode` supports two policies.

### Background

```yaml
remoteLoadMode: background
```

This is the package default. Remote requests begin alongside local validation,
but localization creation waits only for valid local English. The app can start
from its bundled catalogs without depending on network availability.

A remote catalog already available when Easy Localization loads a locale is
merged immediately. A catalog that completes later is cached and used the next
time that locale is loaded. Persistent caching and forced live refresh are not
part of the current implementation.

### Blocking

```yaml
remoteLoadMode: blocking
```

Local and remote requests still run in parallel, but localization creation
waits for every remote request to complete or fail. Use this when the first
render must use the newest reachable catalogs. Remote failures remain nonfatal
and fall back to bundled content.

## Fixed fallback policy

English is the non-configurable fallback language:

```yaml
fallbackLanguage: en
```

The package schema locks this value. A bundled English catalog is optional but
must be valid when present.

Fallback behavior is also fixed:

| Selected value | English value | Display |
| --- | --- | --- |
| Present | Any | Selected value |
| Missing or blank | Present | English value |
| Missing or blank | Missing or blank | Translation key |

The package always configures:

```dart
fallbackLocale: const Locale('en'),
useFallbackTranslations: true,
useFallbackTranslationsForEmptyResources: true,
```

## Source adapters

`LocalizationCatalogSource` is the generic package boundary:

```dart
abstract interface class LocalizationCatalogSource {
  Future<Map<String, dynamic>?> load(Locale locale);
}
```

Current implementations:

- `AssetLocalizationCatalogSource` reads bundled JSON from Flutter assets.
- `GitLocalizationCatalogSource` converts a public GitHub repository,
  reference, path, and locale into a raw HTTPS request.
- `TieredLocalizationCatalogLoader` validates, caches, and merges both tiers.

`remoteSource: git` describes repository semantics. The running app does not
clone Git; it downloads public raw files over HTTPS.

The adapter boundary permits future local or remote sources without moving
loading logic into consuming applications.

## Remote URL convention

A Git catalog resolves as:

```text
https://raw.githubusercontent.com/<owner>/<repo>/<reference>/<remotePath>/<locale>.json
```

Example:

```text
https://raw.githubusercontent.com/mozrin/gicho/develop/legacy/gicho-localization/example.everything/th.json
```

`remoteReference` may name a branch, version tag, or commit. A tag or commit is
preferred when an app requires immutable catalog resolution.

## Configuration reference

The package owns:

```text
lib/src/localization/localization.config.yaml
lib/src/localization/localization.config.schema.json
lib/src/localization/localization.languages.json
lib/src/localization/localization.languages.schema.json
```

The app may override permitted values in:

```text
assets/gicho/localization.config.yaml
```

| Parameter | Package default | App override | Meaning |
| --- | --- | --- | --- |
| `fallbackLanguage` | `en` | No | Required bundled fallback language. |
| `localSource` | `assets` | No | Bundled catalog source adapter. |
| `remoteEnabled` | `false` | Yes | Enables optional remote catalog updates. |
| `remoteSource` | `git` | No | Remote source adapter. |
| `remoteLoadMode` | `background` | Yes | `background` or `blocking`. |
| `remoteRepository` | `https://github.com/mozrin/gicho` | Yes | Public HTTPS GitHub repository URL. |
| `remotePath` | `example.everything` | Yes | Application directory inside the localization repository. |
| `remoteReference` | `main` | Yes | Branch, tag, or commit. |

When `remoteEnabled` is true, `remoteRepository` is required. `remotePath`
defaults to the `example.everything` application directory and can be overridden by other
consuming applications. English must be present locally.

The resolved localization document is cached under `localization` in
`moztopiaConfig.values`. Language metadata is package reference data rather
than feature configuration. After localization is created, UI can consume it
from:

```dart
moztopiaLocalization.languages
```

## Translation APIs

Translate keys and change the active language normally:

```dart
Text(translate('navigation.home', context: context));
await context.setLocale(const Locale('th'));
```

Gicho also exports Easy Localization, Flutter localization delegates, and
the `intl` API. Translation catalogs remain application data even though the
package owns the machinery that loads them.

## Errors

`LocalizationException` reports malformed catalog failures. Missing local
English and remote errors are logged by the configured package API and do not
prevent startup.

Do not put secrets or credentials in localization configuration. The current
Git source supports public repositories only. Authentication, integrity hashes,
signatures, and persistent catalog caching are future security work.

## Package/example separation

The package owns:

- schemas, defaults, and the shared language metadata registry;
- typed configuration;
- local and remote source adapters;
- parallel scheduling, caching, merging, and fallback behavior;
- errors and Easy Localization construction.

The consuming app owns:

- bundled JSON catalogs;
- the fixed `assets/gicho/` augmentation directory;
- remote repository paths;
- repository and reference;
- whether remote loading is enabled and whether it blocks.

The app must not duplicate loader, merge, network, or fallback implementation.

See the configuration [schema bible](../config/README.md#schema-bible) for the
shared YAML rules, schema syntax, locking, and merge contract.

Barrel files are utility-generated and must not be edited manually.
