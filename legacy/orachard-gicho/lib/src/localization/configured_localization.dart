import 'package:material_ui/material_ui.dart';
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../config/configuration_document.dart';
import '../config/configuration_exception.dart';
import '../config/configuration_registry.dart';
import '../config/configuration_service.dart';
import '../logging/configured_logging.dart';
import 'localization_catalog_loader.dart';
import 'localization_language_registry.dart';

enum LocalizationRemoteLoadMode { background, blocking }

enum LocalizationLocalSource { assets }

enum LocalizationRemoteSource { git }

/// Localization metadata supplied by the configured instance around the app.
final class MoztopiaLocalizationScope extends InheritedWidget {
  const MoztopiaLocalizationScope({
    required this.configuration,
    required this.languages,
    required super.child,
    super.key,
  });

  final LocalizationConfiguration configuration;
  final List<LocalizationLanguage> languages;

  static MoztopiaLocalizationScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MoztopiaLocalizationScope>();
    if (scope == null) {
      throw StateError(
        'No MoztopiaLocalizationScope exists above this context.',
      );
    }
    return scope;
  }

  @override
  bool updateShouldNotify(MoztopiaLocalizationScope oldWidget) =>
      configuration != oldWidget.configuration ||
      languages != oldWidget.languages;
}

/// Validated settings resolved from `localization.config.yaml`.
final class LocalizationConfiguration {
  const LocalizationConfiguration({
    required this.fallbackLanguage,
    required this.localSource,
    required this.remoteEnabled,
    required this.remoteSource,
    required this.remoteLoadMode,
    required this.remoteRepository,
    required this.remotePath,
    required this.remoteReference,
  });

  factory LocalizationConfiguration.fromDocument(
    ConfigurationDocument document,
  ) {
    final remoteLoadMode = switch (document.require<String>('remoteLoadMode')) {
      'background' => LocalizationRemoteLoadMode.background,
      'blocking' => LocalizationRemoteLoadMode.blocking,
      final value => throw StateError('Unsupported remote load mode: $value'),
    };
    final localSource = switch (document.require<String>('localSource')) {
      'assets' => LocalizationLocalSource.assets,
      final value => throw StateError('Unsupported local source: $value'),
    };
    final remoteSource = switch (document.require<String>('remoteSource')) {
      'git' => LocalizationRemoteSource.git,
      final value => throw StateError('Unsupported remote source: $value'),
    };
    final remoteEnabled = document.require<bool>('remoteEnabled');
    final remoteRepository = document.value('remoteRepository');
    final remotePath = document.value('remotePath');
    if (remoteEnabled &&
        (remoteRepository is! String || remotePath is! String)) {
      throw ConfigurationException(
        'remoteRepository and remotePath are required when remote loading is enabled.',
        location: ConfigurationService.appConfigAsset('localization'),
      );
    }

    final fallbackLanguage = Locale(
      document.require<String>('fallbackLanguage'),
    );

    return LocalizationConfiguration(
      fallbackLanguage: fallbackLanguage,
      localSource: localSource,
      remoteEnabled: remoteEnabled,
      remoteSource: remoteSource,
      remoteLoadMode: remoteLoadMode,
      remoteRepository: remoteRepository is String
          ? Uri.parse(remoteRepository)
          : null,
      remotePath: remotePath is String ? remotePath : null,
      remoteReference: document.require<String>('remoteReference'),
    );
  }

  final Locale fallbackLanguage;
  final LocalizationLocalSource localSource;
  final bool remoteEnabled;
  final LocalizationRemoteSource remoteSource;
  final LocalizationRemoteLoadMode remoteLoadMode;
  final Uri? remoteRepository;
  final String? remotePath;
  final String remoteReference;
}

/// Creates Easy Localization using package defaults and app overrides.
final class MoztopiaLocalization {
  MoztopiaLocalization({
    ConfigurationService? configurationService,
    ConfigurationRegistry? configurationRegistry,
  }) : assert(
         configurationService == null || configurationRegistry == null,
         'Provide either configurationService or configurationRegistry.',
       ),
       _configurationService = configurationService,
       _configurationRegistry =
           configurationRegistry ??
           (configurationService == null ? moztopiaConfig : null);

  final ConfigurationService? _configurationService;
  final ConfigurationRegistry? _configurationRegistry;
  Future<LocalizationConfiguration>? _initialization;
  Future<_LocalizationRuntime>? _runtimeInitialization;
  LocalizationConfiguration? _configuration;
  List<LocalizationLanguage>? _languages;

  Future<LocalizationConfiguration> initialize() =>
      _initialization ??= _loadConfiguration();

  LocalizationConfiguration get configuration =>
      _configuration ??
      (throw StateError('Moztopia localization has not been initialized.'));

  /// Languages declared by the required bundled English catalog.
  List<LocalizationLanguage> get languages =>
      _languages ??
      (throw StateError('Moztopia localization has not been created.'));

