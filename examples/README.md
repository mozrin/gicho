# Gicho examples

Each directory is an independent consumer app with one component or scenario and its own
`pubspec.yaml`. Its `lib/main.dart` starts the app; `lib/app.dart` makes the
Gicho composition visible. App-owned screens live under `lib/features/`
when they need a separate construct. Examples use the public
`package:gicho/gicho.dart` API through a local path dependency.

- [Flutter bootstrap](flutter-bootstrap/README.md): asynchronous startup,
  failure and retry, then a ready Gicho application.
- [Flutter distance slider](flutter-distance-slider/README.md): one adjustable
  playground for the shared `DistanceSlider`.
- [Flutter page flow](flutter-page-flow/README.md): shell home to a full-screen
  modal page and Back.
- [Flutter themes](flutter-themes/README.md): app-selected named themes,
  light/dark/system appearance and remembered user choice.
- [Flutter scanner](flutter-scanner/README.md): one Android camera flow
  configured for employee/menu QR and product barcode meanings.
- [Flutter place lookup](flutter-place-lookup/README.md): one live Google place
  search playground with adjustable map and coordinate privacy options.
- [Flutter gallery](flutter/README.md): the older interactive multi-scenario
  gallery, retained while focused examples replace its scenarios. It is not
  the structure to copy for a new app.

Most focused apps include Android and Linux host scaffolding; the scanner
example targets Android because its camera plugin lacks a Linux backend. Run
`flutter pub get`, `flutter analyze` and `flutter test` inside each directory.
Host tests do not prove physical camera/device behavior. All seven apps also
include web scaffolding: run `flutter run -d chrome` for browser verification.
The place-lookup app starts in labelled offline mode without credentials; live
Google mode requires user-supplied configuration.
The bootstrap example exercises configuration and branding. Authentication
examples belong in Authackage because
Gicho does not depend on it.

## Repeatable acceptance

Execute `python3 tools/verify_examples/verify_examples.py` from the repository
root for package and maintained-example dependency resolution, analysis and
tests. Add `--build-web` to create development web builds. The script executes
checks; it does not replace interactive runtime or physical-device acceptance.
See [validation evidence](../docs/validation.md) for what was actually verified.
