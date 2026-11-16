import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  const packageConfig = '''
colors:
  debug: green
  info: blue
  warn: yellow
  error: red
''';

  const schema = r'''
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "colors": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "debug": {"type": "string", "enum": ["green", "purple"]},
        "info": {"type": "string", "enum": ["blue"], "x-moztopia-locked": true},
        "error": {"type": "string", "enum": ["red"], "x-moztopia-locked": true},
        "warn": {"type": "string", "enum": ["yellow"], "x-moztopia-locked": true}
      }
    }
  }
}
''';

  test('app can override debug while package colors remain locked', () async {
    final loader = _MemoryLoader({
      ConfigurationService.packageConfigAsset('logging'): packageConfig,
      ConfigurationService.packageSchemaAsset('logging'): schema,
      ConfigurationService.appConfigAsset('logging'): '''
colors:
  info: blue
  debug: purple
''',
    });

    final document = await ConfigurationService(
      loader: loader,
    ).loadFeature('logging');

    expect(document.value('colors.info'), 'blue');
    expect(document.value('colors.error'), 'red');
    expect(document.value('colors.warn'), 'yellow');
    expect(document.value('colors.debug'), 'purple');
  });

  test('package defaults are used when app config is absent', () async {
    final loader = _MemoryLoader({
      ConfigurationService.packageConfigAsset('logging'): packageConfig,
      ConfigurationService.packageSchemaAsset('logging'): schema,
    });

    final document = await ConfigurationService(
      loader: loader,
    ).loadFeature('logging');

    expect(document.value('colors.debug'), 'green');
  });

  test('unknown log levels are rejected', () async {
    final loader = _MemoryLoader({
      ConfigurationService.packageConfigAsset('logging'): packageConfig,
      ConfigurationService.packageSchemaAsset('logging'): schema,
      ConfigurationService.appConfigAsset('logging'): '''
colors:
  dog: purple
''',
    });

    expect(
      () => ConfigurationService(loader: loader).loadFeature('logging'),
      throwsA(isA<ConfigurationException>()),
    );
  });

  test('unsupported colors are rejected', () async {
    final loader = _MemoryLoader({
      ConfigurationService.packageConfigAsset('logging'): packageConfig,
      ConfigurationService.packageSchemaAsset('logging'): schema,
      ConfigurationService.appConfigAsset('logging'): '''
colors:
  debug: cat
''',
    });

    expect(
      () => ConfigurationService(loader: loader).loadFeature('logging'),
      throwsA(isA<ConfigurationException>()),
    );
  });

  test('returned configuration values are defensive copies', () async {
    final loader = _MemoryLoader({
      ConfigurationService.packageConfigAsset('logging'): packageConfig,
      ConfigurationService.packageSchemaAsset('logging'): schema,
    });
    final document = await ConfigurationService(
      loader: loader,
    ).loadFeature('logging');

    final values = document.values;
    (values['colors'] as Map<String, dynamic>)['debug'] = 'purple';

    expect(document.value('colors.debug'), 'green');
  });
}

class _MemoryLoader implements ConfigurationAssetLoader {
  const _MemoryLoader(this.assets);

  final Map<String, String> assets;

  @override
  Future<String?> load(String asset, {bool optional = false}) async {
    final value = assets[asset];
    if (value != null || optional) return value;
    throw ConfigurationException('Asset not found.', location: asset);
  }
}
