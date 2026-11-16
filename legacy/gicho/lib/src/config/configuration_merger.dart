/// Applies Moztopia merge annotations from a feature's JSON Schema.
class ConfigurationMerger {
  const ConfigurationMerger(this.schema);

  final Map<String, dynamic> schema;

  Map<String, dynamic> merge(
    Map<String, dynamic> packageValues,
    Map<String, dynamic> appValues,
  ) => _mergeMap(packageValues, appValues, schema);

  Map<String, dynamic> _mergeMap(
    Map<String, dynamic> packageValues,
    Map<String, dynamic> appValues,
    Map<String, dynamic> node,
  ) {
    final result = <String, dynamic>{};
    final properties = node['properties'];
    final propertySchemas = properties is Map
        ? properties.cast<String, dynamic>()
        : const <String, dynamic>{};

    for (final key in {...packageValues.keys, ...appValues.keys}) {
      final rawPropertySchema = propertySchemas[key];
      final propertySchema = rawPropertySchema is Map
          ? rawPropertySchema.cast<String, dynamic>()
          : const <String, dynamic>{};
      final packageHasValue = packageValues.containsKey(key);
      final appHasValue = appValues.containsKey(key);

      if (propertySchema['x-moztopia-locked'] == true && packageHasValue) {
        result[key] = _copyValue(packageValues[key]);
        continue;
      }

      final packageValue = packageValues[key];
      final appValue = appValues[key];
      if (packageHasValue &&
          appHasValue &&
          packageValue is Map<String, dynamic> &&
          appValue is Map<String, dynamic>) {
        result[key] = _mergeMap(packageValue, appValue, propertySchema);
      } else if (appHasValue) {
        result[key] = _copyValue(appValue);
      } else {
        result[key] = _copyValue(packageValue);
      }
    }
    return result;
  }
}

Object? _copyValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value.map((key, item) => MapEntry(key, _copyValue(item)));
  }
  if (value is List) return value.map(_copyValue).toList();
  return value;
}
