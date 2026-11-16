import 'configuration_document.dart';
import 'configuration_flutter_asset_loader.dart';
import 'configuration_service.dart';

/// Loads, caches, and aggregates resolved feature configuration in memory.
final class ConfigurationRegistry {
  ConfigurationRegistry({ConfigurationService? service})
    : _service =
          service ??
          const ConfigurationService(loader: FlutterAssetConfigurationLoader());

  final ConfigurationService _service;
  final Map<String, Future<ConfigurationDocument>> _loads = {};
  final Map<String, ConfigurationDocument> _documents = {};

  /// Names of features that have completed configuration loading.
  Iterable<String> get loadedFeatures => _documents.keys;

  /// A defensive aggregate map keyed by feature name.
  Map<String, dynamic> get values => {
    for (final entry in _documents.entries) entry.key: entry.value.values,
  };

  /// Returns a loaded feature document, or null if it has not completed.
  ConfigurationDocument? feature(String feature) => _documents[feature];

  /// Loads a feature once and retains its resolved document in memory.
  Future<ConfigurationDocument> loadFeature(String feature) {
    return _loads.putIfAbsent(feature, () async {
      try {
        final document = await _service.loadFeature(feature);
        _documents[feature] = document;
        return document;
      } catch (_) {
        _loads.remove(feature);
        rethrow;
      }
    });
  }

  /// Loads all requested features and returns the current aggregate map.
  Future<Map<String, dynamic>> loadFeatures(Iterable<String> features) async {
    await Future.wait(features.map(loadFeature));
    return values;
  }
}

/// Shared package configuration retained for application-wide inspection.
final moztopiaConfig = ConfigurationRegistry();
