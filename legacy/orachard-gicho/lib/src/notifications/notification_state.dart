import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config/configuration_document.dart';
import '../config/configuration_registry.dart';
import '../logging/configured_logging.dart';

enum GichoNotificationChannel { inApp, push, email }

enum GichoNotificationIcon {
  notification,
  favorite,
  star,
  message,
  shield,
  account,
  campaign,
}

final class GichoNotificationChannelConfiguration {
  const GichoNotificationChannelConfiguration({required this.enabled});

  final bool enabled;
}

final class GichoNotificationCatalogEntry {
  const GichoNotificationCatalogEntry({
    required this.type,
    required this.category,
    required this.icon,
    required this.titleKey,
    required this.detailKey,
    required this.channels,
    this.action,
    this.unavailableDetailKey,
    this.packageOwned = false,
  });

  final String type;
  final String category;
  final String? action;
  final GichoNotificationIcon icon;
  final String titleKey;
  final String detailKey;
  final String? unavailableDetailKey;
  final Set<GichoNotificationChannel> channels;
  final bool packageOwned;
}

final class GichoNotificationCopyConfiguration {
  const GichoNotificationCopyConfiguration({
    required this.titleKey,
    required this.openKey,
    required this.headingKey,
    required this.introductionKey,
    required this.markAllReadKey,
    required this.emptyKey,
    required this.emptyDetailKey,
    required this.unreadSemanticsKey,
    required this.readSemanticsKey,
    required this.loadFailedKey,
    required this.loadFailedDetailKey,
    required this.retryKey,
    required this.saveFailedKey,
    required this.loadMoreKey,
    required this.loadMoreFailedKey,
  });

  final String titleKey;
  final String openKey;
  final String headingKey;
  final String introductionKey;
  final String markAllReadKey;
  final String emptyKey;
  final String emptyDetailKey;
  final String unreadSemanticsKey;
  final String readSemanticsKey;
  final String loadFailedKey;
  final String loadFailedDetailKey;
  final String retryKey;
  final String saveFailedKey;
  final String loadMoreKey;
  final String loadMoreFailedKey;
}

/// Validated, provider-neutral settings from `notifications.config.yaml`.
final class GichoNotificationsConfiguration {
  const GichoNotificationsConfiguration({
    required this.channels,
    required this.pageSize,
    required this.copy,
    required this.catalog,
  });

  factory GichoNotificationsConfiguration.fromDocument(
    ConfigurationDocument document,
  ) {
    final channelValues = document.require<Map<String, dynamic>>('channels');
    final channels =
        <GichoNotificationChannel, GichoNotificationChannelConfiguration>{
          for (final channel in GichoNotificationChannel.values)
            channel: GichoNotificationChannelConfiguration(
              enabled:
                  ((channelValues[channel.name]! as Map)
                          .cast<String, dynamic>())['enabled']!
                      as bool,
            ),
        };
    final catalog = <GichoNotificationCatalogEntry>[
      ..._parseCatalog(document, 'coreCatalog', packageOwned: true),
      ..._parseCatalog(document, 'catalog', packageOwned: false),
    ];
    final seenTypes = <String>{};
    for (final entry in catalog) {
      if (!seenTypes.add(entry.type)) {
        throw StateError(
          'Notification type "${entry.type}" is defined more than once.',
        );
      }
    }

    return GichoNotificationsConfiguration(
      channels: Map.unmodifiable(channels),
      pageSize: document.require<int>('presentation.pageSize'),
      copy: GichoNotificationCopyConfiguration(
        titleKey: document.require<String>('copy.title'),
        openKey: document.require<String>('copy.open'),
        headingKey: document.require<String>('copy.heading'),
        introductionKey: document.require<String>('copy.introduction'),
        markAllReadKey: document.require<String>('copy.markAllRead'),
        emptyKey: document.require<String>('copy.empty'),
        emptyDetailKey: document.require<String>('copy.emptyDetail'),
        unreadSemanticsKey: document.require<String>('copy.unreadSemantics'),
        readSemanticsKey: document.require<String>('copy.readSemantics'),
        loadFailedKey: document.require<String>('copy.loadFailed'),
        loadFailedDetailKey: document.require<String>('copy.loadFailedDetail'),
        retryKey: document.require<String>('copy.retry'),
        saveFailedKey: document.require<String>('copy.saveFailed'),
        loadMoreKey: document.require<String>('copy.loadMore'),
        loadMoreFailedKey: document.require<String>('copy.loadMoreFailed'),
      ),
      catalog: List.unmodifiable(catalog),
    );
  }

