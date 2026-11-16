import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => moztopiaLog.initialize());

  testWidgets('wrapper renders its child while provider initializes', (
    tester,
  ) async {
    final initialization = Completer<void>();
    final adapter = _FakeEntitlementAdapter(
      initializeBlock: initialization.future,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GichoEntitlements(
          configuration: _configuration(),
          adapter: adapter,
          child: const Text('APPLICATION READY'),
        ),
      ),
    );

    expect(find.text('APPLICATION READY'), findsOneWidget);
    expect(adapter.initializeCalls, 1);

    initialization.complete();
    await tester.pump();
  });

  test(
    'initializes in the background and groups configured offerings',
    () async {
      final adapter = _FakeEntitlementAdapter();
      final controller = _controller(adapter);
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.state.phase, GichoEntitlementPhase.ready);
      expect(controller.state.offerings.single.id, 'example.plus');
      expect(controller.state.offerings.single.products.single.id, 'monthly');
      expect(controller.state.snapshot?.isActive('premium'), isTrue);
      expect(adapter.initializeCalls, 1);
    },
  );

  test('identity changes refresh and logout clears account state', () async {
    final adapter = _FakeEntitlementAdapter();
    final controller = _controller(adapter);
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.identify('member-123');
    expect(adapter.identifiedUser, 'member-123');
    expect(controller.state.identified, isTrue);
    expect(adapter.checkCalls, 2);

    await controller.logout();
    expect(adapter.identifiedUser, isNull);
    expect(controller.state.identified, isFalse);
    expect(adapter.checkCalls, 3);
  });

  test('identity transition immediately clears prior account state', () async {
    final transition = Completer<void>();
    final adapter = _FakeEntitlementAdapter(identifyBlock: transition.future);
    final controller = _controller(adapter);
    addTearDown(controller.dispose);
    await controller.initialize();

    final identification = controller.identify('member-456');
    await _flushEvents();
    expect(controller.state.phase, GichoEntitlementPhase.refreshing);
    expect(controller.state.snapshot, isNull);
    expect(controller.state.identified, isFalse);

    transition.complete();
    await identification;
    expect(controller.state.identified, isTrue);
    expect(controller.state.snapshot, isNotNull);
  });

  test('purchase and deferred purchase expose typed outcomes', () async {
    final adapter = _FakeEntitlementAdapter();
    final controller = _controller(adapter);
    addTearDown(controller.dispose);
    await controller.initialize();

    final purchased = await controller.purchase('monthly');
    expect(purchased?.status, GichoEntitlementPurchaseStatus.purchased);
    expect(controller.state.lastPurchase, same(purchased));

    adapter.emitPurchase(
      const GichoEntitlementPurchaseResult(
        status: GichoEntitlementPurchaseStatus.pending,
      ),
    );
    await _flushEvents();
    expect(
      controller.state.lastPurchase?.status,
      GichoEntitlementPurchaseStatus.pending,
    );
  });

  test(
    'restore and observed entitlement updates replace the snapshot',
    () async {
      final adapter = _FakeEntitlementAdapter();
      final controller = _controller(adapter);
      addTearDown(controller.dispose);
      await controller.initialize();

      adapter.snapshot = _snapshot(active: false, minute: 2);
      await controller.restore();
      expect(controller.state.snapshot?.isActive('premium'), isFalse);

      adapter.emitSnapshot(_snapshot(active: true, minute: 3));
      await _flushEvents();
      expect(controller.state.snapshot?.isActive('premium'), isTrue);
      expect(controller.state.snapshot?.refreshedAt.minute, 3);
    },
  );

  test('offline refresh retains and marks an expired snapshot stale', () async {
    var now = DateTime.utc(2026, 1, 1, 0, 1);
    final adapter = _FakeEntitlementAdapter();
    final controller = _controller(adapter, now: () => now);
    addTearDown(controller.dispose);
    await controller.initialize();

    now = DateTime.utc(2026, 1, 1, 0, 10);
    adapter.checkFailure = const GichoEntitlementException(
      GichoEntitlementFailure.offline,
      diagnosticCode: 'network',
    );
    await controller.refresh();

    expect(controller.state.phase, GichoEntitlementPhase.ready);
    expect(controller.state.failure, GichoEntitlementFailure.offline);
    expect(controller.state.snapshot?.stale, isTrue);
    expect(controller.state.snapshot?.isActive('premium'), isTrue);
  });

  test('scheduled refresh runs after the configured delay', () async {
    final adapter = _FakeEntitlementAdapter();
    final controller = _controller(
      adapter,
      refreshInterval: const Duration(milliseconds: 10),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await Future<void>.delayed(const Duration(milliseconds: 35));
    expect(adapter.checkCalls, greaterThan(1));
  });

  test('disabled and unsupported adapters remain unavailable', () async {
    final disabled = _FakeEntitlementAdapter();
    final disabledController = _controller(disabled, enabled: false);
    addTearDown(disabledController.dispose);
    await disabledController.initialize();
    expect(disabledController.state.available, isFalse);
    expect(
      disabledController.state.failure,
      GichoEntitlementFailure.disabled,
    );

    final unsupported = _FakeEntitlementAdapter(supported: false);
    final unsupportedController = _controller(unsupported);
    addTearDown(unsupportedController.dispose);
    await unsupportedController.initialize();
    expect(unsupportedController.state.available, isFalse);
    expect(
      unsupportedController.state.failure,
      GichoEntitlementFailure.unsupportedPlatform,
    );
  });

  test('invalid identity and provider purchase failure are typed', () async {
    final adapter = _FakeEntitlementAdapter();
    final controller = _controller(adapter);
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.identify('   ');
    expect(controller.state.failure, GichoEntitlementFailure.identity);

    adapter.purchaseResult = const GichoEntitlementPurchaseResult(
      status: GichoEntitlementPurchaseStatus.failed,
      failure: GichoEntitlementFailure.purchaseNotAllowed,
    );
    final result = await controller.purchase('monthly');
    expect(result?.failure, GichoEntitlementFailure.purchaseNotAllowed);
  });
}

