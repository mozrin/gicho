# Bundled localization

GichoLocaleController bundles 20 registered locale catalogs in lib/src/i18n.
A consumer chooses enabledLocales and initialLocale and supplies appCatalogs.
English must remain enabled and provides fallback. Application catalog values
for the same fully qualified key override package copy. The language picker
only exposes the application's enabled subset. Arabic uses Flutter directionality.

Catalog editing is repository-local: edit the locale's Dart map, preserving key
names and named interpolation placeholders, then run the locale-controller tests.
There is no remote first-party catalog fetch, separate localization package,
code-generation service or companion repository in the supported workflow.
Historical JSON catalogs under legacy/ are design references only.

Validate with `flutter test lib/src/features/localization` and the full package
suite. New applications follow the root AGENTS.md localization policy; existing
examples retain their explicit enabled subsets.
