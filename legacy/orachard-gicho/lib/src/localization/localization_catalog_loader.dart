import 'package:material_ui/material_ui.dart';
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

/// A fatal or recoverable failure while resolving translation catalogs.
final class LocalizationException implements Exception {
  const LocalizationException(this.message, {this.location, this.cause});

  final String message;
  final String? location;
  final Object? cause;

  @override
  String toString() {
    final at = location == null ? '' : ' at $location';
    final because = cause == null ? '' : ': $cause';
    return 'LocalizationException$at: $message$because';
  }
}

typedef LocalizationCatalogError =
    void Function(Object error, StackTrace stackTrace, Locale locale);

typedef LocalizationCatalogWarning =
    FutureOr<void> Function(String message, Locale locale);

/// Package-owned display metadata for a supported language.
final class LocalizationLanguage {
  const LocalizationLanguage({
    required this.locale,
    required this.label,
    required this.names,
  });

  final Locale locale;
  final String label;
  final Map<String, String> names;

  /// Returns this language's name translated into [displayLocale].
  String nameIn(Locale displayLocale, {Locale fallback = const Locale('en')}) {
    return names[displayLocale.languageCode] ??
        names[fallback.languageCode] ??
        locale.languageCode;
  }
}

/// A replaceable source of locale-keyed translation catalogs.
abstract interface class LocalizationCatalogSource {
  Future<Map<String, dynamic>?> load(Locale locale);
}

/// Loads bundled JSON catalogs from Flutter assets.
final class AssetLocalizationCatalogSource
    implements LocalizationCatalogSource {
  const AssetLocalizationCatalogSource({this.bundle});

  static const assetDirectory = 'assets/gicho';
  final AssetBundle? bundle;

  String location(Locale locale) =>
      '$assetDirectory/${locale.languageCode}.json';

  /// Discovers app-enabled locales from bundled JSON filenames.
  Future<List<Locale>> discoverLocales() async {
    final manifest = await AssetManifest.loadFromAssetBundle(
      bundle ?? rootBundle,
    );
    const prefix = '$assetDirectory/';
    final locales = <Locale>[];
    for (final asset in manifest.listAssets()) {
      if (!asset.startsWith(prefix) || !asset.endsWith('.json')) continue;
      final filename = asset.substring(prefix.length);
      if (filename.contains('/')) continue;
      final code = filename.substring(0, filename.length - 5);
      if (RegExp(r'^[a-z]{2,3}$').hasMatch(code)) {
        locales.add(Locale(code));
      }
    }
    locales.sort(
      (left, right) => left.languageCode.compareTo(right.languageCode),
    );
    return List.unmodifiable(locales);
  }

  @override
  Future<Map<String, dynamic>?> load(Locale locale) async {
    final asset = location(locale);
    String source;
    try {
      source = await (bundle ?? rootBundle).loadString(asset);
    } on FlutterError {
      return null;
    }
    return _decodeCatalog(source, asset);
  }
}

/// Loads public JSON catalogs from a GitHub repository's raw endpoint.
final class GitLocalizationCatalogSource implements LocalizationCatalogSource {
  GitLocalizationCatalogSource({
    required this.repository,
    required this.path,
    required this.reference,
    Dio? client,
  }) : _client = client ?? Dio();

  final Uri repository;
  final String path;
  final String reference;
  final Dio _client;

  Uri location(Locale locale) {
    final segments = repository.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    if (repository.scheme != 'https' ||
        repository.host != 'github.com' ||
        segments.length != 2) {
      throw LocalizationException(
        'Remote Git source requires an HTTPS GitHub repository URL.',
        location: repository.toString(),
      );
    }
    final owner = segments.first;
    final repositoryName = segments.last.replaceFirst(RegExp(r'\.git$'), '');
    final remotePath = path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return Uri.parse(
      'https://raw.githubusercontent.com/'
      '${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repositoryName)}/'
      '${Uri.encodeComponent(reference)}/$remotePath/'
      '${Uri.encodeComponent(locale.languageCode)}.json',
    );
  }

