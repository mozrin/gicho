import 'dart:async';

import 'package:flutter/material.dart';

import 'startup_delegate.dart';
import 'startup_page.dart';
import 'startup_state.dart';

/// Runs startup overlays and the process queue before revealing [child].
final class StartupStage extends StatefulWidget {
  const StartupStage({
    super.key,
    required this.child,
    required this.delegate,
    required this.queue,
    required this.postDelayDuration,
  });

  final Widget child;
  final StartupDelegate delegate;
  final Future<void> queue;
  final Duration postDelayDuration;

  static StartupState of(BuildContext context) =>
      StartupScope.of(context).state;

  static StartupState? maybeOf(BuildContext context) =>
      StartupScope.maybeOf(context)?.state;

  @override
  State<StartupStage> createState() => _StartupStageState();
}

class _StartupStageState extends State<StartupStage> {
  final _overlaysCompletion = Completer<void>();
  late final Future<void> _completion;
  var _overlayIndex = 0;
  var _advanceScheduled = false;

  @override
  void initState() {
    super.initState();
    _completion = Future.wait([
      widget.queue,
      _overlaysCompletion.future,
    ]).then((_) => Future<void>.delayed(widget.postDelayDuration));
    if (widget.delegate.startupOverlays.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishOverlays());
    }
  }

  void _overlayCompleted() {
    if (_advanceScheduled || _overlaysCompletion.isCompleted) return;
    _advanceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlaysCompletion.isCompleted) return;
      _advanceScheduled = false;
      final isLast =
          _overlayIndex == widget.delegate.startupOverlays.length - 1;
      if (isLast) {
        _finishOverlays();
      } else {
        setState(() => _overlayIndex++);
      }
    });
  }

  void _finishOverlays() {
    if (!_overlaysCompletion.isCompleted) _overlaysCompletion.complete();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _completion,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return StartupScope(
          state: const StartupState.complete(),
          child: ErrorWidget(snapshot.error!),
        );
      }
      if (snapshot.connectionState == ConnectionState.done) {
        return StartupScope(
          state: const StartupState.complete(),
          child: widget.child,
        );
      }
      const state = StartupState.running();
      return StartupScope(state: state, child: _buildOverlay(context, state));
    },
  );

  Widget _buildOverlay(BuildContext context, StartupState state) {
    final overlays = widget.delegate.startupOverlays;
    if (overlays.isEmpty) return const StartupPage();
    return KeyedSubtree(
      key: ValueKey(_overlayIndex),
      child: overlays[_overlayIndex](context, state, _overlayCompleted),
    );
  }
}

/// Provides the current startup-stage state to descendant widgets.
final class StartupScope extends InheritedWidget {
  const StartupScope({super.key, required this.state, required super.child});

  final StartupState state;

  static StartupScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw StateError(
        'Gicho startup state is unavailable. '
        'Wrap this subtree in GichoBootstrap.',
      );
    }
    return scope;
  }

  static StartupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StartupScope>();

  @override
  bool updateShouldNotify(StartupScope oldWidget) =>
      state.isAvailable != oldWidget.state.isAvailable ||
      state.isRunning != oldWidget.state.isRunning;
}
