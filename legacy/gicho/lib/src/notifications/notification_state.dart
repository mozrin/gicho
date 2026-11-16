import 'package:flutter/widgets.dart';

/// The runtime availability of Gicho notifications for the current subtree.
final class GichoNotificationsState {
  const GichoNotificationsState._(this.isAvailable);

  const GichoNotificationsState.available() : this._(true);
  const GichoNotificationsState.unavailable() : this._(false);

  /// True when the Gicho notification layer is installed.
  final bool isAvailable;
}

/// Provides the current notification system state to descendant widgets.
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
      state.isAvailable != oldWidget.state.isAvailable;
}
