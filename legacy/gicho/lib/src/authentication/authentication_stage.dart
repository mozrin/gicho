import 'dart:async';

import 'package:flutter/widgets.dart';

import 'authentication_delegate.dart';

/// Authentication information available below [GichoBootstrap].
final class AuthenticationRuntime {
  const AuthenticationRuntime._({
    required this.isAvailable,
    this.state,
    this.delegate,
  });

  const AuthenticationRuntime.unavailable() : this._(isAvailable: false);

  const AuthenticationRuntime.available({
    required AuthenticationState state,
    required AuthenticationDelegate delegate,
  }) : this._(isAvailable: true, state: state, delegate: delegate);

  final bool isAvailable;
  final AuthenticationState? state;
  final AuthenticationDelegate? delegate;
}

/// Runs a consumer-supplied authentication delegate before revealing [child].
final class AuthenticationStage extends StatefulWidget {
  const AuthenticationStage({
    super.key,
    required this.delegate,
    required this.child,
  });

  final AuthenticationDelegate delegate;
  final Widget child;

  static AuthenticationRuntime of(BuildContext context) =>
      AuthenticationScope.of(context).runtime;

  static AuthenticationRuntime? maybeOf(BuildContext context) =>
      AuthenticationScope.maybeOf(context)?.runtime;

  @override
  State<AuthenticationStage> createState() => _AuthenticationStageState();
}

class _AuthenticationStageState extends State<AuthenticationStage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.delegate.initialize());
  }

  @override
  void didUpdateWidget(AuthenticationStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.delegate, widget.delegate)) {
      oldWidget.delegate.dispose();
      unawaited(widget.delegate.initialize());
    }
  }

  @override
  void dispose() {
    widget.delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<AuthenticationState>(
        valueListenable: widget.delegate.state,
        builder: (context, state, _) => AuthenticationScope(
          runtime: AuthenticationRuntime.available(
            state: state,
            delegate: widget.delegate,
          ),
          child: Builder(
            builder: (context) => state == AuthenticationState.authenticated
                ? widget.child
                : widget.delegate.buildAuthentication(context),
          ),
        ),
      );
}

/// Provides authentication orchestration state to descendant widgets.
final class AuthenticationScope extends InheritedWidget {
  const AuthenticationScope({
    super.key,
    required this.runtime,
    required super.child,
  });

  final AuthenticationRuntime runtime;

  static AuthenticationScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw StateError(
        'Gicho authentication state is unavailable. '
        'Wrap this subtree in GichoBootstrap.',
      );
    }
    return scope;
  }

  static AuthenticationScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthenticationScope>();

  @override
  bool updateShouldNotify(AuthenticationScope oldWidget) =>
      runtime.isAvailable != oldWidget.runtime.isAvailable ||
      runtime.state != oldWidget.runtime.state ||
      !identical(runtime.delegate, oldWidget.runtime.delegate);
}
