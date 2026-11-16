import '../config/configuration_document.dart';

/// Standard app-bar features supplied by Gicho.
enum GichoAppBarFeature {
  brightnessToggle('brightness'),
  themeSelector('theme'),
  languageSelector('language'),
  configurationDisplay('configDisplay'),
  logout('logout');

  const GichoAppBarFeature(this.configKey);

  final String configKey;
}

/// Resolved global default for one standard app-bar feature.
final class AppBarFeaturePolicy {
  const AppBarFeaturePolicy({required this.feature, required this.enabled});

  final GichoAppBarFeature feature;
  final bool enabled;
}

/// Package-wide composition settings that do not belong to one feature.
final class GichoCoreConfiguration {
  GichoCoreConfiguration._(this.appBarFeatures);

  factory GichoCoreConfiguration.fromDocument(
    ConfigurationDocument document,
  ) {
    final values = document.require<Map<String, dynamic>>('appBar.actions');
    final features = <GichoAppBarFeature, AppBarFeaturePolicy>{};

    for (final feature in GichoAppBarFeature.values) {
      final action = (values[feature.configKey] as Map).cast<String, dynamic>();
      features[feature] = AppBarFeaturePolicy(
        feature: feature,
        enabled: action['enabled'] as bool,
      );
    }

    return GichoCoreConfiguration._(Map.unmodifiable(features));
  }

  final Map<GichoAppBarFeature, AppBarFeaturePolicy> appBarFeatures;

  AppBarFeaturePolicy? feature(GichoAppBarFeature feature) =>
      appBarFeatures[feature];

  /// Returns the configured global default for [feature].
  bool isFeatureEnabled(GichoAppBarFeature feature) =>
      this.feature(feature)?.enabled ?? true;
}
