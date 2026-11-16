import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:moztopia/gicho.dart';

const _animationAsset = 'assets/animations/startup.json';
const _packageName = 'flextension_startup_showcase';

/// The first showcase overlay.
///
/// Gicho supplies [complete]. This overlay calls it only after the Lottie
/// animation has played once from beginning to end.
Widget buildShowcaseAnimationOverlay(
  BuildContext context,
  StartupState state,
  VoidCallback complete,
) => ShowcaseAnimation(onComplete: complete);

final class ShowcaseAnimation extends StatefulWidget {
  const ShowcaseAnimation({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<ShowcaseAnimation> createState() => _ShowcaseAnimationState();
}

class _ShowcaseAnimationState extends State<ShowcaseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playOnce(LottieComposition animation) {
    _controller
      ..duration = animation.duration
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 320,
        height: 320,
        child: Semantics(
          label: 'Startup animation',
          image: true,
          child: Lottie.asset(
            _animationAsset,
            package: _packageName,
            controller: _controller,
            repeat: false,
            fit: BoxFit.contain,
            onLoaded: _playOnce,
            errorBuilder: (context, error, stackTrace) =>
                ShowcaseAnimationError(onContinue: widget.onComplete),
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Text('Animating the improbable...'),
    ],
  );
}

/// A visible fallback that keeps the showcase moving when its sample asset is
/// intentionally replaced with an invalid Lottie file.
final class ShowcaseAnimationError extends StatefulWidget {
  const ShowcaseAnimationError({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<ShowcaseAnimationError> createState() => _ShowcaseAnimationErrorState();
}

class _ShowcaseAnimationErrorState extends State<ShowcaseAnimationError> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), widget.onContinue);
  }

  @override
  Widget build(BuildContext context) => const Icon(Icons.animation, size: 96);
}
