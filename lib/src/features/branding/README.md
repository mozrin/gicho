# Branding

`GichoBrand` resolves a generic application name and two optional image
assets from Gicho configuration. A full logo suits sign-in and startup;
the compact mark suits an app bar or another small placement. An app declares
its own image files in `pubspec.yaml` and sets `brand.logoAsset` and
`brand.markAsset` in `assets/gicho/gicho.yaml`.

Read the brand after `GichoConfigurationService.loadApplication()`:

```dart
final brand = GichoBrand.fromConfiguration(configuration);
```

Use `GichoBrandHeader(brand: brand)` for the full presentation. The header
also accepts its previous `title`/`logo` arguments for existing consumers.
Image failures display Gicho's built-in brand symbol, so a missing image
does not prevent startup. Theme colors and provider button rules are outside
this feature.
