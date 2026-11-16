import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'configuration_asset_loader.dart';
import 'configuration_exception.dart';

/// Loads package and application configuration from a Flutter [AssetBundle].
class FlutterAssetConfigurationLoader implements ConfigurationAssetLoader {
  const FlutterAssetConfigurationLoader({this.bundle});

  final AssetBundle? bundle;

  @override
  Future<String?> load(String asset, {bool optional = false}) async {
    final selectedBundle = bundle ?? rootBundle;
    if (optional) {
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(
          selectedBundle,
        );
        if (!manifest.listAssets().contains(asset)) return null;
      } on FlutterError {
        // Some custom bundles do not expose a manifest. Preserve the previous
        // optional-load behavior for those bundles.
      }
    }
    try {
      return await selectedBundle.loadString(asset);
    } on FlutterError catch (error) {
      if (optional) return null;
      throw ConfigurationException(error.message, location: asset);
    }
  }
}
