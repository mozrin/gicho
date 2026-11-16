import 'package:json_schema/json_schema.dart';

import 'configuration_exception.dart';

/// Validates configuration values with a JSON Schema.
class JsonSchemaConfigurationValidator {
  const JsonSchemaConfigurationValidator();

  void validate(
    Map<String, dynamic> values,
    Map<String, dynamic> schema, {
    required String location,
  }) {
    try {
      final results = JsonSchema.create(schema).validate(values);
      if (!results.isValid) {
        throw ConfigurationException(
          results.errors.map((error) => error.toString()).join('; '),
          location: location,
        );
      }
    } on ConfigurationException {
      rethrow;
    } catch (error) {
      throw ConfigurationException(
        'Unable to validate against the feature schema: $error',
        location: location,
      );
    }
  }
}
