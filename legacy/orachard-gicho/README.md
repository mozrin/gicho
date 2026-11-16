> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Gicho

> [!IMPORTANT]
> Current package implementation reference — not Orchard product authority
>
> Check executable code and passing tests before relying on this guide. Issue
> #139 restored the package analysis/test baseline; #20 and #21 own Orchard's
> eventual component boundary and engineering standards.

<p align="left">
  <img src="logo.svg" alt="Gicho logo" width="180">
</p>

[`moztopia/gicho`](https://github.com/mozrin/gicho) is the single
Flutter dependency and public API entry point for shared Flutter integrations
used by Moztopia applications.

Applications depend on this package instead of selecting and versioning its
underlying packages independently. Gicho owns the compatible dependency
ranges and re-exports their complete APIs without unnecessary wrappers.

## Installation

Install `moztopia/gicho` directly from GitHub:

```yaml
dependencies:
  flutter:
    sdk: flutter
  moztopia:
    git:
      url: https://github.com/mozrin/gicho.git
      ref: main
```

The repository is private, so developers and CI runners need GitHub access.
Pin `ref` to an approved release tag or commit for production applications.
For local development beside this repository, replace `git` with
`path: ../gicho`.

### Authenticate with GitHub CLI instead of SSH

Developers authenticated with GitHub CLI can use an HTTPS repository URL and
do not need to configure an SSH key for dependency resolution. Authenticate
and configure Git to use GitHub CLI as its credential helper:

```shell
gh auth login --git-protocol https
gh auth setup-git
```

Then reference the repository over HTTPS:

```yaml
dependencies:
  flutter:
    sdk: flutter
  moztopia:
    git:
      url: https://github.com/mozrin/gicho.git
      ref: main
```

GitHub CLI accepts the short repository name `moztopia/gicho` in its own
commands, but Dart Pub requires a Git URL in `pubspec.yaml`. The HTTPS URL above
uses the credentials managed by GitHub CLI without exposing a token in the
manifest.

### Select a release with `ref`

The `main` branch always points to the most current released version. Use it
when an application should follow the latest release:

```yaml
moztopia:
  git:
    url: https://github.com/mozrin/gicho.git
    ref: main
```

Every release is also identified by an immutable version tag. Pin `ref` to a
tag when an application must remain on that release, including after `main`
moves forward:

```yaml
moztopia:
  git:
    url: https://github.com/mozrin/gicho.git
    ref: v0.0.1
```

The `develop` branch is a moving target containing unreleased changes and is
not suitable for normal consumers. Consumers should use `main` for consistency
with the current release or pin `ref` to a specific version tag for a stable,
repeatable dependency resolution. After changing `ref`, run
`flutter pub upgrade moztopia` to update an existing lockfile to the selected
branch, tag, or commit.

Do not add re-exported packages such as `logger`, `go_router`, or `material_ui`
directly to the consuming application.

Run dependency resolution after changing `pubspec.yaml`:

```shell
flutter pub get
```

## Public API: one source of truth

The only supported application import is:

```dart
import 'package:moztopia/gicho.dart';
```

Do not import `package:moztopia/src/...` or the generated `exports_*.dart`
files. Those paths are implementation details. Do not edit files beginning
with `// Created with barrel workflow utility.`; the barrel utility owns them.

Application-specific policy remains in the application. Examples include API
base URLs, routes, providers, form models, log redaction, storage keys,
translation catalogs, and the selected theme. Stable organization-wide policy
may be added to this package as small, focused files.

## Using the complete package

Import the public library normally when an application uses several features:

```dart
import 'package:moztopia/gicho.dart';

final router = GoRouter(routes: []);
final log = Logger();
final client = Dio();
```

Dart and Flutter tree shaking remove unreachable release code. A broad import
does not mean every exposed package is initialized or bundled wholesale.

## Cherry-picking a feature

Use Dart's `show` combinator when a file should expose only selected symbols
while retaining the single public Gicho import.

Logging only:

```dart
import 'package:moztopia/gicho.dart'
    show Logger, PrettyPrinter, ProductionFilter;

final log = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(methodCount: 0),
);
```

Routing only:

```dart
import 'package:moztopia/gicho.dart'
    show GoRoute, GoRouter, GoRouterState;
```

The same approach works for every feature. Add symbols to the `show` list as
they are needed. Do not bypass Gicho with `package:logger/logger.dart` or
another upstream import; doing so creates a second source of dependency and
upgrade instructions.

## Included capabilities

- **Assets:** Flutter SVG for vector assets.
- **Authentication:** An opt-in, protocol-neutral delegate stage implemented by
  consumer applications or Flextensions.
- **Core:** Cross-feature application-shell composition and configurable
  app-bar action availability.
- **Entitlements:** Provider-neutral store products, purchases, restores,
  identified-user lifecycle, stale cache state, and a Qonversion adapter.
- **Configuration:** Package defaults, application overrides, JSON Schema
  validation, and schema-controlled merging.
- **Forms:** Reactive Forms for model-driven forms and validation.
- **Localization:** Easy Localization, Flutter localization delegates, `intl`,
  `translate(key)`, and a resilient loader that displays keys when catalogs
  cannot load.
- **Logging:** Logger with its complete levels, filters, printers, and outputs.
- **Media:** Typed, testable photo selection, camera, EXIF normalization, and
  fixed-ratio crop flows that accept application-owned copy and policy.
- **Networking:** Dio for HTTP clients, interceptors, cancellation, and data
  transfer.
- **Notifications:** Toastification for transient in-app messages.
- **Routing:** go_router for URL, nested, shell, and modal navigation.
- **State:** Flutter Riverpod for reactive state and dependency management.
- **Storage:** Shared Preferences for settings and Flutter Secure Storage for
  secrets.
- **Startup:** An opt-in launch stage with typed sequential/concurrent task
  groups and a replaceable presentation.
- **Theme:** Configured Material color palettes with automatic light, dark,
  system-mode, and app-wide selection support.

Responsive behavior uses Flutter's built-in layout and adaptive navigation
APIs, so no separate layout dependency is exposed.

## Configuration

Gicho features can own validated package defaults while allowing a
consuming application to provide permitted overrides. Each configurable
feature stores its defaults and JSON Schema in the package:

```text
lib/src/<feature>/
├── <feature>.config.yaml
└── <feature>.config.schema.json
```

A consuming application can optionally add an override at
`assets/gicho/<feature>.config.yaml` and declare it in its `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/gicho/
```

For example, an application can override the configurable logging debug color:

```yaml
boxing: false
colors:
  debug: purple
```

Initialize the configured logging API before `runApp` when startup ordering
matters:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await moztopiaLog.initialize();
  runApp(const App());
}
```

The package loads its defaults and schema plus the optional application YAML,
validates both documents, and merges only values permitted by the schema.
Fields marked with `x-moztopia-locked: true` retain the package value. Default
configured features are cached in `moztopiaConfig`, whose `values` getter
provides an in-memory map keyed by feature name. See the
[configuration overview](docs/configuration.md) and the
[configuration feature guide](lib/src/config/README.md) for the complete
convention and API.

## Localization assets

Translation catalogs and `assets/gicho/localization.config.yaml` source/language
options belong to the consuming application. Catalogs live directly under
`assets/gicho/`. When localization is enabled without `en.json`, startup
continues with an empty fallback catalog, logs a warning, and displays missing
translation keys. The package can concurrently retrieve updated catalogs from
a configured public Git repository while retaining bundled catalogs as the
offline baseline.

One `assets/gicho/` declaration bundles all app-owned Gicho augmentation
files. Localization does not expose a configurable local asset path.

The loader boundary supports a future versioned localization endpoint without
coupling screens to networking, caching, or the server response format.

## Example application

The [`gicho-examples`](https://github.com/mozrin/gicho/tree/develop/legacy/gicho-examples/example.everything)
application demonstrates independent footer
navigation stacks, drawer-only destinations, modal stacks, conditional app-bar
actions, themes, 17 app-enabled languages, resilient localization, and comprehensive
logging.

Clone `gicho` and `gicho-examples` as sibling directories, then run:

```shell
cd ../gicho-examples/example.everything
flutter run
```

## Validation

Run package and example checks separately:

```shell
flutter analyze
flutter test

