import 'package:yaml/yaml.dart';

import 'configuration_exception.dart';

/// Loads a YAML configuration document into ordinary Dart collections.
class ConfigurationYamlLoader {
  const ConfigurationYamlLoader();

  Map<String, dynamic> load(String source, {required String location}) {
    try {
      final decoded = loadYaml(source, sourceUrl: Uri.parse(location));
      if (decoded == null) return <String, dynamic>{};
      final value = _toDartValue(decoded);
      if (value is! Map<String, dynamic>) {
        throw ConfigurationException(
          'The YAML root must be a map.',
          location: location,
        );
      }
      return value;
    } on ConfigurationException {
      rethrow;
    } catch (error) {
      throw ConfigurationException('$error', location: location);
    }
  }
}

Object? _toDartValue(Object? value) {
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw const FormatException('Configuration map keys must be strings.');
      }
      result[key] = _toDartValue(entry.value);
    }
    return result;
  }
  if (value is List) return value.map(_toDartValue).toList();
  return value;
}
