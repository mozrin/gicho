# Localization

```dart
final locales = GichoLocaleController(
  appCatalogs: const {'en': {'app.title': 'Customer'}},
);
final title = locales.text('app.title');
```

Import through `package:gicho/gicho.dart`. The
[locale controller](locale_controller/README.md) owns the supported-locale
registry and key lookup. The [language picker](language_picker/README.md)
changes the selected locale. Package-owned copy lives in [i18n](../../i18n/README.md),
not in individual widgets. Apps own their catalog entries and may override a
package key deliberately.
