import 'package:flutter/material.dart';

import 'showcase_progress.dart';

/// Persistent queue status displayed below every large visual overlay.
final class ShowcaseProgressPanel extends StatelessWidget {
  const ShowcaseProgressPanel({super.key, required this.progress});

  final ShowcaseStartupProgress progress;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: progress,
    builder: (context, _) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            progress.currentPhrase,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress.fractionComplete),
          const SizedBox(height: 8),
          Text(
            '${progress.percentComplete}% ready',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final task in progress.tasks) ShowcaseTaskChip(task: task),
            ],
          ),
        ],
      ),
    ),
  );
}

final class ShowcaseTaskChip extends StatelessWidget {
  const ShowcaseTaskChip({super.key, required this.task});

  final ShowcaseTaskProgress task;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: switch (task.status) {
      ShowcaseTaskStatus.waiting => const Icon(Icons.circle_outlined),
      ShowcaseTaskStatus.running => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      ShowcaseTaskStatus.complete => const Icon(
        Icons.check_circle,
        color: Colors.green,
      ),
    },
    label: Text(task.name),
  );
}
