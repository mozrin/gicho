import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'entitlement_adapter.dart';
import 'entitlement_configuration.dart';
import 'entitlement_controller.dart';
import 'qonversion_entitlement_adapter.dart';

final gichoEntitlementsProvider =
    ChangeNotifierProvider<GichoEntitlementController>(
      (_) => throw StateError(
        'Gicho entitlements were not installed by GichoBootstrap.',
      ),
      disposeNotifier: false,
    );

/// Installs the reusable entitlement controller without blocking app startup.
final class GichoEntitlements extends StatefulWidget {
  const GichoEntitlements({
    super.key,
    required this.child,
    this.configuration,
    this.adapter,
  });

  final Widget child;
  final GichoEntitlementConfiguration? configuration;
  final GichoEntitlementAdapter? adapter;

  static GichoEntitlementController of(BuildContext context) =>
      GichoEntitlementsScope.of(context).controller;

  static GichoEntitlementController? maybeOf(BuildContext context) =>
      GichoEntitlementsScope.maybeOf(context)?.controller;

  @override
  State<GichoEntitlements> createState() => _GichoEntitlementsState();
}

class _GichoEntitlementsState extends State<GichoEntitlements> {
  late final GichoEntitlementController _controller =
      widget.configuration == null
      ? GichoEntitlementController.unavailable()
      : GichoEntitlementController(
          configuration: widget.configuration!,
          adapter: widget.adapter ?? QonversionEntitlementAdapter(),
        );

  @override
  void initState() {
    super.initState();
    if (widget.configuration != null) unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [gichoEntitlementsProvider.overrideWith((_) => _controller)],
    child: GichoEntitlementsScope(
      controller: _controller,
      child: widget.child,
    ),
  );
}

final class GichoEntitlementsScope
    extends InheritedNotifier<GichoEntitlementController> {
  const GichoEntitlementsScope({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final GichoEntitlementController controller;

  static GichoEntitlementsScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw StateError(
        'Gicho entitlement state is unavailable. '
        'Wrap this subtree in GichoBootstrap.',
      );
    }
    return scope;
  }

  static GichoEntitlementsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GichoEntitlementsScope>();
}
