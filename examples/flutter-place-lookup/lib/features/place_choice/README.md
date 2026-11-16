# PlaceLookupMapScreen

Search live Google places and inspect the selected approximate area. This
app-owned screen composes Gicho's public `PlaceLookup` widget and receives
resolved YAML configuration from `app.dart`. Its development panel keeps draft
map and privacy options until Apply; Reset restores the example defaults.
Turning off the map demonstrates search-only behavior in the same app.

Without a configured Google key, the screen displays an offline-mode notice and
uses its private sample-city provider with maps disabled. Configured mode keeps
the live Google provider and maps. Search/selection and privacy are exercised
in test/app_test.dart; service/device acceptance remains separate.
