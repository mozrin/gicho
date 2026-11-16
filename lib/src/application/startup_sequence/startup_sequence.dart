import 'dart:async';

import 'package:flutter/material.dart';

/// A full-page scene shown before application initialization starts.
class StartupScene {
  const StartupScene({
    required this.builder,
    this.minimumDuration = Duration.zero,
    this.prepare,
  });

  final WidgetBuilder builder;
  final Duration minimumDuration;

  /// Optional work that runs while the scene is visible and gates the next scene.
  final Future<void> Function()? prepare;
}

enum StartupJobType { asynchronous, synchronous }

enum StartupJobStatus { waiting, running, complete }

/// Built-in visual changes between introductory and loading screens.
enum StartupTransition { fade, slide, scale, none }

/// A named initialization job. Synchronous jobs are barriers in list order.
class StartupJob {
  const StartupJob({
    required this.id,
    required this.label,
    required this.run,
    this.type = StartupJobType.asynchronous,
  });

  final String id;
  final String label;
  final Future<void> Function(StartupProgress progress) run;
  final StartupJobType type;
}

/// Observable status shared by the initialization jobs and startup screen.
class StartupProgress extends ChangeNotifier {
  StartupProgress(Iterable<StartupJob> jobs)
    : _labels = {for (final job in jobs) job.id: job.label},
      _status = {for (final job in jobs) job.id: StartupJobStatus.waiting},
      _fractions = {for (final job in jobs) job.id: 0};

  final Map<String, String> _labels;
  final Map<String, StartupJobStatus> _status;
  final Map<String, double> _fractions;
  bool _disposed = false;

  Iterable<String> get ids => _labels.keys;
  String label(String id) => _labels[id]!;
  StartupJobStatus status(String id) => _status[id]!;
  double fraction(String id) => _fractions[id]!;

  void start(String id) {
    if (_disposed) {
      return;
    }
    _status[id] = StartupJobStatus.running;
    notifyListeners();
  }

  void report(String id, double fraction) {
    if (_disposed) {
      return;
    }
    _fractions[id] = fraction.clamp(0.0, 1.0);
    notifyListeners();
  }

  void complete(String id) {
    if (_disposed) {
      return;
    }
    _status[id] = StartupJobStatus.complete;
    _fractions[id] = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Shows ordered scenes, then runs visible initialization before opening app.
class StartupSequence<T> extends StatefulWidget {
  const StartupSequence({
    super.key,
    required this.scenes,
    required this.jobs,
    required this.loadLabel,
    required this.load,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.readyBuilder,
    this.minimumLoadingDuration = Duration.zero,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transition = StartupTransition.fade,
  });

  final List<StartupScene> scenes;
  final List<StartupJob> jobs;
  final String loadLabel;
  final Future<T> Function(StartupProgress progress) load;
  final Widget Function(BuildContext, StartupProgress) loadingBuilder;
  final Widget Function(BuildContext, Object, VoidCallback) errorBuilder;
  final Widget Function(BuildContext, T) readyBuilder;
  final Duration minimumLoadingDuration;
  final Duration transitionDuration;
  final StartupTransition transition;

  @override
  State<StartupSequence<T>> createState() => _StartupSequenceState<T>();
}

class _StartupSequenceState<T> extends State<StartupSequence<T>> {
  int _generation = 0;
  int _sceneIndex = 0;
  bool _loading = false;
  bool _ready = false;
  T? _value;
  Object? _error;
  late StartupProgress _progress;

  @override
  void initState() {
    super.initState();
    _progress = _newProgress();
    unawaited(_run());
  }

  Future<void> _run({bool retry = false}) async {
    final generation = ++_generation;
    if (retry) {
      _progress.dispose();
      _progress = _newProgress();
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      if (!retry) {
        for (var index = 0; index < widget.scenes.length; index++) {
          if (!mounted || generation != _generation) {
            return;
          }
          setState(() => _sceneIndex = index);
          final scene = widget.scenes[index];
          await Future.wait<void>([
            Future<void>.delayed(scene.minimumDuration),
            if (scene.prepare != null) scene.prepare!(),
          ]);
        }
      }
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() => _loading = true);
      final minimum = Future<void>.delayed(widget.minimumLoadingDuration);
      final result = _runLoad(_progress);
      final queue = _runJobs(_progress);
      final values = await Future.wait<Object?>([
        result,
        queue,
        minimum,
      ], eagerError: true);
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _value = values.first as T;
        _ready = true;
      });
    } catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() => _error = error);
    }
  }

  StartupProgress _newProgress() => StartupProgress([
    StartupJob(id: 'load', label: widget.loadLabel, run: (_) async {}),
    ...widget.jobs,
  ]);

  Future<T> _runLoad(StartupProgress progress) async {
    progress.start('load');
    final value = await widget.load(progress);
    progress.complete('load');
    return value;
  }

  Future<void> _runJobs(StartupProgress progress) async {
    final pending = <Future<void>>[];
    for (final job in widget.jobs) {
      if (job.type == StartupJobType.synchronous) {
        await Future.wait(pending);
        pending.clear();
        await _runJob(job, progress);
      } else {
        pending.add(_runJob(job, progress));
      }
    }
    await Future.wait(pending);
  }

  Future<void> _runJob(StartupJob job, StartupProgress progress) async {
    progress.start(job.id);
    await job.run(progress);
    progress.complete(job.id);
  }

  @override
  void dispose() {
    ++_generation;
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return widget.readyBuilder(context, _value as T);
    }
    if (_error != null) {
      return widget.errorBuilder(
        context,
        _error!,
        () => unawaited(_run(retry: true)),
      );
    }
    final page = _loading || widget.scenes.isEmpty
        ? widget.loadingBuilder(context, _progress)
        : widget.scenes[_sceneIndex].builder(context);
    return AnimatedSwitcher(
      duration: widget.transition == StartupTransition.none
          ? Duration.zero
          : widget.transitionDuration,
      transitionBuilder: (child, animation) => switch (widget.transition) {
        StartupTransition.fade => FadeTransition(
          opacity: animation,
          child: child,
        ),
        StartupTransition.slide => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        StartupTransition.scale => ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        StartupTransition.none => child,
      },
      child: KeyedSubtree(
        key: ValueKey(_loading ? 'loading' : 'scene-$_sceneIndex'),
        child: page,
      ),
    );
  }
}
