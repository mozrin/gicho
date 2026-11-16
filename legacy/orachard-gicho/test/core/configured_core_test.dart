import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the bundled core defaults and schema', () async {
    final core = MoztopiaCore();

    final configuration = await core.initialize();

    expect(
      configuration.isFeatureEnabled(GichoAppBarFeature.brightnessToggle),
      isFalse,
    );
    expect(
      configuration.isFeatureEnabled(GichoAppBarFeature.themeSelector),
      isFalse,
    );
    expect(
      configuration.isFeatureEnabled(GichoAppBarFeature.languageSelector),
      isFalse,
    );
    expect(
      configuration.isFeatureEnabled(
        GichoAppBarFeature.configurationDisplay,
      ),
      isFalse,
    );
    expect(
      configuration.isFeatureEnabled(GichoAppBarFeature.logout),
      isFalse,
    );
  });

  test('application configuration can enable an action', () async {
    final configuration = await _configuration(
      appConfig: '''
appBar:
  actions:
    language:
      enabled: true
''',
    );

    expect(
      configuration.isFeatureEnabled(GichoAppBarFeature.brightnessToggle),
      isFalse,
    );
    expect(
      configuration.isFeatureEnabled(GichoAppBarFeature.languageSelector),
      isTrue,
    );
  });

  test('core schema rejects page-placement configuration', () async {
    expect(
      () => _configuration(
        appConfig: '''
appBar:
  actions:
    theme:
      enabled: false
      pages: [settings]
''',
      ),
      throwsA(isA<ConfigurationException>()),
    );
  });
}

const _packageConfig = '''
appBar:
  actions:
    brightness:
      enabled: false
    theme:
      enabled: false
    language:
      enabled: false
    configDisplay:
      enabled: false
    logout:
      enabled: false
''';

const _schema = r'''
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "appBar": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "actions": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "brightness": {"$ref": "#/$defs/action"},
            "theme": {"$ref": "#/$defs/action"},
            "language": {"$ref": "#/$defs/action"},
            "configDisplay": {"$ref": "#/$defs/action"},
            "logout": {"$ref": "#/$defs/action"}
          }
        }
      }
    }
  },
  "$defs": {
    "action": {
      "type": "object",
      "additionalProperties": false,
      "properties": {"enabled": {"type": "boolean"}},
      "required": ["enabled"]
    }
  }
}
''';

Future<GichoCoreConfiguration> _configuration({String? appConfig}) async {
  final assets = {
    ConfigurationService.packageConfigAsset('core'): _packageConfig,
    ConfigurationService.packageSchemaAsset('core'): _schema,
    ConfigurationService.appConfigAsset('core'): ?appConfig,
  };
  final loader = _CoreLoader(assets);
  final document = await ConfigurationService(
    loader: loader,
  ).loadFeature('core');
  return GichoCoreConfiguration.fromDocument(document);
}

class _CoreLoader implements ConfigurationAssetLoader {
  const _CoreLoader(this.assets);

  final Map<String, String> assets;

  @override
  Future<String?> load(String asset, {bool optional = false}) async {
    final value = assets[asset];
    if (value != null || optional) return value;
    throw ConfigurationException('Asset not found.', location: asset);
  }
}
