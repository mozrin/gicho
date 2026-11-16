import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/configured_logging.dart';
import 'entitlement_adapter.dart';
import 'entitlement_configuration.dart';
import 'entitlement_models.dart';

/// Reusable lifecycle controller for provider-backed store entitlements.
final class GichoEntitlementController extends ChangeNotifier {
  factory GichoEntitlementController({
    required GichoEntitlementConfiguration configuration,
    required GichoEntitlementAdapter adapter,
    DateTime Function()? now,
  }) => GichoEntitlementController._(
    configuration: configuration,
    adapter: adapter,
    now: now ?? DateTime.now,
    state: GichoEntitlementState(
      phase: GichoEntitlementPhase.initializing,
      platform: adapter.platform,
    ),
  );

  GichoEntitlementController.unavailable()
    : this._(
        configuration: null,
        adapter: null,
        now: DateTime.now,
        state: const GichoEntitlementState.unavailable(),
      );

  GichoEntitlementController._({
    required this._configuration,
    required this._adapter,
    required this._now,
    required this._state,
  });

  final GichoEntitlementConfiguration? _configuration;
  final GichoEntitlementAdapter? _adapter;
  final DateTime Function() _now;
  GichoEntitlementState _state;
  StreamSubscription<GichoEntitlementSnapshot>? _entitlementSubscription;
  StreamSubscription<GichoEntitlementPurchaseResult>? _purchaseSubscription;
  Timer? _refreshTimer;
  Future<void>? _initialization;
  int _generation = 0;
  bool _disposed = false;

  GichoEntitlementState get state => _state;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    final configuration = _configuration;
    final adapter = _adapter;
    if (configuration == null || adapter == null) return;
    if (!configuration.enabled) {
      _set(
        GichoEntitlementState.unavailable(
          failure: GichoEntitlementFailure.disabled,
          platform: adapter.platform,
        ),
      );
      unawaited(
        moztopiaLog.info(
          '[Gicho entitlements] Initialization skipped: disabled.',
        ),
      );
      return;
    }
    if (!adapter.supported) {
      _set(
        GichoEntitlementState.unavailable(
          failure: GichoEntitlementFailure.unsupportedPlatform,
          platform: adapter.platform,
        ),
      );
      unawaited(
        moztopiaLog.warn(
          '[Gicho entitlements] Store unavailable on this platform.',
        ),
      );
      return;
    }

