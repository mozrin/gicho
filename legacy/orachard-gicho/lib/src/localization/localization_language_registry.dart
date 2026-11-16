import 'package:material_ui/material_ui.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:json_schema/json_schema.dart';

import 'localization_catalog_loader.dart';

/// Package-owned metadata for every language available to Moztopia apps.
final class LocalizationLanguageRegistry {
  const LocalizationLanguageRegistry._(this.languages);

  static const registryAsset =
      'packages/moztopia/lib/src/localization/localization.languages.json';
  static const schemaAsset =
      'packages/moztopia/lib/src/localization/localization.languages.schema.json';

  final List<LocalizationLanguage> languages;

  static Future<LocalizationLanguageRegistry> load({
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final sources = await Future.wait([
      assets.loadString(registryAsset),
      assets.loadString(schemaAsset),
    ]);
    try {
      final values = jsonDecode(sources[0]);
      final schema = jsonDecode(sources[1]);
      final validation = JsonSchema.create(schema).validate(values);
      if (!validation.isValid) {
        throw FormatException(
          validation.errors.map((error) => error.toString()).join('; '),
        );
      }
      return fromMap((values as Map).cast<String, dynamic>());
    } catch (error) {
      throw LocalizationException(
        'Unable to load the package language registry',
        location: registryAsset,
        cause: error,
      );
    }
  }

  static LocalizationLanguageRegistry fromMap(Map<String, dynamic> values) {
    final languages = <LocalizationLanguage>[];
    final registeredCodes = values.keys.toSet();
    for (final entry in values.entries) {
      final metadata = (entry.value as Map).cast<String, dynamic>();
      final iso639 = metadata['iso639'] as String;
      if (iso639 != entry.key) {
        throw LocalizationException(
          'Language registry key "${entry.key}" does not match iso639 '
          '"$iso639".',
          location: registryAsset,
        );
      }
      final names = (metadata['names'] as Map).cast<String, String>();
      final missingNames = registeredCodes.difference(names.keys.toSet());
      final unknownNames = names.keys.toSet().difference(registeredCodes);
      if (missingNames.isNotEmpty || unknownNames.isNotEmpty) {
        throw LocalizationException(
          'Language "$iso639" must provide names for exactly every '
          'registered language. Missing: ${missingNames.join(', ')}; '
          'unknown: ${unknownNames.join(', ')}.',
          location: registryAsset,
        );
      }
      languages.add(
        LocalizationLanguage(
          locale: Locale(iso639),
          label: metadata['label'] as String,
          names: Map.unmodifiable(names),
        ),
      );
    }
    return LocalizationLanguageRegistry._(List.unmodifiable(languages));
  }
}
