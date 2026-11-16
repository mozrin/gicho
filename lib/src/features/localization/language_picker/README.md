# GichoLanguagePicker

```dart
GichoLanguagePicker(controller: locales)
```

Material language selector backed by `GichoLocaleController`. It displays
only the app-enabled subset of Gicho's canonical registry and uses centralized package
catalog keys for its label and locale names. A consuming app may override
those fully qualified keys through its app catalog. Place the picker in an
app-owned settings or profile screen; Gicho does not choose navigation.
