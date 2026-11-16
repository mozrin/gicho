import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Responsive full-screen canvas for consumer-owned splash artwork.
class SplashScene extends StatelessWidget {
  const SplashScene({
    super.key,
    required this.title,
    this.artworkAsset,
    this.portraitSceneAsset,
    this.landscapeSceneAsset,
    this.panel,
    this.backgroundColor,
    this.foregroundColor,
  }) : assert(
         (portraitSceneAsset == null) == (landscapeSceneAsset == null),
         'Full scenes need both portrait and landscape assets.',
       );

  final String title;
  final String? artworkAsset;
  final String? portraitSceneAsset;
  final String? landscapeSceneAsset;
  final Widget? panel;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: backgroundColor ?? scheme.surface,
      body: LayoutBuilder(
        builder: (context, viewport) {
          final compact = viewport.maxWidth < 768;
          final sceneAsset = compact ? portraitSceneAsset : landscapeSceneAsset;
          if (sceneAsset != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  sceneAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  excludeFromSemantics: true,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x99000000),
                      ],
                      stops: [0, 0.26, 0.62, 1],
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0, viewport.maxHeight - 48),
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: compact
                                  ? Alignment.topCenter
                                  : AlignmentDirectional.topStart,
                              child: Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  textAlign: compact
                                      ? TextAlign.center
                                      : TextAlign.start,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (panel != null)
                              Align(
                                alignment: compact
                                    ? Alignment.bottomCenter
                                    : AlignmentDirectional.bottomEnd,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
                                  child: panel!,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          final art = artworkAsset == null
              ? null
              : Image.asset(
                  artworkAsset!,
                  width: compact
                      ? math.min(viewport.maxWidth * 0.64, 300)
                      : math.min(viewport.maxWidth * 0.34, 420),
                  height: compact
                      ? math.min(viewport.maxHeight * 0.34, 300)
                      : math.min(viewport.maxHeight * 0.66, 420),
                  fit: BoxFit.contain,
                  semanticLabel: title,
                );
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: foregroundColor ?? scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (panel != null) ...[const SizedBox(height: 24), panel!],
            ],
          );
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: compact || art == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (art != null) ...[
                              art,
                              const SizedBox(height: 28),
                            ],
                            content,
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            art,
                            const SizedBox(width: 48),
                            Flexible(child: content),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
