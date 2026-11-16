import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => moztopiaLog.initialize());

  test('loads, pages, and acknowledges notification read state', () async {
    final delegate = _NotificationDelegate(
      pages: [
        [_notification('first')],
        [_notification('second')],
      ],
    );
    final controller = GichoNotificationController(
      configuration: _configuration,
      delegate: delegate,
    );
    addTearDown(controller.dispose);

    await controller.ensureLoaded();
    expect(controller.state.items.map((item) => item.id), ['first']);
    expect(controller.state.unreadCount, 2);

    await controller.loadMore();
    expect(controller.state.items.map((item) => item.id), ['first', 'second']);

    expect(
      await controller.markRead('first'),
      GichoNotificationMutationResult.saved,
    );
    expect(controller.state.unreadCount, 1);
    expect(controller.state.items.first.readAt, _readAt);

    expect(
      await controller.markAllRead(),
      GichoNotificationMutationResult.saved,
    );
    expect(controller.state.unreadCount, 0);
    expect(delegate.markedRead, ['first']);
    expect(delegate.markAllReadCount, 1);
  });

  test('restores optimistic state and exposes inline failure', () async {
    final delegate = _NotificationDelegate()..markReadFails = true;
    final controller = GichoNotificationController(
      configuration: _configuration,
      delegate: delegate,
    );
    addTearDown(controller.dispose);
    await controller.ensureLoaded();

    expect(
      await controller.markRead('first'),
      GichoNotificationMutationResult.failed,
    );
    expect(controller.state.unreadCount, 1);
    expect(controller.state.items.first.readAt, isNull);
    expect(controller.state.mutationFailed, isTrue);
  });

  test('does not present types absent from the app catalog', () async {
    final delegate = _NotificationDelegate(
      pages: [
        [_notification('unknown', type: 'serverOnly')],
      ],
    );
    final controller = GichoNotificationController(
      configuration: _configuration,
      delegate: delegate,
    );
    addTearDown(controller.dispose);

    await controller.ensureLoaded();

    expect(controller.state.items, isEmpty);
  });

  test(
    'does not present configured types absent from server capabilities',
    () async {
      final delegate = _NotificationDelegate(
        supportedTypes: const {'serverOnly'},
      );
      final controller = GichoNotificationController(
        configuration: _configuration,
        delegate: delegate,
      );
      addTearDown(controller.dispose);

      await controller.ensureLoaded();

      expect(controller.state.items, isEmpty);
    },
  );
}

const _copy = GichoNotificationCopyConfiguration(
  titleKey: 'test.title',
  openKey: 'test.open',
  headingKey: 'test.heading',
  introductionKey: 'test.introduction',
  markAllReadKey: 'test.markAllRead',
  emptyKey: 'test.empty',
  emptyDetailKey: 'test.emptyDetail',
  unreadSemanticsKey: 'test.unread',
  readSemanticsKey: 'test.read',
  loadFailedKey: 'test.loadFailed',
  loadFailedDetailKey: 'test.loadFailedDetail',
  retryKey: 'test.retry',
  saveFailedKey: 'test.saveFailed',
  loadMoreKey: 'test.loadMore',
  loadMoreFailedKey: 'test.loadMoreFailed',
);

const _configuration = GichoNotificationsConfiguration(
  channels: {
    GichoNotificationChannel.inApp: GichoNotificationChannelConfiguration(
      enabled: true,
    ),
    GichoNotificationChannel.push: GichoNotificationChannelConfiguration(
      enabled: false,
    ),
    GichoNotificationChannel.email: GichoNotificationChannelConfiguration(
      enabled: false,
    ),
  },
  pageSize: 20,
  copy: _copy,
  catalog: [
    GichoNotificationCatalogEntry(
      type: 'recordChanged',
      category: 'activity',
      action: 'openRecord',
      icon: GichoNotificationIcon.favorite,
      titleKey: 'test.record.title',
      detailKey: 'test.record.detail',
      unavailableDetailKey: 'test.record.unavailable',
      channels: {GichoNotificationChannel.inApp},
    ),
  ],
);

final _readAt = DateTime.utc(2026, 8, 24, 9);

GichoNotificationRecord _notification(
  String id, {
  String type = 'recordChanged',
}) => GichoNotificationRecord(
  id: id,
  type: type,
  category: 'activity',
  action: const GichoNotificationActionData(
    type: 'openRecord',
    resourceId: 'record-id',
  ),
  createdAt: DateTime.utc(2026, 8, 24, 8),
);

final class _NotificationDelegate implements GichoNotificationDelegate {
  _NotificationDelegate({
    List<List<GichoNotificationRecord>>? pages,
    this.supportedTypes = const {'recordChanged', 'serverOnly'},
  }) : pages =
           pages ??
           [
             [_notification('first')],
           ];

  final List<List<GichoNotificationRecord>> pages;
  final Set<String> supportedTypes;
  bool markReadFails = false;
  final List<String> markedRead = [];
  int markAllReadCount = 0;

  @override
  Future<GichoNotificationPage> listNotifications({
    String? cursor,
    required int limit,
  }) async {
    final index = cursor == null ? 0 : int.parse(cursor);
    final hasMore = index + 1 < pages.length;
    return GichoNotificationPage(
      items: pages[index],
      unreadCount: pages.expand((page) => page).length,
      hasMore: hasMore,
      supportedTypes: supportedTypes,
      nextCursor: hasMore ? '${index + 1}' : null,
    );
  }

  @override
  Future<DateTime> markNotificationRead(String notificationId) async {
    if (markReadFails) throw StateError('offline');
    markedRead.add(notificationId);
    return _readAt;
  }

  @override
  Future<GichoNotificationsReadReceipt> markAllNotificationsRead() async {
    markAllReadCount++;
    return GichoNotificationsReadReceipt(
      readCount: pages.expand((page) => page).length,
      readAt: _readAt,
    );
  }

  @override
  Future<void> openNotification(
    BuildContext context,
    GichoNotificationRecord notification,
  ) async {}
}
