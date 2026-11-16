/// An immutable resolved feature configuration.
class ConfigurationDocument {
  ConfigurationDocument(Map<String, dynamic> values)
    : _values = _freezeMap(values);

  final Map<String, dynamic> _values;

  Map<String, dynamic> get values => _copyMap(_values);

  Object? value(String path) {
    Object? current = _values;
    for (final segment in path.split('.')) {
      if (current is! Map<String, dynamic> || !current.containsKey(segment)) {
        return null;
      }
      current = current[segment];
    }
    return _copyValue(current);
  }

  T require<T>(String path) {
    final result = value(path);
    if (result is! T) {
      throw StateError('Configuration value "$path" is not a $T.');
    }
    return result;
  }
}

Map<String, dynamic> _copyMap(Map<String, dynamic> value) =>
    value.map((key, item) => MapEntry(key, _copyValue(item)));

Object? _copyValue(Object? value) {
  if (value is Map<String, dynamic>) return _copyMap(value);
  if (value is List) return value.map(_copyValue).toList();
  return value;
}

Map<String, dynamic> _freezeMap(Map<String, dynamic> value) => Map.unmodifiable(
  value.map((key, item) => MapEntry(key, _freezeValue(item))),
);

Object? _freezeValue(Object? value) {
  if (value is Map<String, dynamic>) return _freezeMap(value);
  if (value is List) return List.unmodifiable(value.map(_freezeValue));
  return value;
}
