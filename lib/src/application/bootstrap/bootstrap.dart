import 'package:flutter/material.dart';

import '../startup_gate/index.dart';
import 'parts/GichoBootstrapFailureView.dart';
import 'parts/GichoBootstrapLoadingView.dart';

/// Runs consumer preparation before handing its result to the application.
class GichoBootstrap<T> extends StatefulWidget {
  const GichoBootstrap({
    super.key,
    required this.load,
    required this.title,
    required this.theme,
    required this.failureMessage,
    required this.retryLabel,
    required this.readyBuilder,
    this.loadingMessage,
    this.loadingScreen,
    this.minimumDurationFor,
    this.holdNativeLaunch = false,
  });

  final Future<T> Function() load;
  final String title;
  final ThemeData theme;
  final String? loadingMessage;
  final Widget? loadingScreen;
  final Duration Function(T value)? minimumDurationFor;
  final bool holdNativeLaunch;
  final String failureMessage;
  final String retryLabel;
  final Widget Function(BuildContext context, T value) readyBuilder;

  @override
  State<GichoBootstrap<T>> createState() => _GichoBootstrapState<T>();
}

class _GichoBootstrapState<T> extends State<GichoBootstrap<T>> {
  bool _firstFrameHeld = false;

  @override
  void initState() {
    super.initState();
    if (widget.holdNativeLaunch) {
      WidgetsBinding.instance.deferFirstFrame();
      _firstFrameHeld = true;
    }
  }

  void _releaseFirstFrame() {
    if (!_firstFrameHeld) {
      return;
    }
    WidgetsBinding.instance.allowFirstFrame();
    _firstFrameHeld = false;
  }

  Widget _reveal(Widget child) {
    if (_firstFrameHeld) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _releaseFirstFrame());
    }
    return child;
  }

  @override
  void dispose() {
    _releaseFirstFrame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StartupGate<T>(
    load: () async {
      final clock = Stopwatch()..start();
      final value = await widget.load();
      final minimum = widget.minimumDurationFor?.call(value) ?? Duration.zero;
      final remaining = minimum - clock.elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
      return value;
    },
    loadingBuilder: (_) => GichoBootstrapLoadingView(
      theme: widget.theme,
      title: widget.title,
      message: widget.loadingMessage,
      screen: widget.loadingScreen,
    ),
    errorBuilder: (_, _, retry) => _reveal(
      GichoBootstrapFailureView(
        theme: widget.theme,
        message: widget.failureMessage,
        retryLabel: widget.retryLabel,
        retry: retry,
      ),
    ),
    readyBuilder: (context, value) =>
        _reveal(widget.readyBuilder(context, value)),
  );
}
