# GichoThemeModeController

Persists only `ThemeMode` for a caller-supplied preference key. Use it with
application-owned light and dark `ThemeData` in `GichoMaterialApp`. Call
`bind` whenever the account changes; it immediately resets the previous
account's mode, then restores the new account's saved choice. A null key clears
the binding for sign-out. The caller owns the preference storage and disposes
the controller.
An explicit mode change takes precedence over a preference read still in flight.

```dart
final modes = GichoThemeModeController(
  readPreference: preferences.getString,
  writePreference: preferences.setString,
);
await modes.bind('app.theme_mode.$accountId', initialMode: ThemeMode.light);
await modes.setMode(ThemeMode.dark);
```

The controller does not select a named palette or supply `ThemeData`.
