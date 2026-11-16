# Supported languages

Gicho registers these 20 language codes for its Flutter locale controller,
language picker and package-owned copy. Consumer apps choose any subset of this
set for which they provide their own translated text. Every enabled subset must
include English (`en`); the default is English only. An app cannot enable a
language outside the registry. Missing text renders its exact key, with no
automatic English fallback.

```dart
final locales = GichoLocaleController(
  enabledLocales: const [Locale('en'), Locale('vi')],
  appCatalogs: const {
    'en': {'app.title': 'Customer'},
    'vi': {'app.title': 'Khách hàng'},
  },
);
```

The app owns all of its visible text, including text outside Gicho widgets.
Keep the same app keys in each enabled catalog before offering that language.

| Language | Code |
| --- | --- |
| English | `en` |
| Thai | `th` |
| Vietnamese | `vi` |
| Indonesian | `id` |
| Malay | `ms` |
| Filipino | `fil` |
| Burmese | `my` |
| Khmer | `km` |
| Lao | `lo` |
| Chinese (Simplified text) | `zh` |
| Japanese | `ja` |
| Korean | `ko` |
| Hindi | `hi` |
| Bengali | `bn` |
| Arabic | `ar` |
| Spanish | `es` |
| Portuguese | `pt` |
| French | `fr` |
| German | `de` |
| Russian | `ru` |

The single `zh` option uses today's Simplified Chinese package text. Existing
consumer catalog keys and configuration values using `zh-Hans` must change to
`zh` when updating to this Gicho revision. Traditional Chinese is not in
the current 20-language set; it would need its own future contract and catalog.

Gicho translates only its own controls. An application supplies and verifies
its own text before enabling a locale, including authentication and business
copy. No companion localization package or repository is required.
