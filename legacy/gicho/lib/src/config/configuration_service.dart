import 'dart:convert';

import 'configuration_asset_loader.dart';
import 'configuration_document.dart';
import 'configuration_exception.dart';
import 'configuration_merger.dart';
import 'configuration_json_schema_validator.dart';
import 'configuration_yaml_loader.dart';

/// Loads, validates, and merges package defaults with app overrides.
class ConfigurationService {
  const ConfigurationService({
    required this.loader,
    this.yamlLoader = const ConfigurationYamlLoader(),
    this.validator = const JsonSchemaConfigurationValidator(),
  });

  final ConfigurationAssetLoader loader;
  final ConfigurationYamlLoader yamlLoader;
  final JsonSchemaConfigurationValidator validator;

  static const supportedFeatures = [
    'logging',
    'localization',
    'theme',
    'core',
    'startup',
  ];

  static String packageConfigAsset(String feature) =>
      'packages/moztopia/lib/src/$feature/$feature.config.yaml';

  static String packageSchemaAsset(String feature) =>
      'packages/moztopia/lib/src/$feature/$feature.config.schema.json';

  static String appConfigAsset(String feature) =>
      'assets/gicho/$feature.config.yaml';

  Future<ConfigurationDocument> loadFeature(String feature) async {
    final packageLocation = packageConfigAsset(feature);
    final schemaLocation = packageSchemaAsset(feature);
    final appLocation = appConfigAsset(feature);

    final sources = await Future.wait([
      loader.load(packageLocation),
      loader.load(schemaLocation),
      loader.load(appLocation, optional: true),
    ]);

    final packageValues = yamlLoader.load(
      sources[0]!,
      location: packageLocation,
    );
    final schema = _decodeSchema(sources[1]!, schemaLocation);
    final appValues = sources[2] == null
        ? <String, dynamic>{}
        : yamlLoader.load(sources[2]!, location: appLocation);

    validator.validate(packageValues, schema, location: packageLocation);
    validator.validate(appValues, schema, location: appLocation);

    return ConfigurationDocument(
      ConfigurationMerger(schema).merge(packageValues, appValues),
    );
  }

  Map<String, dynamic> _decodeSchema(String source, String location) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('The schema root must be an object.');
      }
      return decoded;
    } catch (error) {
      throw ConfigurationException('$error', location: location);
    }
  }
}
