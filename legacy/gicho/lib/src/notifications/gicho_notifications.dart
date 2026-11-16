import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

import 'notification_state.dart';

/// Installs Gicho's supported transient-notification implementation.
final class GichoNotifications extends StatelessWidget {
  const GichoNotifications({super.key, required this.child});

  final Widget child;

  /// Reads the notification system installed by [GichoBootstrap].
  static GichoNotificationsState of(BuildContext context) =>
      GichoNotificationsScope.of(context).state;

  static GichoNotificationsState? maybeOf(BuildContext context) =>
      GichoNotificationsScope.maybeOf(context)?.state;

  @override
  Widget build(BuildContext context) => ToastificationWrapper(child: child);
}
