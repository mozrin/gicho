import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('loads configured themes and builds app-wide ThemeData', () async {
    final registry = ConfigurationRegistry(
      service: ConfigurationService(
        loader: _ThemeLoader({
          ConfigurationService.packageConfigAsset('theme'): '''
level: simple
defaultTheme: ocean
themes:
  ocean:
    name: Ocean
    primary: "#006994"
''',
          ConfigurationService.packageSchemaAsset('theme'): '''
{
  "type": "object",
  "properties": {
    "level": {"type": "string"},
    "defaultTheme": {"type": "string"},
    "themes": {"type": "object"}
  }
}
''',
        }),
      ),
    );
    final controller = MoztopiaThemeController(configurationRegistry: registry);

    await controller.initialize();

    expect(controller.selectedThemeId, 'ocean');
    expect(controller.themes.single.name, 'Ocean');
    expect(controller.lightTheme.brightness, Brightness.light);
    expect(controller.darkTheme.brightness, Brightness.dark);

    controller.selectMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);
  });
}

class _ThemeLoader implements ConfigurationAssetLoader {
  const _ThemeLoader(this.assets);

  final Map<String, String> assets;

  @override
  Future<String?> load(String asset, {bool optional = false}) async {
    final value = assets[asset];
    if (value != null || optional) return value;
    throw ConfigurationException('Asset not found.', location: asset);
  }
}