  final Map<
    GichoNotificationChannel,
    GichoNotificationChannelConfiguration
  >
  channels;
  final int pageSize;
  final GichoNotificationCopyConfiguration copy;
  final List<GichoNotificationCatalogEntry> catalog;

  bool isChannelEnabled(GichoNotificationChannel channel) =>
      channels[channel]?.enabled ?? false;

  GichoNotificationCatalogEntry? entryFor(String type) {
    for (final entry in catalog) {
      if (entry.type == type) return entry;
    }
    return null;
  }

  static List<GichoNotificationCatalogEntry> _parseCatalog(
    ConfigurationDocument document,
    String path, {
    required bool packageOwned,
  }) => [
    for (final raw in document.require<List<dynamic>>(path))
      _parseEntry(
        (raw as Map).cast<String, dynamic>(),
        packageOwned: packageOwned,
      ),
  ];

  static GichoNotificationCatalogEntry _parseEntry(
    Map<String, dynamic> values, {
    required bool packageOwned,
  }) => GichoNotificationCatalogEntry(
    type: values['type']! as String,
    category: values['category']! as String,
    action: values['action'] as String?,
    icon: GichoNotificationIcon.values.byName(values['icon']! as String),
    titleKey: values['title']! as String,
    detailKey: values['detail']! as String,
    unavailableDetailKey: values['unavailableDetail'] as String?,
    channels: Set.unmodifiable(
      (values['channels']! as List<dynamic>).map(
        (value) => GichoNotificationChannel.values.byName(value as String),
      ),
    ),
    packageOwned: packageOwned,
  );
}

final class MoztopiaNotifications {
  MoztopiaNotifications({ConfigurationRegistry? configurationRegistry})
    : _configurationRegistry = configurationRegistry ?? moztopiaConfig;

  final ConfigurationRegistry _configurationRegistry;
  Future<GichoNotificationsConfiguration>? _initialization;
  GichoNotificationsConfiguration? _configuration;

  Future<GichoNotificationsConfiguration> initialize() =>
      _initialization ??= _load();

  GichoNotificationsConfiguration get configuration =>
      _configuration ??
      (throw StateError('Gicho notifications have not been initialized.'));

  Future<GichoNotificationsConfiguration> _load() async {
    final configuration = GichoNotificationsConfiguration.fromDocument(
      await _configurationRegistry.loadFeature('notifications'),
    );
    _configuration = configuration;
    return configuration;
  }
}

final moztopiaNotifications = MoztopiaNotifications();

final class GichoNotificationActionData {
  const GichoNotificationActionData({
    required this.type,
    required this.resourceId,
  });

  final String type;
  final String resourceId;
}

final class GichoNotificationRecord {
  const GichoNotificationRecord({
    required this.id,
    required this.type,
    required this.category,
    required this.createdAt,
    this.action,
    this.readAt,
  });

  final String id;
  final String type;
  final String category;
  final GichoNotificationActionData? action;
  final DateTime? readAt;
  final DateTime createdAt;

  GichoNotificationRecord withReadAt(DateTime value) =>
      GichoNotificationRecord(
        id: id,
        type: type,
        category: category,
        action: action,
        readAt: value,
        createdAt: createdAt,
      );
}

