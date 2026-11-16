import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled defaults keep provider integration inactive', () async {
    final configuration = await MoztopiaEntitlements().initialize();

    expect(configuration.enabled, isFalse);
    expect(
      configuration.provider.adapter,
      GichoEntitlementAdapterType.qonversion,
    );
    expect(configuration.products, isEmpty);
  });

  test('application override supplies client-safe product mappings', () async {
    final configuration = await _configuration('''
enabled: true
provider:
  environment: sandbox
  projectKeys:
    android: android-project-key
products:
  - id: example.plus.monthly
    offeringId: example.plus
    entitlementId: example.plus
    providerProductId: qonversion.monthly
    providerEntitlementId: premium
''');

    expect(configuration.enabled, isTrue);
    expect(
      configuration.provider.environment,
      GichoEntitlementEnvironment.sandbox,
    );
    expect(
      configuration.provider.projectKeyFor(GichoStorePlatform.android),
      'android-project-key',
    );
    expect(
      configuration.mappingForProduct('example.plus.monthly')?.entitlementId,
      'example.plus',
    );
  });

  test('duplicate stable or provider product IDs are rejected', () async {
    for (final duplicateField in ['id', 'providerProductId']) {
      final firstId = 'example.monthly';
      final secondId = duplicateField == 'id' ? firstId : 'example.annual';
      final firstProvider = 'provider.monthly';
      final secondProvider = duplicateField == 'providerProductId'
          ? firstProvider
          : 'provider.annual';
      await expectLater(
        _configuration('''
products:
  - id: $firstId
    offeringId: example
    entitlementId: premium
    providerProductId: $firstProvider
    providerEntitlementId: premium
  - id: $secondId
    offeringId: example
    entitlementId: premium
    providerProductId: $secondProvider
    providerEntitlementId: premium
'''),
        throwsA(isA<StateError>()),
      );
    }
  });

  test('schema rejects unknown configuration', () async {
    await expectLater(
      _configuration('unexpected: true'),
      throwsA(isA<ConfigurationException>()),
    );
  });
}

Future<GichoEntitlementConfiguration> _configuration(
  String appConfig,
) async {
  final packageConfig = await rootBundle.loadString(
    ConfigurationService.packageConfigAsset('entitlements'),
  );
  final schema = await rootBundle.loadString(
    ConfigurationService.packageSchemaAsset('entitlements'),
  );
  final registry = ConfigurationRegistry(
    service: ConfigurationService(
      loader: _EntitlementsLoader({
        ConfigurationService.packageConfigAsset('entitlements'): packageConfig,
        ConfigurationService.packageSchemaAsset('entitlements'): schema,
        ConfigurationService.appConfigAsset('entitlements'): appConfig,
      }),
    ),
  );
  return MoztopiaEntitlements(configurationRegistry: registry).initialize();
}

final class _EntitlementsLoader implements ConfigurationAssetLoader {
  const _EntitlementsLoader(this.assets);

  final Map<String, String> assets;

  @override
  Future<String?> load(String asset, {bool optional = false}) async {
    final value = assets[asset];
    if (value != null || optional) return value;
    throw ConfigurationException('Asset not found.', location: asset);
  }
}
