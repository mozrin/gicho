# Package catalogs

Locale-specific, key-driven Gicho copy lives here. The localization feature
registers the supported locales and reads these catalogs. Consumer-owned copy
belongs in the consumer's catalogs, with exact-key overrides taking precedence.
Native language names shared by the picker live in `locale_names.dart` because
they do not change with the selected UI language. Each locale catalog owns its
language label and navigation text. Missing keys render as their exact key.