  /// Builds localization from required local and optional remote catalogs.
  Future<EasyLocalization> create({
    required Widget child,
    bool useOnlyLangCode = false,
    bool ignorePluralRules = true,
    bool saveLocale = true,
  }) async {
    final runtime = await (_runtimeInitialization ??= _prepareRuntime());

    return EasyLocalization(
      supportedLocales: runtime.supportedLocales,
      path: AssetLocalizationCatalogSource.assetDirectory,
      fallbackLocale: runtime.settings.fallbackLanguage,
      useOnlyLangCode: useOnlyLangCode,
      useFallbackTranslations: true,
      useFallbackTranslationsForEmptyResources: true,
      ignorePluralRules: ignorePluralRules,
      saveLocale: saveLocale,
      assetLoader: runtime.loader,
      child: MoztopiaLocalizationScope(
        configuration: runtime.settings,
        languages: languages,
        child: runtime.backgroundRemoteLoad == null
            ? child
            : _BackgroundLocalizationRefresh(
                remoteLoad: runtime.backgroundRemoteLoad!,
                loader: runtime.loader,
                child: child,
              ),
      ),
    );
  }

  Future<_LocalizationRuntime> _prepareRuntime() async {
    final settings = await initialize();
    const localSource = AssetLocalizationCatalogSource();
    final loader = TieredLocalizationCatalogLoader(
      local: localSource,
      fallbackLocale: settings.fallbackLanguage,
      remote: settings.remoteEnabled
          ? GitLocalizationCatalogSource(
              repository: settings.remoteRepository!,
              path: settings.remotePath!,
              reference: settings.remoteReference,
            )
          : null,
      onRemoteError: (error, _, locale) {
        EasyLocalization.logger.warning(
          'Unable to load remote ${locale.languageCode} translations: $error',
        );
      },
      onFallbackMissing: (message, _) => moztopiaLog.warn(message),
    );

    final registryLoad = LocalizationLanguageRegistry.load();
    final localeDiscovery = localSource.discoverLocales();
    final fallbackValidation = loader.validateFallback();
    final fallbackRemoteLoad = loader.loadRemote([settings.fallbackLanguage]);
    final registry = await registryLoad;
    final discoveredLocales = await localeDiscovery;
    await fallbackValidation;
    final languagesByCode = {
      for (final language in registry.languages)
        language.locale.languageCode: language,
    };
    final unknownCodes = discoveredLocales
        .map((locale) => locale.languageCode)
        .where((code) => !languagesByCode.containsKey(code))
        .toList();
    if (unknownCodes.isNotEmpty) {
      throw LocalizationException(
        'Bundled catalogs use languages missing from the package registry: '
        '${unknownCodes.join(', ')}.',
        location: AssetLocalizationCatalogSource.assetDirectory,
      );
    }
    final enabledLanguageCodes = {
      settings.fallbackLanguage.languageCode,
      for (final locale in discoveredLocales) locale.languageCode,
    };
    _languages = [
      for (final language in registry.languages)
        if (enabledLanguageCodes.contains(language.locale.languageCode))
          language,
    ];
    final supportedLocales = [
      for (final language in _languages!) language.locale,
    ];
    final remoteLoad = Future.wait([
      fallbackRemoteLoad,
      loader.loadRemote(supportedLocales),
    ]);
    Future<void>? backgroundRemoteLoad;
    if (settings.remoteLoadMode == LocalizationRemoteLoadMode.blocking) {
      await remoteLoad;
    } else {
      backgroundRemoteLoad = remoteLoad;
    }

    return _LocalizationRuntime(
      settings: settings,
      supportedLocales: supportedLocales,
      loader: loader,
      backgroundRemoteLoad: backgroundRemoteLoad,
    );
  }

  Future<LocalizationConfiguration> _loadConfiguration() async {
    final document =
        await (_configurationRegistry?.loadFeature('localization') ??
            _configurationService!.loadFeature('localization'));
    return _configuration = LocalizationConfiguration.fromDocument(document);
  }
}

final class _LocalizationRuntime {
  const _LocalizationRuntime({
    required this.settings,
    required this.supportedLocales,
    required this.loader,
    required this.backgroundRemoteLoad,
  });

  final LocalizationConfiguration settings;
  final List<Locale> supportedLocales;
  final TieredLocalizationCatalogLoader loader;
  final Future<void>? backgroundRemoteLoad;
}

/// Reloads Easy Localization once background catalogs are available.
///
/// The tiered loader receives remote data after Easy Localization has already
/// rendered its bundled catalog. Re-selecting the active locale makes the
/// controller request the now-merged catalog and notify its dependants.
final class _BackgroundLocalizationRefresh extends StatefulWidget {
  const _BackgroundLocalizationRefresh({
    required this.remoteLoad,
    required this.loader,
    required this.child,
  });

  final Future<void> remoteLoad;
  final TieredLocalizationCatalogLoader loader;
  final Widget child;

  @override
  State<_BackgroundLocalizationRefresh> createState() =>
      _BackgroundLocalizationRefreshState();
}

final class _BackgroundLocalizationRefreshState
    extends State<_BackgroundLocalizationRefresh> {
  @override
  void initState() {
    super.initState();
    unawaited(_applyRemoteCatalogs());
  }

  Future<void> _applyRemoteCatalogs() async {
    await widget.remoteLoad;
    if (!widget.loader.hasRemoteCatalogs) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final locale = context.locale;
    await context.setLocale(locale);
    await moztopiaLog.info(
      'Background localization catalogs applied for $locale',
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final moztopiaLocalization = MoztopiaLocalization();