cd ../gicho-examples/example.everything
flutter analyze
flutter test
```

## Repository README index

- **Repository documentation**
  - [`docs/configuration.md`](docs/configuration.md) — configuration file
    layout, schema rules, merge behavior, loading, and value access.
  - [`CHANGELOG.md`](CHANGELOG.md) — package release history.
  - [`TODO.md`](TODO.md) — planned package work and design notes.
- **Example application**
  - [`example.everything/README.md`](https://github.com/mozrin/gicho/blob/develop/legacy/gicho-examples/example.everything/README.md) — runnable demonstration of the
    package integrations and navigation architecture.
  - **Example guides**
    - [`configuration.md`](https://github.com/mozrin/gicho/blob/develop/legacy/gicho-examples/example.everything/docs/dart/foundation/configuration.md) —
      loading, merging, and reading feature configuration.
    - [`logging.md`](https://github.com/mozrin/gicho/blob/develop/legacy/gicho-examples/example.everything/docs/dart/foundation/logging.md) — logging
      behavior demonstrated by the example.
    - [`package linkage.md`](https://github.com/mozrin/gicho/blob/develop/legacy/gicho-examples/example.everything/docs/dart/foundation/ping.md) — a minimal
      compile-time package linkage check.
    - [`upload.md`](https://github.com/mozrin/gicho/blob/develop/legacy/gicho-examples/example.everything/docs/flutter/features/upload.md) — current upload
      support boundary and application ownership.
  - **Platform assets**
    - [`iOS launch image README`](https://github.com/mozrin/gicho/blob/develop/legacy/gicho-examples/example.everything/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md)
      — instructions for replacing the iOS launch-screen images.
- **Package feature guides (`lib/src`)**
  - [`assets/README.md`](lib/src/assets/README.md) — loading and declaring SVG
    assets with Flutter SVG.
  - [`config/README.md`](lib/src/config/README.md) — feature configuration
    files, JSON Schema validation, locked values, and runtime merging.
  - [`forms/README.md`](lib/src/forms/README.md) — building model-driven forms
    and validation with Reactive Forms.
  - [`localization/README.md`](lib/src/localization/README.md) — translation
    setup, resilient loading, locale changes, and future remote catalogs.
  - [`logging/README.md`](lib/src/logging/README.md) — Logger levels, formatting,
    outputs, redaction, and application-owned logging policy.
  - [`media/README.md`](lib/src/media/README.md) — reusable photo capability,
    camera, selection, crop, platform adapters, and application boundaries.
  - [`networking/README.md`](lib/src/networking/README.md) — Dio client setup and
    application-owned networking configuration.
  - [`notifications/README.md`](lib/src/notifications/README.md) — validated
    notification catalogs, durable in-app feeds, unread state, destinations,
    channel boundaries, and transient Toastification feedback.
  - [`routing/README.md`](lib/src/routing/README.md) — route definitions, deep
    links, nested navigation, and shell routes with go_router.
  - [`state/README.md`](lib/src/state/README.md) — providers, reactive state,
    dependency injection, and testing with Riverpod.
  - [`storage/README.md`](lib/src/storage/README.md) — choosing between Shared
    Preferences and protected secure storage.
  - [`theme/README.md`](lib/src/theme/README.md) — Material theme usage and the
    boundary for organization-wide theme policy.
