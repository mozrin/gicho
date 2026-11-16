import 'package:flutter/material.dart';

import '../splash_scene/index.dart';
import '../startup_sequence/index.dart';
import 'parts/GichoStartupNetworkCountry.dart';
import 'parts/GichoStartupScheduledScene.dart';

/// Presentation strings owned by the consuming application's catalog.
class GichoStartupLabels {
  const GichoStartupLabels({
    required this.company,
    required this.product,
    required this.loading,
    required this.failed,
    required this.retry,
  });

  final String company;
  final String product;
  final String loading;
  final String failed;
  final String retry;
}

/// Typed view of the schema-validated `app.startup` configuration.
class GichoStartupConfiguration {
  const GichoStartupConfiguration({
    this.companyMinimum = Duration.zero,
    this.productMinimum = Duration.zero,
    this.loadingMinimum = Duration.zero,
    this.transitionDuration = Duration.zero,
    this.transition = StartupTransition.fade,
    this.companyArtworkAsset,
    this.productArtworkAsset,
    this.loadingArtworkAsset,
    this.companyPortraitSceneAsset,
    this.companyLandscapeSceneAsset,
    this.productPortraitSceneAsset,
    this.productLandscapeSceneAsset,
    this.loadingPortraitSceneAsset,
    this.loadingLandscapeSceneAsset,
    this.countryLookupPath,
    this._scheduledProductScenes = const [],
  });

  factory GichoStartupConfiguration.fromConfiguration(
    Map<String, dynamic> values,
  ) {
    final app = values['app'] as Map;
    final startup = app['startup'] as Map;
    return GichoStartupConfiguration(
      companyMinimum: Duration(
        milliseconds: startup['companyMinimumMilliseconds'] as int,
      ),
      productMinimum: Duration(
        milliseconds: startup['productMinimumMilliseconds'] as int,
      ),
      loadingMinimum: Duration(
        milliseconds: startup['loadingMinimumMilliseconds'] as int,
      ),
      transitionDuration: Duration(
        milliseconds: startup['transitionMilliseconds'] as int,
      ),
      transition: StartupTransition.values.byName(
        startup['transition'] as String,
      ),
      companyArtworkAsset: startup['companyArtworkAsset'] as String?,
      productArtworkAsset: startup['productArtworkAsset'] as String?,
      loadingArtworkAsset: startup['loadingArtworkAsset'] as String?,
      companyPortraitSceneAsset:
          startup['companyPortraitSceneAsset'] as String?,
      companyLandscapeSceneAsset:
          startup['companyLandscapeSceneAsset'] as String?,
      productPortraitSceneAsset:
          startup['productPortraitSceneAsset'] as String?,
      productLandscapeSceneAsset:
          startup['productLandscapeSceneAsset'] as String?,
      loadingPortraitSceneAsset:
          startup['loadingPortraitSceneAsset'] as String?,
      loadingLandscapeSceneAsset:
          startup['loadingLandscapeSceneAsset'] as String?,
      countryLookupPath: startup['countryLookupPath'] as String?,
      scheduledProductScenes: [
        for (final scene
            in startup['scheduledProductScenes'] as List? ?? const [])
          GichoStartupScheduledScene.fromConfiguration(scene as Map),
      ],
    );
  }

  final Duration companyMinimum;
  final Duration productMinimum;
  final Duration loadingMinimum;
  final Duration transitionDuration;
  final StartupTransition transition;
  final String? companyArtworkAsset;
  final String? productArtworkAsset;
  final String? loadingArtworkAsset;
  final String? companyPortraitSceneAsset;
  final String? companyLandscapeSceneAsset;
  final String? productPortraitSceneAsset;
  final String? productLandscapeSceneAsset;
  final String? loadingPortraitSceneAsset;
  final String? loadingLandscapeSceneAsset;
  final String? countryLookupPath;
  final List<GichoStartupScheduledScene> _scheduledProductScenes;

  /// Selects the first date-and-country match, then the configured default.
  ({String? portrait, String? landscape}) productSceneFor(
    DateTime localDate, {
    String? countryCode,
  }) {
    for (final scene in _scheduledProductScenes) {
      if (scene.includes(localDate, countryCode)) {
        return (portrait: scene.portraitAsset, landscape: scene.landscapeAsset);
      }
    }
    return (
      portrait: productPortraitSceneAsset,
      landscape: productLandscapeSceneAsset,
    );
  }

