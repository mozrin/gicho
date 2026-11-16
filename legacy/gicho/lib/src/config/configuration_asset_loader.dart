/// Loads configuration resources by their Flutter asset key.
abstract interface class ConfigurationAssetLoader {
  Future<String?> load(String asset, {bool optional = false});
}
