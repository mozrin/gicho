import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

import '../localization/translate.dart';
import '../logging/configured_logging.dart';
import 'notification_state.dart';

/// Installs Gicho's notification runtime and transient feedback wrapper.
final class GichoNotifications extends StatefulWidget {
  const GichoNotifications({
    super.key,
    required this.configuration,
    required this.child,
    this.delegate,
  });

  final GichoNotificationsConfiguration configuration;
  final GichoNotificationDelegate? delegate;
  final Widget child;

  static GichoNotificationsState of(BuildContext context) =>
      GichoNotificationsScope.of(context).state;

  static GichoNotificationsState? maybeOf(BuildContext context) =>
      GichoNotificationsScope.maybeOf(context)?.state;

  @override
  State<GichoNotifications> createState() => _GichoNotificationsState();
}

class _GichoNotificationsState extends State<GichoNotifications> {
  GichoNotificationController? _controller;
  late GichoNotificationsState _runtime;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(GichoNotifications oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.configuration, widget.configuration) ||
        !identical(oldWidget.delegate, widget.delegate)) {
      _controller?.dispose();
      _configure();
    }
  }

  void _configure() {
    final delegate = widget.delegate;
    _controller =
        delegate != null &&
            widget.configuration.isChannelEnabled(
              GichoNotificationChannel.inApp,
            )
        ? GichoNotificationController(
            configuration: widget.configuration,
            delegate: delegate,
          )
        : null;
    _runtime = GichoNotificationsState.available(
      configuration: widget.configuration,
      controller: _controller,
      delegate: delegate,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GichoNotificationsScope(
    state: _runtime,
    child: ToastificationWrapper(child: widget.child),
  );
}

/// Standard app-bar action for the configured in-app notification feed.
final class GichoNotificationButton extends StatefulWidget {
  const GichoNotificationButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<GichoNotificationButton> createState() =>
      _GichoNotificationButtonState();
}

class _GichoNotificationButtonState
    extends State<GichoNotificationButton> {
  GichoNotificationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = GichoNotifications.of(context).controller;
    if (identical(controller, _controller)) return;
    _controller = controller;
    if (controller != null) unawaited(controller.ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final runtime = GichoNotifications.of(context);
    final controller = runtime.controller;
    if (!runtime.feedAvailable || controller == null) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final unreadCount = controller.state.unreadCount;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Badge.count(
            count: unreadCount,
            isLabelVisible: unreadCount > 0,
            offset: const Offset(-4, 4),
            child: IconButton(
              tooltip: translate(
                runtime.configuration!.copy.openKey,
                context: context,
              ),
              onPressed: widget.onPressed,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        );
      },
    );
  }
}

/// Full-page, configuration-driven in-app notification destination.
final class GichoNotificationFeedPage extends StatefulWidget {
  const GichoNotificationFeedPage({super.key});

  @override
  State<GichoNotificationFeedPage> createState() =>
      _GichoNotificationFeedPageState();
}

