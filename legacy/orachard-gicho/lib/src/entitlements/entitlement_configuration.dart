import '../config/configuration_document.dart';
import '../config/configuration_registry.dart';

enum GichoEntitlementAdapterType { qonversion }

enum GichoEntitlementEnvironment { sandbox, production }

enum GichoEntitlementLaunchMode { subscriptionManagement, analytics }

enum GichoEntitlementCacheLifetime {
  week,
  twoWeeks,
  month,
  twoMonths,
  threeMonths,
  sixMonths,
  year,
  unlimited,
}

enum GichoStorePlatform { android, ios, macos, unsupported }

final class GichoEntitlementProductMapping {
  const GichoEntitlementProductMapping({
    required this.id,
    required this.offeringId,
    required this.entitlementId,
    required this.providerProductId,
    required this.providerEntitlementId,
  });

  final String id;
  final String offeringId;
  final String entitlementId;
  final String providerProductId;
  final String providerEntitlementId;
}

final class GichoEntitlementProviderConfiguration {
  const GichoEntitlementProviderConfiguration({
    required this.adapter,
    required this.environment,
    required this.launchMode,
    required this.cacheLifetime,
    required this.projectKeys,
  });

  final GichoEntitlementAdapterType adapter;
  final GichoEntitlementEnvironment environment;
  final GichoEntitlementLaunchMode launchMode;
  final GichoEntitlementCacheLifetime cacheLifetime;
  final Map<GichoStorePlatform, String> projectKeys;

  String projectKeyFor(GichoStorePlatform platform) =>
      projectKeys[platform] ?? '';
}

final class GichoEntitlementConfiguration {
  const GichoEntitlementConfiguration({
    required this.enabled,
    required this.provider,
    required this.refreshInterval,
    required this.staleAfter,
    required this.products,
  });

  factory GichoEntitlementConfiguration.fromDocument(
    ConfigurationDocument document,
  ) {
    final rawKeys = document.require<Map<String, dynamic>>(
      'provider.projectKeys',
    );
    final products = <GichoEntitlementProductMapping>[];
    final ids = <String>{};
    final providerProductIds = <String>{};
    for (final raw in document.require<List<dynamic>>('products')) {
      final values = (raw as Map).cast<String, dynamic>();
      final id = values['id']! as String;
      final providerProductId = values['providerProductId']! as String;
      if (!ids.add(id)) {
        throw StateError('Store entitlement product "$id" is duplicated.');
      }
      if (!providerProductIds.add(providerProductId)) {
        throw StateError(
          'Provider product "$providerProductId" is mapped more than once.',
        );
      }
      products.add(
        GichoEntitlementProductMapping(
          id: id,
          offeringId: values['offeringId']! as String,
          entitlementId: values['entitlementId']! as String,
          providerProductId: providerProductId,
          providerEntitlementId: values['providerEntitlementId']! as String,
        ),
      );
    }

    return GichoEntitlementConfiguration(
      enabled: document.require<bool>('enabled'),
      provider: GichoEntitlementProviderConfiguration(
        adapter: GichoEntitlementAdapterType.values.byName(
          document.require<String>('provider.adapter'),
        ),
        environment: GichoEntitlementEnvironment.values.byName(
          document.require<String>('provider.environment'),
        ),
        launchMode: GichoEntitlementLaunchMode.values.byName(
          document.require<String>('provider.launchMode'),
        ),
        cacheLifetime: GichoEntitlementCacheLifetime.values.byName(
          document.require<String>('provider.cacheLifetime'),
        ),
        projectKeys: Map.unmodifiable({
          for (final platform in [
            GichoStorePlatform.android,
            GichoStorePlatform.ios,
            GichoStorePlatform.macos,
          ])
            platform: rawKeys[platform.name]! as String,
        }),
      ),
      refreshInterval: Duration(
        minutes: document.require<int>('refresh.intervalMinutes'),
      ),
      staleAfter: Duration(
        minutes: document.require<int>('refresh.staleAfterMinutes'),
      ),
      products: List.unmodifiable(products),
    );
  }

  final bool enabled;
  final GichoEntitlementProviderConfiguration provider;
  final Duration refreshInterval;
  final Duration staleAfter;
  final List<GichoEntitlementProductMapping> products;

  GichoEntitlementProductMapping? mappingForProduct(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }
}

final class MoztopiaEntitlements {
  MoztopiaEntitlements({ConfigurationRegistry? configurationRegistry})
    : _configurationRegistry = configurationRegistry ?? moztopiaConfig;

  final ConfigurationRegistry _configurationRegistry;
  Future<GichoEntitlementConfiguration>? _initialization;

  Future<GichoEntitlementConfiguration> initialize() =>
      _initialization ??= _load();

  Future<GichoEntitlementConfiguration> _load() async =>
      GichoEntitlementConfiguration.fromDocument(
        await _configurationRegistry.loadFeature('entitlements'),
      );
}

final moztopiaEntitlements = MoztopiaEntitlements();