  /// Returns true only when a dated scene needs country resolution.
  bool needsCountryFor(DateTime localDate) {
    for (final scene in _scheduledProductScenes) {
      if (scene.includesDate(localDate)) {
        return scene.countries.isNotEmpty;
      }
    }
    return false;
  }
}

/// Package-owned full-screen startup sequence with consumer-owned assets.
class GichoStartup<T> extends StatefulWidget {
  const GichoStartup({
    super.key,
    required this.configuration,
    required this.labels,
    required this.load,
    required this.readyBuilder,
    this.jobs = const [],
    this.startupDate,
    this.countryResolver,
    this.origin,
  });

  final GichoStartupConfiguration configuration;
  final GichoStartupLabels labels;
  final Future<T> Function(StartupProgress) load;
  final Widget Function(BuildContext, T) readyBuilder;
  final List<StartupJob> jobs;
  final DateTime? startupDate;
  final Future<String?> Function()? countryResolver;
  final Uri? origin;

  @override
  State<GichoStartup<T>> createState() => _GichoStartupState<T>();
}

class _GichoStartupState<T> extends State<GichoStartup<T>> {
  late final DateTime _localDate = widget.startupDate ?? DateTime.now();
  String? _countryCode;

  Future<void> _resolveCountry() async {
    if (!widget.configuration.needsCountryFor(_localDate)) {
      return;
    }
    try {
      final custom = widget.countryResolver;
      final origin = widget.origin;
      final path = widget.configuration.countryLookupPath;
      if (custom != null) {
        _countryCode = (await custom())?.toUpperCase();
      } else if (origin != null && path != null) {
        _countryCode = await const GichoStartupNetworkCountry().resolve(
          origin: origin,
          path: path,
        );
      }
    } catch (_) {
      // Unknown location selects the configured default scene.
    }
  }

  @override
  Widget build(BuildContext context) {
    final configuration = widget.configuration;
    final labels = widget.labels;
    return StartupSequence<T>(
      scenes: [
        StartupScene(
          minimumDuration: configuration.companyMinimum,
          prepare: _resolveCountry,
          builder: (context) => SplashScene(
            title: labels.company,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            artworkAsset: configuration.companyArtworkAsset,
            portraitSceneAsset: configuration.companyPortraitSceneAsset,
            landscapeSceneAsset: configuration.companyLandscapeSceneAsset,
          ),
        ),
        StartupScene(
          minimumDuration: configuration.productMinimum,
          builder: (_) => SplashScene(
            title: labels.product,
            artworkAsset: configuration.productArtworkAsset,
            portraitSceneAsset: configuration
                .productSceneFor(_localDate, countryCode: _countryCode)
                .portrait,
            landscapeSceneAsset: configuration
                .productSceneFor(_localDate, countryCode: _countryCode)
                .landscape,
          ),
        ),
      ],
      jobs: widget.jobs,
      loadLabel: labels.loading,
      load: widget.load,
      minimumLoadingDuration: configuration.loadingMinimum,
      transitionDuration: configuration.transitionDuration,
      transition: configuration.transition,
      loadingBuilder: (_, progress) => SplashScene(
        title: labels.product,
        artworkAsset:
            configuration.loadingArtworkAsset ??
            configuration.productArtworkAsset,
        portraitSceneAsset:
            configuration.loadingPortraitSceneAsset ??
            configuration
                .productSceneFor(_localDate, countryCode: _countryCode)
                .portrait,
        landscapeSceneAsset:
            configuration.loadingLandscapeSceneAsset ??
            configuration
                .productSceneFor(_localDate, countryCode: _countryCode)
                .landscape,
        panel: Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(labels.loading),
                  const SizedBox(height: 16),
                  for (final id in progress.ids) ...[
                    Row(
                      children: [
                        Icon(
                          progress.status(id) == StartupJobStatus.complete
                              ? Icons.check_circle
                              : Icons.pending_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(progress.label(id))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value:
                          progress.status(id) == StartupJobStatus.running &&
                              progress.fraction(id) == 0
                          ? null
                          : progress.fraction(id),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      errorBuilder: (_, _, retry) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(labels.failed),
              TextButton(onPressed: retry, child: Text(labels.retry)),
            ],
          ),
        ),
      ),
      readyBuilder: widget.readyBuilder,
    );
  }
}
