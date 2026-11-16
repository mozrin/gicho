/// A failure while loading, decoding, validating, or merging configuration.
class ConfigurationException implements Exception {
  const ConfigurationException(this.message, {this.location});

  final String message;
  final String? location;

  @override
  String toString() => location == null
      ? 'ConfigurationException: $message'
      : 'ConfigurationException at $location: $message';
}