class _GichoNotificationFeedPageState
    extends State<GichoNotificationFeedPage> {
  GichoNotificationController? _controller;

  @override
  void initState() {
    super.initState();
    unawaited(moztopiaLog.info('[Gicho notifications] Feed page opened.'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = GichoNotifications.of(context).controller;
    if (identical(controller, _controller)) return;
    _controller = controller;
    if (controller != null) unawaited(controller.ensureLoaded());
  }

  @override
  void dispose() {
    unawaited(moztopiaLog.info('[Gicho notifications] Feed page closed.'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = GichoNotifications.of(context);
    final configuration = runtime.configuration!;
    final controller = runtime.controller;
    final copy = configuration.copy;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(translate(copy.titleKey, context: context)),
        actions: [
          if (controller != null)
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => IconButton(
                tooltip: translate(copy.markAllReadKey, context: context),
                onPressed:
                    controller.state.unreadCount == 0 ||
                        controller.state.mutating
                    ? null
                    : controller.markAllRead,
                icon: const Icon(Icons.done_all_rounded),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: controller == null
            ? _NotificationStatus(
                icon: Icons.notifications_off_outlined,
                title: translate(copy.loadFailedKey, context: context),
                detail: translate(copy.loadFailedDetailKey, context: context),
              )
            : ListenableBuilder(
                listenable: controller,
                builder: (context, _) => _NotificationBody(
                  configuration: configuration,
                  controller: controller,
                  delegate: runtime.delegate!,
                ),
              ),
      ),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  const _NotificationBody({
    required this.configuration,
    required this.controller,
    required this.delegate,
  });

  final GichoNotificationsConfiguration configuration;
  final GichoNotificationController controller;
  final GichoNotificationDelegate delegate;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final copy = configuration.copy;
    return switch (state.phase) {
      GichoNotificationFeedPhase.idle ||
      GichoNotificationFeedPhase.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      GichoNotificationFeedPhase.failed => RefreshIndicator(
        onRefresh: controller.reload,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 70),
            _NotificationStatus(
              icon: Icons.cloud_off_outlined,
              title: translate(copy.loadFailedKey, context: context),
              detail: translate(copy.loadFailedDetailKey, context: context),
              action: FilledButton.tonalIcon(
                onPressed: controller.reload,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(translate(copy.retryKey, context: context)),
              ),
            ),
          ],
        ),
      ),
      GichoNotificationFeedPhase.ready => _NotificationFeed(
        state: state,
        configuration: configuration,
        onRefresh: controller.reload,
        onLoadMore: controller.loadMore,
        onClearFailure: controller.clearMutationFailure,
        onOpen: (notification) => _open(context, notification),
      ),
    };
  }

  Future<void> _open(
    BuildContext context,
    GichoNotificationRecord notification,
  ) async {
    await controller.markRead(notification.id);
    if (!context.mounted) return;
    final entry = configuration.entryFor(notification.type);
    final action = notification.action;
    if (entry?.action == null ||
        action == null ||
        entry!.action != action.type) {
      return;
    }
    unawaited(
      moztopiaLog.info(
        '[Gicho notifications] Notification destination requested: '
        '${notification.type}.',
      ),
    );
    await delegate.openNotification(context, notification);
  }
}

class _NotificationFeed extends StatelessWidget {
  const _NotificationFeed({
    required this.state,
    required this.configuration,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onClearFailure,
    required this.onOpen,
  });

  final GichoNotificationFeedState state;
  final GichoNotificationsConfiguration configuration;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onClearFailure;
  final ValueChanged<GichoNotificationRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final copy = configuration.copy;
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 90),
            _NotificationStatus(
              icon: Icons.notifications_none_rounded,
              title: translate(copy.emptyKey, context: context),
              detail: translate(copy.emptyDetailKey, context: context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 280 && state.hasMore) {
            onLoadMore();
          }
          return false;
        },
        child: ListView(
          key: const PageStorageKey('gicho-notification-feed'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            Text(
              translate(copy.headingKey, context: context),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              translate(copy.introductionKey, context: context),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.mutationFailed) ...[
              const SizedBox(height: 16),
              _InlineFailure(
                message: translate(copy.saveFailedKey, context: context),
                onDismiss: onClearFailure,
              ),
            ],
            const SizedBox(height: 22),
            for (final notification in state.items) ...[
              _NotificationCard(
                notification: notification,
                entry: configuration.entryFor(notification.type)!,
                copy: copy,
                onTap: () => onOpen(notification),
              ),
              const SizedBox(height: 10),
            ],
            if (state.loadingMore)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.loadMoreFailed)
              OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  translate(copy.loadMoreFailedKey, context: context),
                ),
              )
            else if (state.hasMore)
              OutlinedButton(
                onPressed: onLoadMore,
                child: Text(translate(copy.loadMoreKey, context: context)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.entry,
    required this.copy,
    required this.onTap,
  });

  final GichoNotificationRecord notification;
  final GichoNotificationCatalogEntry entry;
  final GichoNotificationCopyConfiguration copy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = notification.readAt == null;
    final actionable =
        entry.action != null && notification.action?.type == entry.action;
    final unavailable = entry.action != null && !actionable;
    final detailKey = unavailable
        ? entry.unavailableDetailKey ?? entry.detailKey
        : entry.detailKey;
    final scheme = Theme.of(context).colorScheme;
    final title = translate(entry.titleKey, context: context);
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(notification.createdAt.toLocal());

    return Card(
      color: unread ? scheme.primaryContainer.withValues(alpha: 0.62) : null,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: unread || actionable,
        label: translate(
          unread ? copy.unreadSemanticsKey : copy.readSemanticsKey,
          context: context,
          namedArgs: {'title': title},
        ),
        child: InkWell(
          key: ValueKey('notification-${notification.id}'),
          onTap: unread || actionable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: entry.icon == GichoNotificationIcon.favorite
                        ? scheme.primary
                        : scheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon(entry.icon),
                    color: entry.icon == GichoNotificationIcon.favorite
                        ? scheme.onPrimary
                        : scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(translate(detailKey, context: context)),
                      const SizedBox(height: 9),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (actionable) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _icon(GichoNotificationIcon icon) => switch (icon) {
    GichoNotificationIcon.notification => Icons.notifications_rounded,
    GichoNotificationIcon.favorite => Icons.favorite_rounded,
    GichoNotificationIcon.star => Icons.star_rounded,
    GichoNotificationIcon.message => Icons.chat_bubble_rounded,
    GichoNotificationIcon.shield => Icons.shield_rounded,
    GichoNotificationIcon.account => Icons.person_rounded,
    GichoNotificationIcon.campaign => Icons.campaign_rounded,
  };
}

class _InlineFailure extends StatelessWidget {
  const _InlineFailure({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 8),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    ),
  );
}

class _NotificationStatus extends StatelessWidget {
  const _NotificationStatus({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 390),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}
