import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled defaults keep Google primary and enabled', () async {
    final configuration = await MoztopiaAuthentication().initialize();

    expect(configuration.providers, hasLength(1));
    expect(configuration.providers.single.slug, 'google');
    expect(
      configuration.providers.single.placement,
      AuthenticationProviderPlacement.primary,
    );
    expect(configuration.providers.single.enabled, isTrue);
  });

  test('application can replace provider placement and state', () async {
    final configuration = await _configuration('''
providers:
  - slug: google
    label: app.auth.google
    placement: primary
    enabled: false
  - slug: github
    label: app.auth.github
    placement: secondary
    enabled: true
''');

    expect(configuration.providers, hasLength(2));
    expect(configuration.providers.first.enabled, isFalse);
    expect(
      configuration.providers.last.placement,
      AuthenticationProviderPlacement.secondary,
    );
  });

  test('schema rejects a provider list without mandatory Google', () async {
    expect(
      () => _configuration('''
providers:
  - slug: github
    label: app.auth.github
    placement: primary
    enabled: true
'''),
      throwsA(isA<ConfigurationException>()),
    );
  });

  test('schema rejects invalid slugs placements and state values', () async {
    for (final appConfig in [
      '''
providers:
  - slug: Google!
    label: app.auth.google
    placement: primary
    enabled: true
''',
      '''
providers:
  - slug: google
    label: app.auth.google
    placement: drawer
    enabled: true
''',
      '''
providers:
  - slug: google
    label: app.auth.google
    placement: primary
    enabled: later
''',
    ]) {
      expect(
        () => _configuration(appConfig),
        throwsA(isA<ConfigurationException>()),
      );
    }
  });
}

Future<AuthenticationConfiguration> _configuration(String appConfig) async {
  final packageConfig = await rootBundle.loadString(
    ConfigurationService.packageConfigAsset('authentication'),
  );
  final schema = await rootBundle.loadString(
    ConfigurationService.packageSchemaAsset('authentication'),
  );
  final registry = ConfigurationRegistry(
    service: ConfigurationService(
      loader: _AuthenticationLoader({
        ConfigurationService.packageConfigAsset('authentication'):
            packageConfig,
        ConfigurationService.packageSchemaAsset('authentication'): schema,
        ConfigurationService.appConfigAsset('authentication'): appConfig,
      }),
    ),
  );
  return MoztopiaAuthentication(configurationRegistry: registry).initialize();
}

final class _AuthenticationLoader implements ConfigurationAssetLoader {
  const _AuthenticationLoader(this.assets);

  final Map<String, String> assets;

  @override
  Future<String?> load(String asset, {bool optional = false}) async {
    final value = assets[asset];
    if (value != null || optional) return value;
    throw ConfigurationException('Asset not found.', location: asset);
  }
}
