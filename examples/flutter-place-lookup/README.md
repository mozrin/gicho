# Flutter place lookup playground

This example exercises Gicho's PlaceLookup. With no key, it starts in clearly
labelled offline mode: search Bangkok, Auckland or Cairo and select a sample
city. With your own configured Google key, search live Google Places and choose
a suggestion. The returned location
starts as an approximate 3 km area. The map uses Google Maps on Android, iOS,
and web.

The component appears above the divider. Development parameters below it
control map visibility, gestures, zoom buttons, selected-coordinate display,
coordinate privacy radius, initial map zoom, and map height. Change options
then choose **Apply**; the lookup restarts with those options. **Reset**
restores the example defaults. Setting the privacy radius to 0 returns exact
coordinates and place ID, so keep the default 3 km for privacy-sensitive apps.
Turning off the map demonstrates search-only use without a second app.

The app owns the chosen selection and option state in
[lib/features/place_choice/](lib/features/place_choice/README.md).
[lib/app.dart](lib/app.dart) composes GichoBootstrap, GichoMaterialApp,
and GichoAppShell, while [lib/main.dart](lib/main.dart) starts the app.
[The package API](../../lib/src/ui/place_lookup/README.md) owns search, map,
and coordinate obfuscation.

From this directory, run `flutter pub get` and `flutter run -d chrome` for
web, or choose an Android/iOS development target. The owner handles physical
device checks. Host analysis is `flutter analyze`. Enable the matching Google
Maps API for the target platform as well as Places API (New).

No Google key is shipped. Set a user-owned, API-restricted development key in
`assets/gicho/gicho.yaml` by adding a `placeLookup` map with `googleApiKey`, enable Places API
(New) and the appropriate Maps API, then run the example locally. Never commit
the populated file. Browser/native assets expose client keys; restrict them at
the provider and use a consumer-owned secure adapter for production. Gicho
rejects this development Google provider in release mode.

Offline mode uses fixed public city coordinates and disables the map; it is not
a live Google result. Live Google
service acceptance needs the user's configured project and is separate from
host tests. This example does not store user location.
