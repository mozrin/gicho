import 'entitlement_configuration.dart';
import 'entitlement_models.dart';

/// Provider-neutral store seam consumed by the Gicho controller.
abstract interface class GichoEntitlementAdapter {
  GichoStorePlatform get platform;

  bool get supported;

  Stream<GichoEntitlementSnapshot> get entitlementUpdates;

  Stream<GichoEntitlementPurchaseResult> get purchaseUpdates;

  Future<void> initialize(GichoEntitlementConfiguration configuration);

  Future<void> identify(String userId);

  Future<void> logout();

  Future<List<GichoStoreProduct>> loadProducts();

  Future<GichoEntitlementSnapshot> checkEntitlements();

  Future<GichoEntitlementPurchaseResult> purchase(String productId);

  Future<GichoEntitlementSnapshot> restore();

  void dispose();
}
