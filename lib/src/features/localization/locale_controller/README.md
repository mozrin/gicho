# GichoLocaleController

```dart
final locales = GichoLocaleController(
  appCatalogs: const {'en': {'app.title': 'Customer'}},
);
```

Canonical locale registry and key-driven lookup for Gicho UI. The package
registers the [20 supported languages](../../../../../docs/languages.md),
including Chinese (`zh`) with Simplified Chinese text. A consumer may enable
only registered locales and must include English (`en`). Register a new locale
and its package catalog before a consuming app can select it.

Construct with app-owned, locale-specific catalogs and `enabledLocales` for
the locales that app has translated. The default exposes English only. Use
the registered codes, such as `zh`, for catalog maps. App values override package
values for the same fully qualified key; missing keys render the exact key.
There is no fallback to English when the selected locale lacks a translation.
The controller rejects unregistered and app-disabled selections. It notifies
listeners when `setLocale` changes the active locale.
The app owns and disposes the controller.

Catalog values may contain named placeholders. Pass `variables` to `text`, for
example `text('app.greeting', variables: {'name': customerName})` for a value
such as `Hello, {name}`. Values come from the selected locale's catalog;
missing keys still render the exact key.
