import 'package:flutter/widgets.dart';

/// The runtime availability of Gicho localization for the current subtree.
final class GichoLocalizationState {
  const GichoLocalizationState._(this.isAvailable);

  const GichoLocalizationState.available() : this._(true);
  const GichoLocalizationState.unavailable() : this._(false);

  /// True when Gicho localization has been installed and can be used.
  final bool isAvailable;
}

/// Reads the localization system installed by [GichoBootstrap].
abstract final class GichoLocalization {
  static GichoLocalizationState of(BuildContext context) =>
      GichoLocalizationScope.of(context).state;

  static GichoLocalizationState? maybeOf(BuildContext context) =>
      GichoLocalizationScope.maybeOf(context)?.state;
}

/// Provides the current localization system state to descendant widgets.
final class GichoLocalizationScope extends InheritedWidget {
  const GichoLocalizationScope({
    super.key,
    required this.state,
    required super.child,
  });

  final GichoLocalizationState state;

  static GichoLocalizationScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw StateError(
        'Gicho localization state is unavailable. '
        'Wrap this subtree in GichoBootstrap.',
      );
    }
    return scope;
  }

  static GichoLocalizationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GichoLocalizationScope>();

  @override
  bool updateShouldNotify(GichoLocalizationScope oldWidget) =>
      state.isAvailable != oldWidget.state.isAvailable;
}