GichoEntitlementController _controller(
  _FakeEntitlementAdapter adapter, {
  bool enabled = true,
  Duration refreshInterval = const Duration(days: 1),
  DateTime Function()? now,
}) => GichoEntitlementController(
  configuration: _configuration(
    enabled: enabled,
    refreshInterval: refreshInterval,
  ),
  adapter: adapter,
  now: now,
);

GichoEntitlementConfiguration _configuration({
  bool enabled = true,
  Duration refreshInterval = const Duration(days: 1),
}) => GichoEntitlementConfiguration(
  enabled: enabled,
  provider: const GichoEntitlementProviderConfiguration(
    adapter: GichoEntitlementAdapterType.qonversion,
    environment: GichoEntitlementEnvironment.sandbox,
    launchMode: GichoEntitlementLaunchMode.subscriptionManagement,
    cacheLifetime: GichoEntitlementCacheLifetime.month,
    projectKeys: {},
  ),
  refreshInterval: refreshInterval,
  staleAfter: const Duration(minutes: 5),
  products: const [
    GichoEntitlementProductMapping(
      id: 'monthly',
      offeringId: 'example.plus',
      entitlementId: 'premium',
      providerProductId: 'provider.monthly',
      providerEntitlementId: 'provider.premium',
    ),
  ],
);

GichoEntitlementSnapshot _snapshot({required bool active, int minute = 0}) =>
    GichoEntitlementSnapshot(
      entitlements: {
        'premium': GichoEntitlement(
          id: 'premium',
          productId: 'monthly',
          active: active,
          willRenew: active,
          billingIssue: false,
        ),
      },
      refreshedAt: DateTime.utc(2026, 1, 1, 0, minute),
    );

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

final class _FakeEntitlementAdapter implements GichoEntitlementAdapter {
  _FakeEntitlementAdapter({
    this.supported = true,
    this.initializeBlock,
    this.identifyBlock,
  });

  final StreamController<GichoEntitlementSnapshot> _entitlements =
      StreamController.broadcast();
  final StreamController<GichoEntitlementPurchaseResult> _purchases =
      StreamController.broadcast();

  @override
  final bool supported;
  final Future<void>? initializeBlock;
  final Future<void>? identifyBlock;

  @override
  GichoStorePlatform get platform => supported
      ? GichoStorePlatform.android
      : GichoStorePlatform.unsupported;

  int initializeCalls = 0;
  int checkCalls = 0;
  String? identifiedUser;
  Object? checkFailure;
  GichoEntitlementSnapshot snapshot = _snapshot(active: true);
  GichoEntitlementPurchaseResult purchaseResult =
      GichoEntitlementPurchaseResult(
        status: GichoEntitlementPurchaseStatus.purchased,
        snapshot: _snapshot(active: true),
      );

  @override
  Stream<GichoEntitlementSnapshot> get entitlementUpdates =>
      _entitlements.stream;

  @override
  Stream<GichoEntitlementPurchaseResult> get purchaseUpdates =>
      _purchases.stream;

  @override
  Future<void> initialize(
    GichoEntitlementConfiguration configuration,
  ) async {
    initializeCalls++;
    await initializeBlock;
  }

  @override
  Future<void> identify(String userId) async {
    await identifyBlock;
    identifiedUser = userId;
  }

  @override
  Future<void> logout() async => identifiedUser = null;

  @override
  Future<List<GichoStoreProduct>> loadProducts() async => const [
    GichoStoreProduct(
      id: 'monthly',
      offeringId: 'example.plus',
      entitlementId: 'premium',
      type: GichoStoreProductType.subscription,
      displayPrice: r'$4.99',
    ),
  ];

  @override
  Future<GichoEntitlementSnapshot> checkEntitlements() async {
    checkCalls++;
    final failure = checkFailure;
    if (failure != null) throw failure;
    return snapshot;
  }

  @override
  Future<GichoEntitlementPurchaseResult> purchase(String productId) async =>
      purchaseResult;

  @override
  Future<GichoEntitlementSnapshot> restore() async => snapshot;

  void emitSnapshot(GichoEntitlementSnapshot value) =>
      _entitlements.add(value);

  void emitPurchase(GichoEntitlementPurchaseResult value) =>
      _purchases.add(value);

  @override
  void dispose() {
    unawaited(_entitlements.close());
    unawaited(_purchases.close());
  }
}
