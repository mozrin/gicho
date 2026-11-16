> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Assets

Gicho exposes Flutter SVG through `package:moztopia/gicho.dart`.

```dart
SvgPicture.asset(
  'assets/logo.svg',
  semanticsLabel: 'Logo',
);
```

Use it directly for SVG assets, strings, bytes, files, and network resources.
Declare application assets in the consuming application's `pubspec.yaml`.

Barrel files are utility-generated and must not be edited manually.

## Configuration reference

Assets currently has no Gicho YAML parameters and no
`assets.config.yaml`. Asset paths, bundle declarations, SVG semantics, network
loading, and caching remain application-owned. Adding `assets/gicho/assets.config.yaml`
has no effect.