final class GichoNotificationPage {
  const GichoNotificationPage({
    required this.items,
    required this.unreadCount,
    required this.hasMore,
    required this.supportedTypes,
    this.nextCursor,
  });

  final List<GichoNotificationRecord> items;
  final int unreadCount;
  final bool hasMore;
  final Set<String> supportedTypes;
  final String? nextCursor;
}

final class GichoNotificationsReadReceipt {
  const GichoNotificationsReadReceipt({
    required this.readCount,
    required this.readAt,
  });

  final int readCount;
  final DateTime readAt;
}

/// Consumer-owned backend and routing seam for the reusable feature.
abstract interface class GichoNotificationDelegate {
  Future<GichoNotificationPage> listNotifications({
    String? cursor,
    required int limit,
  });

  Future<DateTime> markNotificationRead(String notificationId);

  Future<GichoNotificationsReadReceipt> markAllNotificationsRead();

  Future<void> openNotification(
    BuildContext context,
    GichoNotificationRecord notification,
  );
}

enum GichoNotificationFeedPhase { idle, loading, ready, failed }

enum GichoNotificationMutationResult { saved, failed, ignored }

final class GichoNotificationFeedState {
  const GichoNotificationFeedState({
    this.phase = GichoNotificationFeedPhase.idle,
    this.items = const [],
    this.unreadCount = 0,
    this.hasMore = false,
    this.nextCursor,
    this.loadingMore = false,
    this.mutating = false,
    this.loadMoreFailed = false,
    this.mutationFailed = false,
  });

  final GichoNotificationFeedPhase phase;
  final List<GichoNotificationRecord> items;
  final int unreadCount;
  final bool hasMore;
  final String? nextCursor;
  final bool loadingMore;
  final bool mutating;
  final bool loadMoreFailed;
  final bool mutationFailed;

  GichoNotificationFeedState copyWith({
    GichoNotificationFeedPhase? phase,
    List<GichoNotificationRecord>? items,
    int? unreadCount,
    bool? hasMore,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? loadingMore,
    bool? mutating,
    bool? loadMoreFailed,
    bool? mutationFailed,
  }) => GichoNotificationFeedState(
    phase: phase ?? this.phase,
    items: items ?? this.items,
    unreadCount: unreadCount ?? this.unreadCount,
    hasMore: hasMore ?? this.hasMore,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    mutating: mutating ?? this.mutating,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    mutationFailed: mutationFailed ?? this.mutationFailed,
  );
}

/// Provider-neutral in-app feed lifecycle shared by Gicho applications.
final class GichoNotificationController extends ChangeNotifier {
  GichoNotificationController({
    required this.configuration,
    required this.delegate,
  });

  final GichoNotificationsConfiguration configuration;
  final GichoNotificationDelegate delegate;
  GichoNotificationFeedState _state = const GichoNotificationFeedState();
  Future<void>? _initialLoad;
  bool _disposed = false;

  GichoNotificationFeedState get state => _state;

  Future<void> ensureLoaded() => _initialLoad ??= _loadInitial();

  Future<void> reload() async {
    _initialLoad = _loadInitial();
    await _initialLoad;
  }

