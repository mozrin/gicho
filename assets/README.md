# Gicho assets

Gicho bundles [`gicho.yaml`](gicho.yaml) and
[`gicho.schema.json`](gicho.schema.json). They currently establish
configuration version 1, package-owned `brand`, `theme`, and `app.startup`
objects, plus a consumer-extensible `app` subtree. Gicho reserves top-level `locale` and
`navigation` for later contracts. Permanent named choices and color data live
in [`assets/themes/`](themes/README.md).

## Consumer assets

A Flutter app may declare these files in its own `pubspec.yaml`:

```text
assets/gicho/gicho.yaml
assets/gicho/gicho.schema.json
```

Both are optional for a generic consumer. The YAML overrides package values.
The app schema describes only the `app` subtree and is needed when the YAML
adds app-owned keys. For example:

```yaml
# assets/gicho/gicho.yaml
app:
  startupMessage: Ready
```

```json
{
  "type": "object",
  "properties": {
    "app": {
      "type": "object",
      "additionalProperties": false,
      "required": ["startupMessage"],
      "properties": {
        "startupMessage": {"type": "string"}
      }
    }
  }
}
```

Declare the files explicitly; a consumer cannot make Gicho load an asset
that Flutter did not bundle:

```yaml
flutter:
  assets:
    - assets/gicho/gicho.yaml
    - assets/gicho/gicho.schema.json
```

Then load before building the ready application:

```dart
final values = await const GichoConfigurationService().loadApplication();
```

The service resolves **package defaults → consumer YAML → explicit runtime
overrides**. Maps merge recursively; lists and scalars replace; explicit `null`
must satisfy the schema. Package defaults are validated against the package
schema before app-only required keys are considered. The app YAML and runtime
overrides are validated as partial values against the combined schema, then
the resolved map is validated and deeply frozen. Unknown keys fail. A consumer
schema cannot redefine a Gicho-owned key or make the `app` subtree open to
unlisted keys. See the [service contract](../lib/src/services/configuration/README.md)
and the [independent bootstrap example](../examples/flutter-bootstrap/README.md).

`schemaVersion: 1` belongs to Gicho and cannot be changed by an app schema.
An app YAML may omit it and inherit the package version; an explicit mismatch
fails validation. Breaking package-owned configuration changes require a new
version and migration guide. The schema version is independent of the numeric package source version.

An app may set `brand.name`, `brand.logoAsset` and `brand.markAsset` in its YAML.
The full logo serves splash/sign-in surfaces; the mark serves small placements.
Declare referenced images in the consumer's `pubspec.yaml`. If an image cannot
load, `GichoBrandImage` shows the built-in symbol; a missing image does not
fail startup. See [the branding feature](../lib/src/features/branding/README.md)
and the [independent example](../examples/flutter-bootstrap/README.md).
Flutter assets are readable by users. Keep secrets out of these files except
for the owner's temporary development-only `placeLookup.googleApiKey` choice.
`GichoConfigurationService.loadApplication()` refuses that configuration
in release mode; consuming applications must also block deployment of builds
that bundle this key. The key must be replaced by a production credential plan
before release.

For development place lookup, a consumer can set:

```yaml
placeLookup:
  googleApiKey: YOUR_DEVELOPMENT_GOOGLE_KEY
```

See [PlaceLookup](../lib/src/ui/place_lookup/README.md). Google's native map
SDKs and web map script also require platform setup in the consuming app.

`app.startup` accepts minimum durations for company, product and loading
screens in milliseconds, plus a `fade`, `slide`, `scale` or `none` transition
and its duration. A consumer can set `companyArtworkAsset`,
`productArtworkAsset` and `loadingArtworkAsset` for uncropped foreground art.
For full scenes, set portrait and landscape asset paths together for each
stage, such as `productPortraitSceneAsset` and
`productLandscapeSceneAsset`. Gicho uses the portrait image below 768
logical pixels and the landscape image at wider widths; both fill the
viewport with center cropping. When no loading pair is set, the product pair
continues through initialization. Keep the image files in the consuming app's
asset bundle and configure their paths in its YAML. Use
`GichoStartupConfiguration.fromConfiguration(values)` and the public
`GichoStartup` widget to run the sequence without app-specific splash code.
The default product pair can be overridden by ordered
`scheduledProductScenes`. Each scene has an inclusive `start` and `end` in
`MM-DD` (annual) or `YYYY-MM-DD` (one-time) format, a portrait/landscape
pair, and optional two-letter `countries`. Selection uses the device's local
calendar date. A country-limited date triggers a lookup during the company
splash through the optional `countryLookupPath` on the consumer's HTTPS origin.
Cloudflare sites can set this to `/cdn-cgi/trace`; Gicho reads only its
`loc` field. A failed lookup selects the default art without requesting
device location permission.

For named themes, set `theme.available` to a nonempty subset of `default`,
`ocean` and `ember`, and set `theme.default` to one of that subset. The schema
rejects unknown names and duplicates; `ThemeController` enforces default
membership. Omit the object to inherit all three with Default selected. The
picker can select only available names and remembers the user's choice on
this device. Each name supports light and dark modes, with system appearance
used until the user chooses a mode. See the
[theme feature](../lib/src/features/themes/README.md) and
[independent example](../examples/flutter-themes/README.md).
