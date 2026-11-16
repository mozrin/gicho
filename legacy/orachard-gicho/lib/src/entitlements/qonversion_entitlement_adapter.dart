import 'package:flutter/foundation.dart';
import 'package:qonversion_flutter/qonversion_flutter.dart';

import 'entitlement_adapter.dart';
import 'entitlement_configuration.dart';
import 'entitlement_models.dart';

/// Qonversion implementation hidden behind Gicho's provider-neutral seam.
final class QonversionEntitlementAdapter implements GichoEntitlementAdapter {
  QonversionEntitlementAdapter({
    GichoStorePlatform? platform,
    DateTime Function()? now,
  }) : _platform = platform ?? detectGichoStorePlatform(),
       _now = now ?? DateTime.now;

  final GichoStorePlatform _platform;
  final DateTime Function() _now;
  Qonversion? _client;
  GichoEntitlementConfiguration? _configuration;
  Map<String, QProduct> _products = const {};

  @override
  GichoStorePlatform get platform => _platform;

  @override
  bool get supported => _platform != GichoStorePlatform.unsupported;

  Qonversion get _requiredClient =>
      _client ??
      (throw const GichoEntitlementException(
        GichoEntitlementFailure.missingConfiguration,
        diagnosticCode: 'provider_not_initialized',
      ));

  GichoEntitlementConfiguration get _requiredConfiguration =>
      _configuration ??
      (throw const GichoEntitlementException(
        GichoEntitlementFailure.missingConfiguration,
        diagnosticCode: 'configuration_not_initialized',
      ));

  @override
  Stream<GichoEntitlementSnapshot> get entitlementUpdates => _requiredClient
      .updatedEntitlementsStream
      .map((values) => _snapshot(values));

  @override
  Stream<GichoEntitlementPurchaseResult> get purchaseUpdates =>
      _requiredClient.deferredPurchaseStream.map(_purchaseResult);

  @override
  Future<void> initialize(
    GichoEntitlementConfiguration configuration,
  ) async {
    if (!supported) {
      throw const GichoEntitlementException(
        GichoEntitlementFailure.unsupportedPlatform,
        diagnosticCode: 'platform_unsupported',
      );
    }
    final projectKey = configuration.provider.projectKeyFor(platform).trim();
    if (projectKey.isEmpty) {
      throw const GichoEntitlementException(
        GichoEntitlementFailure.missingConfiguration,
        diagnosticCode: 'project_key_missing',
      );
    }
    _configuration = configuration;
    final provider = configuration.provider;
    final builder = QonversionConfigBuilder(
      projectKey,
      switch (provider.launchMode) {
        GichoEntitlementLaunchMode.subscriptionManagement =>
          QLaunchMode.subscriptionManagement,
        GichoEntitlementLaunchMode.analytics => QLaunchMode.analytics,
      },
    );
    builder.setEnvironment(
      provider.environment == GichoEntitlementEnvironment.sandbox
          ? QEnvironment.sandbox
          : QEnvironment.production,
    );
    builder.setEntitlementsCacheLifetime(
      QEntitlementsCacheLifetime.values.byName(provider.cacheLifetime.name),
    );
    _client = Qonversion.initialize(builder.build());
  }

  @override
  Future<void> identify(String userId) async {
    try {
      await _requiredClient.identify(userId);
    } on Object catch (error) {
      throw _exceptionFor(error, fallback: GichoEntitlementFailure.identity);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _requiredClient.logout();
    } on Object catch (error) {
      throw _exceptionFor(error, fallback: GichoEntitlementFailure.identity);
    }
  }

  @override
  Future<List<GichoStoreProduct>> loadProducts() async {
    try {
      _products = Map.unmodifiable(await _requiredClient.products());
      return [
        for (final mapping in _requiredConfiguration.products)
          if (_products[mapping.providerProductId] case final product?)
            _product(mapping, product),
      ];
    } on Object catch (error) {
      throw _exceptionFor(
        error,
        fallback: GichoEntitlementFailure.storeUnavailable,
      );
    }
  }

  @override
  Future<GichoEntitlementSnapshot> checkEntitlements() async {
    try {
      return _snapshot(await _requiredClient.checkEntitlements());
    } on Object catch (error) {
      throw _exceptionFor(error);
    }
  }

  @override
  Future<GichoEntitlementPurchaseResult> purchase(String productId) async {
    final mapping = _requiredConfiguration.mappingForProduct(productId);
    if (mapping == null) {
      return const GichoEntitlementPurchaseResult(
        status: GichoEntitlementPurchaseStatus.failed,
        failure: GichoEntitlementFailure.productUnavailable,
      );
    }
    var product = _products[mapping.providerProductId];
    if (product == null) {
      await loadProducts();
      product = _products[mapping.providerProductId];
    }
    if (product == null) {
      return const GichoEntitlementPurchaseResult(
        status: GichoEntitlementPurchaseStatus.failed,
        failure: GichoEntitlementFailure.productUnavailable,
      );
    }

    try {
      return _purchaseResult(await _requiredClient.purchaseWithResult(product));
    } on Object catch (error) {
      final exception = _exceptionFor(error);
      return GichoEntitlementPurchaseResult(
        status: GichoEntitlementPurchaseStatus.failed,
        failure: exception.failure,
      );
    }
  }

  @override
  Future<GichoEntitlementSnapshot> restore() async {
    try {
      return _snapshot(await _requiredClient.restore());
    } on Object catch (error) {
      throw _exceptionFor(error);
    }
  }

