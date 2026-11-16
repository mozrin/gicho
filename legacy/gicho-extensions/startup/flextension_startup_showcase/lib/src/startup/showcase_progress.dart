import 'package:flutter/foundation.dart';

enum ShowcaseTaskStatus { waiting, running, complete }

final class ShowcaseTaskProgress {
  const ShowcaseTaskProgress({
    required this.name,
    required this.phrase,
    this.status = ShowcaseTaskStatus.waiting,
    this.fractionComplete = 0,
  });

  final String name;
  final String phrase;
  final ShowcaseTaskStatus status;
  final double fractionComplete;

  ShowcaseTaskProgress copyWith({
    ShowcaseTaskStatus? status,
    double? fractionComplete,
  }) => ShowcaseTaskProgress(
    name: name,
    phrase: phrase,
    status: status ?? this.status,
    fractionComplete: fractionComplete ?? this.fractionComplete,
  );
}

/// Data written by queue processes and observed by the persistent status UI.
final class ShowcaseStartupProgress extends ChangeNotifier {
  final List<ShowcaseTaskProgress> _tasks = [
    const ShowcaseTaskProgress(
      name: 'Load configuration',
      phrase: 'Circling the drain...',
    ),
    const ShowcaseTaskProgress(
      name: 'Warm the cache',
      phrase: 'Organizing the bucket list...',
    ),
    const ShowcaseTaskProgress(
      name: 'Register services',
      phrase: 'Herding stray bits...',
    ),
  ];

  List<ShowcaseTaskProgress> get tasks => List.unmodifiable(_tasks);

  double get fractionComplete =>
      _tasks.fold(0.0, (total, task) => total + task.fractionComplete) /
      _tasks.length;

  int get percentComplete => (fractionComplete * 100).round();

  bool get isComplete =>
      _tasks.every((task) => task.status == ShowcaseTaskStatus.complete);

  String get currentPhrase {
    final running = _tasks.where(
      (task) => task.status == ShowcaseTaskStatus.running,
    );
    if (running.isNotEmpty) return running.first.phrase;
    return isComplete ? 'Everything is suspiciously ready.' : 'Warming up...';
  }

  void start(String taskName) =>
      _update(taskName, status: ShowcaseTaskStatus.running, fraction: 0);

  void report(String taskName, double fraction) =>
      _update(taskName, fraction: fraction);

  void complete(String taskName) =>
      _update(taskName, status: ShowcaseTaskStatus.complete, fraction: 1);

  void _update(
    String taskName, {
    ShowcaseTaskStatus? status,
    double? fraction,
  }) {
    final index = _tasks.indexWhere((task) => task.name == taskName);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(
      status: status,
      fractionComplete: fraction?.clamp(0, 1),
    );
    notifyListeners();
  }
}
