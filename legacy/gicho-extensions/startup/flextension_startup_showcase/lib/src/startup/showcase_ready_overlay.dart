import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

import 'showcase_frame.dart';
import 'showcase_progress.dart';

/// The final large visual waits for queue data to say the app is ready.
Widget buildShowcaseReadyOverlay(
  BuildContext context,
  StartupState state,
  VoidCallback complete,
  ShowcaseStartupProgress progress,
) => ShowcaseFrame(
  progress: progress,
  visual: ShowcaseReadyMessage(progress: progress, onComplete: complete),
);

final class ShowcaseReadyMessage extends StatefulWidget {
  const ShowcaseReadyMessage({
    super.key,
    required this.progress,
    required this.onComplete,
  });

  final ShowcaseStartupProgress progress;
  final VoidCallback onComplete;

  @override
  State<ShowcaseReadyMessage> createState() => _ShowcaseReadyMessageState();
}

class _ShowcaseReadyMessageState extends State<ShowcaseReadyMessage> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_progressChanged);
    _progressChanged();
  }

  void _progressChanged() {
    if (!widget.progress.isComplete || _ready) return;
    setState(() => _ready = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
  }

  @override
  void dispose() {
    widget.progress.removeListener(_progressChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _ready
            ? const Icon(Icons.rocket_launch, key: ValueKey('ready'), size: 160)
            : const Icon(
                Icons.hourglass_top,
                key: ValueKey('waiting'),
                size: 160,
              ),
      ),
      const SizedBox(height: 20),
      Text(
        _ready
            ? 'Ready for launch!'
            : 'Finishing the important-looking bits...',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ],
  );
}
