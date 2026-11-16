import 'entitlement_configuration.dart';

enum GichoEntitlementPhase {
  unavailable,
  initializing,
  ready,
  refreshing,
  purchasing,
  restoring,
  failed,
}

enum GichoEntitlementFailure {
  disabled,
  unsupportedPlatform,
  missingConfiguration,
  offline,
  storeUnavailable,
  productUnavailable,
  purchaseNotAllowed,
  identity,
  provider,
  unknown,
}

enum GichoEntitlementPurchaseStatus { purchased, cancelled, pending, failed }

enum GichoStoreProductType { subscription, oneTime, unknown }

final class GichoStoreProduct {
  const GichoStoreProduct({
    required this.id,
    required this.offeringId,
    required this.entitlementId,
    required this.type,
    this.storeId,
    this.title,
    this.description,
    this.displayPrice,
    this.price,
    this.currencyCode,
    this.subscriptionPeriod,
  });

  final String id;
  final String offeringId;
  final String entitlementId;
  final GichoStoreProductType type;
  final String? storeId;
  final String? title;
  final String? description;
  final String? displayPrice;
  final double? price;
  final String? currencyCode;
  final String? subscriptionPeriod;
}

final class GichoStoreOffering {
  const GichoStoreOffering({required this.id, required this.products});

  final String id;
  final List<GichoStoreProduct> products;
}

final class GichoEntitlement {
  const GichoEntitlement({
    required this.id,
    required this.productId,
    required this.active,
    required this.willRenew,
    required this.billingIssue,
    this.startedAt,
    this.expiresAt,
  });

  final String id;
  final String productId;
  final bool active;
  final bool willRenew;
  final bool billingIssue;
  final DateTime? startedAt;
  final DateTime? expiresAt;
}

final class GichoEntitlementSnapshot {
  const GichoEntitlementSnapshot({
    required this.entitlements,
    required this.refreshedAt,
    this.stale = false,
  });

  final Map<String, GichoEntitlement> entitlements;
  final DateTime refreshedAt;
  final bool stale;

  bool isActive(String id) => entitlements[id]?.active ?? false;

  GichoEntitlementSnapshot withStale(bool value) =>
      GichoEntitlementSnapshot(
        entitlements: entitlements,
        refreshedAt: refreshedAt,
        stale: value,
      );
}

final class GichoEntitlementPurchaseResult {
  const GichoEntitlementPurchaseResult({
    required this.status,
    this.snapshot,
    this.failure,
  });

  final GichoEntitlementPurchaseStatus status;
  final GichoEntitlementSnapshot? snapshot;
  final GichoEntitlementFailure? failure;
}

final class GichoEntitlementState {
  const GichoEntitlementState({
    required this.phase,
    required this.platform,
    this.offerings = const [],
    this.snapshot,
    this.failure,
    this.lastPurchase,
    this.identified = false,
  });

  const GichoEntitlementState.unavailable({
    this.failure = GichoEntitlementFailure.disabled,
    this.platform = GichoStorePlatform.unsupported,
  }) : phase = GichoEntitlementPhase.unavailable,
       offerings = const [],
       snapshot = null,
       lastPurchase = null,
       identified = false;

  final GichoEntitlementPhase phase;
  final GichoStorePlatform platform;
  final List<GichoStoreOffering> offerings;
  final GichoEntitlementSnapshot? snapshot;
  final GichoEntitlementFailure? failure;
  final GichoEntitlementPurchaseResult? lastPurchase;
  final bool identified;

  bool get available => phase != GichoEntitlementPhase.unavailable;
  bool get busy => switch (phase) {
    GichoEntitlementPhase.initializing ||
    GichoEntitlementPhase.refreshing ||
    GichoEntitlementPhase.purchasing ||
    GichoEntitlementPhase.restoring => true,
    _ => false,
  };

  GichoEntitlementState copyWith({
    GichoEntitlementPhase? phase,
    List<GichoStoreOffering>? offerings,
    GichoEntitlementSnapshot? snapshot,
    bool clearSnapshot = false,
    GichoEntitlementFailure? failure,
    bool clearFailure = false,
    GichoEntitlementPurchaseResult? lastPurchase,
    bool clearLastPurchase = false,
    bool? identified,
  }) => GichoEntitlementState(
    phase: phase ?? this.phase,
    platform: platform,
    offerings: offerings ?? this.offerings,
    snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
    failure: clearFailure ? null : (failure ?? this.failure),
    lastPurchase: clearLastPurchase
        ? null
        : (lastPurchase ?? this.lastPurchase),
    identified: identified ?? this.identified,
  );
}

final class GichoEntitlementException implements Exception {
  const GichoEntitlementException(this.failure, {this.diagnosticCode});

  final GichoEntitlementFailure failure;
  final String? diagnosticCode;

  @override
  String toString() =>
      'GichoEntitlementException(${failure.name}, ${diagnosticCode ?? 'none'})';
}