    final generation = ++_generation;
    _set(
      GichoEntitlementState(
        phase: GichoEntitlementPhase.initializing,
        platform: adapter.platform,
      ),
    );
    unawaited(
      moztopiaLog.info(
        '[Gicho entitlements] Provider initialization started: '
        'adapter=${configuration.provider.adapter.name}; '
        'platform=${adapter.platform.name}.',
      ),
    );
    try {
      await adapter.initialize(configuration);
      if (!_isCurrent(generation)) return;
      _entitlementSubscription = adapter.entitlementUpdates.listen(
        _applyObservedSnapshot,
        onError: _observeError,
      );
      _purchaseSubscription = adapter.purchaseUpdates.listen(
        _applyDeferredPurchase,
        onError: _observeError,
      );
      await _refresh(generation: generation, initializing: true);
      if (!_isCurrent(generation)) return;
      unawaited(
        moztopiaLog.info(
          '[Gicho entitlements] Provider initialization completed.',
        ),
      );
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _applyFailure(error, stackTrace, operation: 'initialize');
    }
  }

  Future<void> refresh() async {
    await initialize();
    final adapter = _adapter;
    if (adapter == null || !state.available || state.busy) return;
    await _refresh(generation: _generation);
  }

  Future<void> _refresh({
    required int generation,
    bool initializing = false,
  }) async {
    final adapter = _adapter!;
    if (!initializing) {
      _set(state.copyWith(phase: GichoEntitlementPhase.refreshing));
    }
    unawaited(
      moztopiaLog.debug(
        '[Gicho entitlements] Products and entitlement refresh started.',
      ),
    );
    try {
      final products = await adapter.loadProducts();
      final snapshot = await adapter.checkEntitlements();
      if (!_isCurrent(generation)) return;
      _set(
        state.copyWith(
          phase: GichoEntitlementPhase.ready,
          offerings: _offerings(products),
          snapshot: snapshot,
          clearFailure: true,
        ),
      );
      unawaited(
        moztopiaLog.debug(
          '[Gicho entitlements] Refresh completed: '
          'offerings=${state.offerings.length}; '
          'entitlements=${snapshot.entitlements.length}.',
        ),
      );
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _applyFailure(error, stackTrace, operation: 'refresh');
    } finally {
      if (_isCurrent(generation)) _scheduleRefresh();
    }
  }

  Future<void> identify(String userId) async {
    await initialize();
    final adapter = _adapter;
    if (adapter == null || !state.available) return;
    final normalized = userId.trim();
    if (normalized.isEmpty || normalized.length > 191) {
      _set(
        state.copyWith(
          phase: GichoEntitlementPhase.failed,
          failure: GichoEntitlementFailure.identity,
        ),
      );
      return;
    }
    final generation = ++_generation;
    _refreshTimer?.cancel();
    _set(
      state.copyWith(
        phase: GichoEntitlementPhase.refreshing,
        clearSnapshot: true,
        clearLastPurchase: true,
        clearFailure: true,
        identified: false,
      ),
    );
    unawaited(
      moztopiaLog.info(
        '[Gicho entitlements] Identified-user transition started; '
        'identifier=redacted.',
      ),
    );
    try {
      await adapter.identify(normalized);
      if (!_isCurrent(generation)) return;
      _set(state.copyWith(identified: true));
      await _refresh(generation: generation);
      if (!_isCurrent(generation)) return;
      unawaited(
        moztopiaLog.info(
          '[Gicho entitlements] Identified-user transition completed.',
        ),
      );
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _applyFailure(error, stackTrace, operation: 'identify');
    }
  }

  Future<void> logout() async {
    await initialize();
    final adapter = _adapter;
    if (adapter == null || !state.available) return;
    final generation = ++_generation;
    _refreshTimer?.cancel();
    _set(
      state.copyWith(
        phase: GichoEntitlementPhase.refreshing,
        clearSnapshot: true,
        clearLastPurchase: true,
        clearFailure: true,
        identified: false,
      ),
    );
    unawaited(moztopiaLog.info('[Gicho entitlements] User logout started.'));
    try {
      await adapter.logout();
      if (!_isCurrent(generation)) return;
      await _refresh(generation: generation);
      if (!_isCurrent(generation)) return;
      unawaited(
        moztopiaLog.info('[Gicho entitlements] User logout completed.'),
      );
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _applyFailure(error, stackTrace, operation: 'logout');
    }
  }

  Future<GichoEntitlementPurchaseResult?> purchase(String productId) async {
    await initialize();
    final adapter = _adapter;
    if (adapter == null || !state.available || state.busy) return null;
    final generation = _generation;
    _set(
      state.copyWith(
        phase: GichoEntitlementPhase.purchasing,
        clearFailure: true,
        clearLastPurchase: true,
      ),
    );
    unawaited(
      moztopiaLog.info(
        '[Gicho entitlements] Purchase started: product=$productId.',
      ),
    );
    try {
      final result = await adapter.purchase(productId);
      if (!_isCurrent(generation)) return null;
      _set(
        state.copyWith(
          phase: GichoEntitlementPhase.ready,
          snapshot: result.snapshot,
          failure: result.failure,
          clearFailure: result.failure == null,
          lastPurchase: result,
        ),
      );
      unawaited(
        moztopiaLog.info(
          '[Gicho entitlements] Purchase completed: '
          'product=$productId; status=${result.status.name}.',
        ),
      );
      _scheduleRefresh();
      return result;
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return null;
      _applyFailure(error, stackTrace, operation: 'purchase');
      return state.lastPurchase;
    }
  }

  Future<void> restore() async {
    await initialize();
    final adapter = _adapter;
    if (adapter == null || !state.available || state.busy) return;
    final generation = _generation;
    _set(
      state.copyWith(
        phase: GichoEntitlementPhase.restoring,
        clearFailure: true,
      ),
    );
    unawaited(
      moztopiaLog.info('[Gicho entitlements] Purchase restore started.'),
    );
    try {
      final snapshot = await adapter.restore();
      if (!_isCurrent(generation)) return;
      _set(
        state.copyWith(
          phase: GichoEntitlementPhase.ready,
          snapshot: snapshot,
          clearFailure: true,
        ),
      );
      unawaited(
        moztopiaLog.info(
          '[Gicho entitlements] Purchase restore completed: '
          'entitlements=${snapshot.entitlements.length}.',
        ),
      );
      _scheduleRefresh();
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _applyFailure(error, stackTrace, operation: 'restore');
    }
  }

  void _applyObservedSnapshot(GichoEntitlementSnapshot snapshot) {
    if (_disposed) return;
    _set(
      state.copyWith(
        phase: GichoEntitlementPhase.ready,
        snapshot: snapshot,
        clearFailure: true,
      ),
    );
    unawaited(
      moztopiaLog.info(
        '[Gicho entitlements] Provider entitlement update observed: '
        'entitlements=${snapshot.entitlements.length}.',
      ),
    );
  }

  void _applyDeferredPurchase(GichoEntitlementPurchaseResult result) {
    if (_disposed) return;
    _set(
      state.copyWith(
        phase: GichoEntitlementPhase.ready,
        snapshot: result.snapshot,
        failure: result.failure,
        clearFailure: result.failure == null,
        lastPurchase: result,
      ),
    );
    unawaited(
      moztopiaLog.info(
        '[Gicho entitlements] Deferred purchase update observed: '
        'status=${result.status.name}.',
      ),
    );
  }

  void _observeError(Object error, StackTrace stackTrace) {
    if (_disposed) return;
    _applyFailure(error, stackTrace, operation: 'observe');
  }

  void _applyFailure(
    Object error,
    StackTrace stackTrace, {
    required String operation,
  }) {
    final typed = error is GichoEntitlementException
        ? error
        : GichoEntitlementException(
            GichoEntitlementFailure.unknown,
            diagnosticCode: error.runtimeType.toString(),
          );
    final snapshot = state.snapshot;
    final stale = snapshot?.withStale(
      _now().toUtc().difference(snapshot.refreshedAt) >=
          _configuration!.staleAfter,
    );
    _set(
      state.copyWith(
        phase: snapshot == null
            ? GichoEntitlementPhase.failed
            : GichoEntitlementPhase.ready,
        snapshot: stale,
        failure: typed.failure,
        lastPurchase: operation == 'purchase'
            ? GichoEntitlementPurchaseResult(
                status: GichoEntitlementPurchaseStatus.failed,
                snapshot: stale,
                failure: typed.failure,
              )
            : null,
      ),
    );
    unawaited(
      moztopiaLog.error(
        '[Gicho entitlements] Operation failed: operation=$operation; '
        'failure=${typed.failure.name}; '
        'diagnostic=${typed.diagnosticCode ?? 'none'}.',
        error: error.runtimeType,
        stackTrace: stackTrace,
      ),
    );
  }

  List<GichoStoreOffering> _offerings(List<GichoStoreProduct> products) {
    final grouped = <String, List<GichoStoreProduct>>{};
    for (final product in products) {
      grouped.putIfAbsent(product.offeringId, () => []).add(product);
    }
    final ids = grouped.keys.toList()..sort();
    return List.unmodifiable([
      for (final id in ids)
        GichoStoreOffering(
          id: id,
          products: List.unmodifiable(grouped[id]!),
        ),
    ]);
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    if (_disposed || !state.available) return;
    _refreshTimer = Timer(
      _configuration!.refreshInterval,
      () => unawaited(refresh()),
    );
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _set(GichoEntitlementState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _refreshTimer?.cancel();
    unawaited(_entitlementSubscription?.cancel());
    unawaited(_purchaseSubscription?.cancel());
    _adapter?.dispose();
    super.dispose();
  }
}