  Future<void> _loadInitial() async {
    _setState(
      _state.copyWith(
        phase: GichoNotificationFeedPhase.loading,
        mutationFailed: false,
      ),
    );
    unawaited(
      moztopiaLog.info('[Gicho notifications] Feed load requested.'),
    );
    try {
      final page = await delegate.listNotifications(
        limit: configuration.pageSize,
      );
      _reconcileCapabilities(page.supportedTypes);
      _setState(
        GichoNotificationFeedState(
          phase: GichoNotificationFeedPhase.ready,
          items: _configuredItems(page.items, page.supportedTypes),
          unreadCount: page.unreadCount,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        ),
      );
      unawaited(
        moztopiaLog.info(
          '[Gicho notifications] Feed load completed: '
          '${page.items.length} records; ${page.unreadCount} unread.',
        ),
      );
    } catch (error, stackTrace) {
      _setState(_state.copyWith(phase: GichoNotificationFeedPhase.failed));
      unawaited(
        moztopiaLog.error(
          '[Gicho notifications] Feed load failed.',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final current = _state;
    final cursor = current.nextCursor;
    if (current.phase != GichoNotificationFeedPhase.ready ||
        current.loadingMore ||
        !current.hasMore ||
        cursor == null) {
      return;
    }
    _setState(current.copyWith(loadingMore: true, loadMoreFailed: false));
    unawaited(
      moztopiaLog.debug('[Gicho notifications] Next page requested.'),
    );
    try {
      final page = await delegate.listNotifications(
        cursor: cursor,
        limit: configuration.pageSize,
      );
      _reconcileCapabilities(page.supportedTypes);
      final latest = _state;
      final items = [...latest.items];
      for (final item in _configuredItems(page.items, page.supportedTypes)) {
        if (!items.any((existing) => existing.id == item.id)) items.add(item);
      }
      _setState(
        latest.copyWith(
          items: List.unmodifiable(items),
          unreadCount: page.unreadCount,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          loadingMore: false,
          loadMoreFailed: false,
        ),
      );
      unawaited(
        moztopiaLog.debug(
          '[Gicho notifications] Next page completed: '
          '${page.items.length} records.',
        ),
      );
    } catch (error, stackTrace) {
      _setState(current.copyWith(loadingMore: false, loadMoreFailed: true));
      unawaited(
        moztopiaLog.error(
          '[Gicho notifications] Next page failed.',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<GichoNotificationMutationResult> markRead(String id) async {
    final current = _state;
    if (current.phase != GichoNotificationFeedPhase.ready ||
        current.mutating) {
      return GichoNotificationMutationResult.ignored;
    }
    final index = current.items.indexWhere((item) => item.id == id);
    if (index < 0) return GichoNotificationMutationResult.ignored;
    if (current.items[index].readAt != null) {
      return GichoNotificationMutationResult.saved;
    }

    final optimisticItems = [...current.items];
    optimisticItems[index] = current.items[index].withReadAt(DateTime.now());
    _setState(
      current.copyWith(
        items: List.unmodifiable(optimisticItems),
        unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
        mutating: true,
        mutationFailed: false,
      ),
    );
    unawaited(
      moztopiaLog.debug('[Gicho notifications] Read update requested.'),
    );
    try {
      final readAt = await delegate.markNotificationRead(id);
      final latest = _state;
      _setState(
        latest.copyWith(
          items: List.unmodifiable([
            for (final item in latest.items)
              item.id == id ? item.withReadAt(readAt) : item,
          ]),
          mutating: false,
        ),
      );
      unawaited(
        moztopiaLog.debug('[Gicho notifications] Read update completed.'),
      );
      return GichoNotificationMutationResult.saved;
    } catch (error, stackTrace) {
      _setState(current.copyWith(mutating: false, mutationFailed: true));
      unawaited(
        moztopiaLog.error(
          '[Gicho notifications] Read update failed.',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return GichoNotificationMutationResult.failed;
    }
  }

  Future<GichoNotificationMutationResult> markAllRead() async {
    final current = _state;
    if (current.phase != GichoNotificationFeedPhase.ready ||
        current.mutating ||
        current.unreadCount == 0) {
      return GichoNotificationMutationResult.ignored;
    }
    final optimisticAt = DateTime.now();
    _setState(
      current.copyWith(
        items: List.unmodifiable([
          for (final item in current.items)
            item.readAt == null ? item.withReadAt(optimisticAt) : item,
        ]),
        unreadCount: 0,
        mutating: true,
        mutationFailed: false,
      ),
    );
    unawaited(
      moztopiaLog.debug('[Gicho notifications] Mark-all-read requested.'),
    );
    try {
      final receipt = await delegate.markAllNotificationsRead();
      final latest = _state;
      _setState(
        latest.copyWith(
          items: List.unmodifiable([
            for (final item in latest.items)
              item.readAt == optimisticAt
                  ? item.withReadAt(receipt.readAt)
                  : item,
          ]),
          mutating: false,
        ),
      );
      unawaited(
        moztopiaLog.debug(
          '[Gicho notifications] Mark-all-read completed: '
          '${receipt.readCount} records.',
        ),
      );
      return GichoNotificationMutationResult.saved;
    } catch (error, stackTrace) {
      _setState(current.copyWith(mutating: false, mutationFailed: true));
      unawaited(
        moztopiaLog.error(
          '[Gicho notifications] Mark-all-read failed.',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return GichoNotificationMutationResult.failed;
    }
  }

  void clearMutationFailure() {
    if (!_state.mutationFailed) return;
    _setState(_state.copyWith(mutationFailed: false));
  }

  List<GichoNotificationRecord> _configuredItems(
    List<GichoNotificationRecord> items,
    Set<String> supportedTypes,
  ) {
    final configured = <GichoNotificationRecord>[];
    for (final item in items) {
      if (!supportedTypes.contains(item.type)) {
        unawaited(
          moztopiaLog.warn(
            '[Gicho notifications] Server returned notification type '
            '"${item.type}" outside its capability set and it was not presented.',
          ),
        );
        continue;
      }
      final entry = configuration.entryFor(item.type);
      if (entry == null ||
          !entry.channels.contains(GichoNotificationChannel.inApp)) {
        unawaited(
          moztopiaLog.warn(
            '[Gicho notifications] Server notification type '
            '"${item.type}" is absent from the enabled in-app catalog and '
            'was not presented.',
          ),
        );
        continue;
      }
      if (entry.category != item.category) {
        unawaited(
          moztopiaLog.warn(
            '[Gicho notifications] Server notification type '
            '"${item.type}" used category "${item.category}" instead of '
            'configured category "${entry.category}" and was not presented.',
          ),
        );
        continue;
      }
      configured.add(item);
    }
    return List.unmodifiable(configured);
  }

  void _reconcileCapabilities(Set<String> supportedTypes) {
    for (final entry in configuration.catalog) {
      if (!entry.channels.contains(GichoNotificationChannel.inApp) ||
          supportedTypes.contains(entry.type)) {
        continue;
      }
      unawaited(
        moztopiaLog.warn(
          '[Gicho notifications] Configured in-app notification type '
          '"${entry.type}" is not supported by the server and was disabled.',
        ),
      );
    }
  }

  void _setState(GichoNotificationFeedState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Runtime notification feature available to descendants.
final class GichoNotificationsState {
  const GichoNotificationsState._({
    required this.isAvailable,
    this.configuration,
    this.controller,
    this.delegate,
  });

  const GichoNotificationsState.unavailable() : this._(isAvailable: false);

  const GichoNotificationsState.available({
    required GichoNotificationsConfiguration configuration,
    GichoNotificationController? controller,
    GichoNotificationDelegate? delegate,
  }) : this._(
         isAvailable: true,
         configuration: configuration,
         controller: controller,
         delegate: delegate,
       );

  final bool isAvailable;
  final GichoNotificationsConfiguration? configuration;
  final GichoNotificationController? controller;
  final GichoNotificationDelegate? delegate;

  bool get feedAvailable =>
      isAvailable && controller != null && delegate != null;
}

final class GichoNotificationsScope extends InheritedWidget {
  const GichoNotificationsScope({
    super.key,
    required this.state,
    required super.child,
  });

  final GichoNotificationsState state;

  static GichoNotificationsScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw StateError(
        'Gicho notification state is unavailable. '
        'Wrap this subtree in GichoBootstrap.',
      );
    }
    return scope;
  }

  static GichoNotificationsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GichoNotificationsScope>();

  @override
  bool updateShouldNotify(GichoNotificationsScope oldWidget) =>
      !identical(state, oldWidget.state);
}
