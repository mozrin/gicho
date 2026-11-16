import 'package:material_ui/material_ui.dart';
import 'package:flutter/widgets.dart';

import '../../core_configuration.dart';

typedef GichoAppBarWidgetBuilder = Widget Function(BuildContext context);

/// A Dart-owned app-bar action whose availability may be overridden by core
/// configuration.
final class GichoAppBarAction {
  const GichoAppBarAction({
    required this.id,
    required this.builder,
    this.isVisible,
  });

  final GichoAppBarFeature id;
  final GichoAppBarWidgetBuilder builder;
  final bool Function(BuildContext context)? isVisible;
}
