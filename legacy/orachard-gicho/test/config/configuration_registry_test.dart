import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  const schema = '''
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "value": {"type": "string"}
  }
}
''';

  test('caches features and exposes a defensive aggregate map', () async {
    final loader = _CountingLoader({
      ConfigurationService.packageConfigAsset('logging'): 'value: log',
      ConfigurationService.packageSchemaAsset('logging'): schema,
      ConfigurationService.packageConfigAsset('localization'): 'value: locale',
      ConfigurationService.packageSchemaAsset('localization'): schema,
    });
    final registry = ConfigurationRegistry(
      service: ConfigurationService(loader: loader),
    );

    await registry.loadFeatures(const ['logging', 'localization']);
    await registry.loadFeature('logging');

    expect(registry.loadedFeatures, containsAll(['logging', 'localization']));
    expect(registry.feature('logging')?.value('value'), 'log');
    expect(registry.values, {
      'logging': {'value': 'log'},
      'localization': {'value': 'locale'},
    });
    expect(loader.loads[ConfigurationService.packageConfigAsset('logging')], 1);

    final values = registry.values;
    (values['logging'] as Map<String, dynamic>)['value'] = 'changed';
    expect(registry.feature('logging')?.value('value'), 'log');
  });
}

class _CountingLoader implements ConfigurationAssetLoader {
  _CountingLoader(this.assets);

  final Map<String, String> assets;
  final Map<String, int> loads = {};

  @override
  Future<String?> load(String asset, {bool optional = false}) async {
    loads.update(asset, (count) => count + 1, ifAbsent: () => 1);
    final value = assets[asset];
    if (value != null || optional) return value;
    throw ConfigurationException('Asset not found.', location: asset);
  }
}
