# GooglePlaceLookupProvider

`GooglePlaceLookupProvider` uses Google Places API (New) autocomplete and place
details. It keeps one session token through a place selection. Pass it to
`PlaceLookup`, or let `PlaceLookup.fromConfiguration` create it from the
consumer application's YAML configuration.

## Development quickstart

1. Create a Google Maps Platform API key for the application and enable Places
   API (New). If the map is shown, also enable the platform's map API: Maps SDK
   for Android, Maps SDK for iOS, or Maps JavaScript API for web. Configure the
   key's application and API restrictions for the platforms and APIs you use.
2. Put the key in the **consumer application's**
   `assets/gicho/gicho.yaml`, as in the
   [example asset](../../../../../examples/flutter-place-lookup/assets/gicho/gicho.yaml):

   ```yaml
   placeLookup:
     googleApiKey: YOUR_GOOGLE_API_KEY
   ```

3. Include that YAML file in the application's `pubspec.yaml` assets. Load it
   with `GichoConfigurationService`, then pass the resulting configuration
   map to `PlaceLookup.fromConfiguration`:

   ```dart
   final configuration = await const GichoConfigurationService()
       .loadApplication();

   PlaceLookup.fromConfiguration(
     configuration: configuration,
     onSelected: (selection) {
       // Use the selected area in the application.
     },
   );
   ```

   The [focused example](../../../../../examples/flutter-place-lookup/README.md)
   shows the configuration load inside `GichoBootstrap` and the widget in
   its screen. The YAML key is used for Places requests; it does **not** load
   the Google Maps SDK by itself.

4. When showing the map, supply the same key to the target platform's map
   loader. The example reads its YAML key in
   [Android Gradle](../../../../../examples/flutter-place-lookup/android/app/build.gradle.kts)
   and passes it to the manifest's `com.google.android.geo.API_KEY` metadata;
   [iOS AppDelegate](../../../../../examples/flutter-place-lookup/ios/Runner/AppDelegate.swift)
   calls `GMSServices.provideAPIKey` before Flutter starts; and
   [web index.html](../../../../../examples/flutter-place-lookup/web/index.html)
   loads the Maps JavaScript API before Flutter. Adapt the loader for the
   consuming application. For search-only use, set `showMap: false`; no map
   loader is needed.
5. From the example directory, run `flutter pub get` and `flutter run -d chrome`
   for a web development check, or choose an Android or iOS development target.
   Search for a place and select a suggestion. The owner handles tests on
   physical devices.

You can construct the provider directly when the application manages its own
development configuration:

```dart
PlaceLookup(
  provider: GooglePlaceLookupProvider(apiKey: googleApiKey),
  onSelected: (selection) {
    // Use the selected area in the application.
  },
);
```

The key in a Flutter asset and in platform map loaders is bundled and readable
by users. This integration is for development: the provider rejects release
mode while a secure credential design is unresolved. A consuming release
pipeline still needs an artifact gate; the widget cannot enforce deployment
policy. Keep `coordinatePrecisionKm` at its default `3` for approximate
locations, or set it to `0` only when exact coordinates are required.