  @override
  Future<Map<String, dynamic>?> load(Locale locale) async {
    final uri = location(locale);
    try {
      final response = await _client.get<String>(
        uri.toString(),
        options: Options(responseType: ResponseType.plain),
      );
      final source = response.data;
      if (source == null) return null;
      return _decodeCatalog(source, uri.toString());
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

/// Combines mandatory bundled catalogs with optional remote updates.
final class TieredLocalizationCatalogLoader extends AssetLoader {
  TieredLocalizationCatalogLoader({
    required this.local,
    required this.fallbackLocale,
    this.systemCatalogs = const {},
    this.remote,
    this.onRemoteError,
    this.onFallbackMissing,
  });

  final LocalizationCatalogSource local;
  final Map<String, Map<String, dynamic>> systemCatalogs;
  final LocalizationCatalogSource? remote;
  final Locale fallbackLocale;
  final LocalizationCatalogError? onRemoteError;
  final LocalizationCatalogWarning? onFallbackMissing;

  final Map<String, Future<Map<String, dynamic>?>> _localLoads = {};
  final Map<String, Future<Map<String, dynamic>?>> _remoteLoads = {};
  final Map<String, Map<String, dynamic>> _remoteCatalogs = {};

  /// Whether at least one configured remote catalog has been downloaded.
  bool get hasRemoteCatalogs => _remoteCatalogs.isNotEmpty;

  /// Checks whether the offline fallback catalog exists.
  ///
  /// A missing or empty catalog is valid. Missing catalogs produce a warning
  /// and resolve to an empty map so untranslated values remain visible as
  /// their keys.
  Future<void> validateFallback() async {
    final catalog = await _loadLocal(fallbackLocale);
    if (catalog == null) {
      final location = local is AssetLocalizationCatalogSource
          ? (local as AssetLocalizationCatalogSource).location(fallbackLocale)
          : fallbackLocale.languageCode;
      await onFallbackMissing?.call(
        'No local fallback-language catalog was found at $location. '
        'Localization will continue with the available system translations '
        'or an empty catalog; missing translations will display their keys.',
        fallbackLocale,
      );
    }
  }

  /// Starts all configured remote requests in parallel.
  Future<void> loadRemote(Iterable<Locale> locales) async {
    if (remote == null) return;
    await Future.wait(locales.map(_loadRemote));
  }

  /// Starts remote requests without delaying the caller.
  void loadRemoteInBackground(Iterable<Locale> locales) {
    unawaited(loadRemote(locales));
  }

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final localCatalog = await _loadLocal(locale) ?? const <String, dynamic>{};
    final systemCatalog =
        systemCatalogs[locale.languageCode] ?? const <String, dynamic>{};
    final baselineCatalog = _mergeMaps(systemCatalog, localCatalog);
    final remoteCatalog = _remoteCatalogs[locale.languageCode];
    if (remoteCatalog == null) return baselineCatalog;
    return _mergeMaps(baselineCatalog, remoteCatalog);
  }

  Future<Map<String, dynamic>?> _loadLocal(Locale locale) {
    return _localLoads.putIfAbsent(
      locale.languageCode,
      () => local.load(locale),
    );
  }

  Future<Map<String, dynamic>?> _loadRemote(Locale locale) {
    return _remoteLoads.putIfAbsent(locale.languageCode, () async {
      try {
        final catalog = await remote!.load(locale);
        if (catalog != null) {
          _remoteCatalogs[locale.languageCode] = _copyMap(catalog);
        }
        return catalog;
      } catch (error, stackTrace) {
        onRemoteError?.call(error, stackTrace, locale);
        return null;
      }
    });
  }
}

Map<String, dynamic> _decodeCatalog(String source, String location) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The catalog root must be an object.');
    }
    return decoded;
  } catch (error) {
    throw LocalizationException(
      'Unable to decode the translation catalog',
      location: location,
      cause: error,
    );
  }
}

Map<String, dynamic> _mergeMaps(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  final result = _copyMap(local);
  for (final entry in remote.entries) {
    final localValue = result[entry.key];
    final remoteValue = entry.value;
    result[entry.key] =
        localValue is Map<String, dynamic> &&
            remoteValue is Map<String, dynamic>
        ? _mergeMaps(localValue, remoteValue)
        : _copyValue(remoteValue);
  }
  return result;
}

Map<String, dynamic> _copyMap(Map<String, dynamic> value) =>
    value.map((key, item) => MapEntry(key, _copyValue(item)));

Object? _copyValue(Object? value) {
  if (value is Map<String, dynamic>) return _copyMap(value);
  if (value is List) return value.map(_copyValue).toList();
  return value;
}