  GichoStoreProduct _product(
    GichoEntitlementProductMapping mapping,
    QProduct product,
  ) => GichoStoreProduct(
    id: mapping.id,
    offeringId: mapping.offeringId,
    entitlementId: mapping.entitlementId,
    type: switch (product.type) {
      QProductType.subscription ||
      QProductType.trial ||
      QProductType.intro => GichoStoreProductType.subscription,
      QProductType.inApp => GichoStoreProductType.oneTime,
      QProductType.unknown => GichoStoreProductType.unknown,
    },
    storeId: product.storeId,
    title: product.storeTitle,
    description: product.storeDescription,
    displayPrice: product.prettyPrice,
    price: product.price,
    currencyCode: product.currencyCode,
    subscriptionPeriod: product.subscriptionPeriod?.iso,
  );

  GichoEntitlementSnapshot _snapshot(
    Map<String, QEntitlement> providerEntitlements,
  ) {
    final resolved = <String, GichoEntitlement>{};
    for (final mapping in _requiredConfiguration.products) {
      final value = providerEntitlements[mapping.providerEntitlementId];
      if (value == null) continue;
      resolved[mapping.entitlementId] = GichoEntitlement(
        id: mapping.entitlementId,
        productId: mapping.id,
        active: value.isActive,
        willRenew: value.renewState == QEntitlementRenewState.willRenew,
        billingIssue: value.renewState == QEntitlementRenewState.billingIssue,
        startedAt: value.startedDate?.toUtc(),
        expiresAt: value.expirationDate?.toUtc(),
      );
    }
    return GichoEntitlementSnapshot(
      entitlements: Map.unmodifiable(resolved),
      refreshedAt: _now().toUtc(),
    );
  }

  GichoEntitlementPurchaseResult _purchaseResult(QPurchaseResult result) {
    final snapshot = result.entitlements == null
        ? null
        : _snapshot(result.entitlements!);
    return switch (result.status) {
      QPurchaseResultStatus.success => GichoEntitlementPurchaseResult(
        status: GichoEntitlementPurchaseStatus.purchased,
        snapshot: snapshot,
      ),
      QPurchaseResultStatus.userCanceled =>
        const GichoEntitlementPurchaseResult(
          status: GichoEntitlementPurchaseStatus.cancelled,
        ),
      QPurchaseResultStatus.pending => GichoEntitlementPurchaseResult(
        status: GichoEntitlementPurchaseStatus.pending,
        snapshot: snapshot,
      ),
      QPurchaseResultStatus.error => GichoEntitlementPurchaseResult(
        status: GichoEntitlementPurchaseStatus.failed,
        snapshot: snapshot,
        failure: _failureForCode(result.error?.code),
      ),
    };
  }

  GichoEntitlementException _exceptionFor(
    Object error, {
    GichoEntitlementFailure fallback = GichoEntitlementFailure.provider,
  }) {
    if (error is GichoEntitlementException) return error;
    if (error is QonversionException) {
      return GichoEntitlementException(
        _failureForCodeName(error.code, fallback: fallback),
        diagnosticCode: error.code,
      );
    }
    if (error is QPurchaseException) {
      return GichoEntitlementException(
        _failureForCodeName(error.code, fallback: fallback),
        diagnosticCode: error.code,
      );
    }
    return GichoEntitlementException(
      fallback,
      diagnosticCode: error.runtimeType.toString(),
    );
  }

  GichoEntitlementFailure _failureForCode(
    QErrorCode? code,
  ) => switch (code) {
    QErrorCode.networkConnectionFailed ||
    QErrorCode.cloudServiceNetworkConnectionFailed ||
    QErrorCode.failedToReceiveData => GichoEntitlementFailure.offline,
    QErrorCode.billingUnavailable ||
    QErrorCode.appleStoreError ||
    QErrorCode.playStoreError => GichoEntitlementFailure.storeUnavailable,
    QErrorCode.productNotFound ||
    QErrorCode.storeProductNotAvailable ||
    QErrorCode.offeringsNotFound ||
    QErrorCode.offeringsNotAvailable =>
      GichoEntitlementFailure.productUnavailable,
    QErrorCode.paymentNotAllowed =>
      GichoEntitlementFailure.purchaseNotAllowed,
    QErrorCode.invalidClientUid => GichoEntitlementFailure.identity,
    QErrorCode.invalidCredentials ||
    QErrorCode.invalidStoreCredentials ||
    QErrorCode.projectConfigError ||
    QErrorCode.launchError => GichoEntitlementFailure.missingConfiguration,
    QErrorCode.unknownClientPlatform || QErrorCode.featureNotSupported =>
      GichoEntitlementFailure.unsupportedPlatform,
    _ => GichoEntitlementFailure.provider,
  };

  GichoEntitlementFailure _failureForCodeName(
    String code, {
    required GichoEntitlementFailure fallback,
  }) {
    for (final value in QErrorCode.values) {
      if (value.code == code) return _failureForCode(value);
    }
    return fallback;
  }

  @override
  void dispose() {
    _products = const {};
    _configuration = null;
    _client = null;
  }
}

GichoStorePlatform detectGichoStorePlatform() {
  if (kIsWeb) return GichoStorePlatform.unsupported;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => GichoStorePlatform.android,
    TargetPlatform.iOS => GichoStorePlatform.ios,
    TargetPlatform.macOS => GichoStorePlatform.macos,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => GichoStorePlatform.unsupported,
  };
}
