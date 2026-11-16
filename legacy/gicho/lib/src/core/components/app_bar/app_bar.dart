import 'package:flutter/material.dart';

import '../../core_configuration.dart';
import '../../moztopia_core.dart';
import 'app_bar_action.dart';
import 'standard_actions.dart';

/// The standard Gicho app bar with configuration-controlled actions.
///
/// Core configuration independently enables or disables the standard
/// actions supplied by Gicho.
final class GichoAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const GichoAppBar({
    super.key,
    required this.title,
    this.configuration,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.bottom,
    this.showStandardActions = true,
    this.actionOverrides = const {},
    this.actions = const [],
  });

  final Widget title;
  final GichoCoreConfiguration? configuration;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;

  /// Whether the package-owned standard actions are considered at all.
  final bool showStandardActions;

  /// Page-specific values that override the global YAML defaults.
  final Map<GichoAppBarFeature, bool> actionOverrides;

  /// Consumer-owned actions appended after the visible standard actions.
  final List<Widget> actions;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final settings = configuration ?? moztopiaCore.configuration;
    final visible = showStandardActions
        ? standardAppBarActions()
              .where(
                (action) =>
                    actionOverrides[action.id] ??
                    settings.isFeatureEnabled(action.id),
              )
              .where((action) => action.isVisible?.call(context) ?? true)
        : const <GichoAppBarAction>[];

    return AppBar(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: title,
      centerTitle: centerTitle,
      bottom: bottom,
      actions: [
        for (final action in visible) action.builder(context),
        ...actions,
      ],
    );
  }
}
