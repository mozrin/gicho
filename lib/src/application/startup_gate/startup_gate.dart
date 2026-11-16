import 'dart:async';

import 'package:flutter/widgets.dart';

class StartupGate<T> extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.load,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.readyBuilder,
  });

  final Future<T> Function() load;
  final WidgetBuilder loadingBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)
  errorBuilder;
  final Widget Function(BuildContext context, T value) readyBuilder;

  @override
  State<StartupGate<T>> createState() => _StartupGateState<T>();
}

class _StartupGateState<T> extends State<StartupGate<T>> {
  int _generation = 0;
  T? _value;
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final generation = ++_generation;
    setState(() {
      _ready = false;
      _value = null;
      _error = null;
    });
    try {
      final value = await widget.load();
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _value = value;
        _ready = true;
      });
    } catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    ++_generation;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder(context, _error!, () => unawaited(_run()));
    }
    if (_ready) {
      return widget.readyBuilder(context, _value as T);
    }
    return widget.loadingBuilder(context);
  }
}
