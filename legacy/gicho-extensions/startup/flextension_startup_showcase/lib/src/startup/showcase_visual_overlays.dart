import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

Widget buildOrbitingIdeasOverlay(
  BuildContext context,
  StartupState state,
  VoidCallback complete,
) => ShowcaseTimedVisual(
  duration: const Duration(seconds: 10),
  onComplete: complete,
  icon: Icons.lightbulb_outline,
  title: 'Putting ideas into orbit',
  color: Colors.amber,
);

Widget buildPackingBoxesOverlay(
  BuildContext context,
  StartupState state,
  VoidCallback complete,
) => ShowcaseTimedVisual(
  duration: const Duration(seconds: 10),
  onComplete: complete,
  icon: Icons.inventory_2_outlined,
  title: 'Packing the last few boxes',
  color: Colors.blue,
);

/// A deliberately obvious example of a timed visual overlay.
final class ShowcaseTimedVisual extends StatefulWidget {
  const ShowcaseTimedVisual({
    super.key,
    required this.duration,
    required this.onComplete,
    required this.icon,
    required this.title,
    required this.color,
  });

  final Duration duration;
  final VoidCallback onComplete;
  final IconData icon;
  final String title;
  final Color color;

  @override
  State<ShowcaseTimedVisual> createState() => _ShowcaseTimedVisualState();
}

class _ShowcaseTimedVisualState extends State<ShowcaseTimedVisual>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onComplete);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.15).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Icon(widget.icon, size: 180, color: widget.color),
      ),
      const SizedBox(height: 24),
      Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
    ],
  );
}
