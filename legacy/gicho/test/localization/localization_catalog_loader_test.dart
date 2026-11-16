import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test(
    'missing local English warns and resolves to an empty catalog',
    () async {
      String? warning;
      final loader = TieredLocalizationCatalogLoader(
        local: _MemoryCatalogSource({}),
        fallbackLocale: const Locale('en'),
        onFallbackMissing: (message, _) => warning = message,
      );

      await loader.validateFallback();
      final catalog = await loader.load('', const Locale('en'));

      expect(catalog, isEmpty);
      expect(warning, contains('No local fallback-language catalog'));
      expect(warning, contains('missing translations will display their keys'));
    },
  );

  test('missing local English retains available system keys', () async {
    final loader = TieredLocalizationCatalogLoader(
      local: _MemoryCatalogSource({}),
      fallbackLocale: const Locale('en'),
      systemCatalogs: const {
        'en': {
          'system': {'login': 'LOGIN'},
        },
      },
    );

    await loader.validateFallback();
    final catalog = await loader.load('', const Locale('en'));

    expect(catalog, {
      'system': {'login': 'LOGIN'},
    });
  });

  test('allows an empty local English catalog', () async {
    final loader = TieredLocalizationCatalogLoader(
      local: _MemoryCatalogSource({'en': {}}),
      fallbackLocale: const Locale('en'),
    );

    await loader.validateFallback();
  });

  test('remote catalogs recursively overlay bundled values', () async {
    final loader = TieredLocalizationCatalogLoader(
      local: _MemoryCatalogSource({
        'en': {
          'screen': {'title': 'Old title', 'body': 'Bundled body'},
        },
      }),
      remote: _MemoryCatalogSource({
        'en': {
          'screen': {'title': 'Updated title'},
        },
      }),
      fallbackLocale: const Locale('en'),
    );

    final remote = loader.loadRemote(const [Locale('en')]);
    await loader.validateFallback();
    await remote;
    final catalog = await loader.load('', const Locale('en'));

    expect(catalog, {
      'screen': {'title': 'Updated title', 'body': 'Bundled body'},
    });
  });

  test('all remote locale requests start in parallel', () async {
    final source = _DeferredCatalogSource();
    final loader = TieredLocalizationCatalogLoader(
      local: _MemoryCatalogSource({
        'en': {'value': 'English'},
      }),
      remote: source,
      fallbackLocale: const Locale('en'),
    );

    final loading = loader.loadRemote(const [Locale('en'), Locale('th')]);
    await Future<void>.delayed(Duration.zero);
    expect(source.requested, containsAll(['en', 'th']));

    source.completeAll();
    await loading;
  });

  test(
    'remote failure is reported and local catalog remains available',
    () async {
      Object? reported;
      final loader = TieredLocalizationCatalogLoader(
        local: _MemoryCatalogSource({
          'en': {'value': 'Bundled'},
        }),
        remote: const _FailingCatalogSource(),
        fallbackLocale: const Locale('en'),
        onRemoteError: (error, _, _) => reported = error,
      );

      await loader.loadRemote(const [Locale('en')]);
      final catalog = await loader.load('', const Locale('en'));

      expect(reported, isA<StateError>());
      expect(catalog, {'value': 'Bundled'});
    },
  );

  test('Git source creates the expected public raw URL', () {
    final source = GitLocalizationCatalogSource(
      repository: Uri.parse(
        'https://github.com/mozrin/gicho',
      ),
      path: 'example.everything',
      reference: 'main',
    );

    expect(
      source.location(const Locale('th')).toString(),
      'https://raw.githubusercontent.com/mozrin/gicho/develop/legacy/gicho-localization/example.everything/th.json',
    );
  });
}

class _MemoryCatalogSource implements LocalizationCatalogSource {
  const _MemoryCatalogSource(this.catalogs);

  final Map<String, Map<String, dynamic>> catalogs;

  @override
  Future<Map<String, dynamic>?> load(Locale locale) async =>
      catalogs[locale.languageCode];
}

class _DeferredCatalogSource implements LocalizationCatalogSource {
  final requested = <String>[];
  final _completers = <Completer<Map<String, dynamic>?>>[];

  @override
  Future<Map<String, dynamic>?> load(Locale locale) {
    requested.add(locale.languageCode);
    final completer = Completer<Map<String, dynamic>?>();
    _completers.add(completer);
    return completer.future;
  }

  void completeAll() {
    for (final completer in _completers) {
      completer.complete({'value': 'remote'});
    }
  }
}

class _FailingCatalogSource implements LocalizationCatalogSource {
  const _FailingCatalogSource();

  @override
  Future<Map<String, dynamic>?> load(Locale locale) async {
    throw StateError('Remote unavailable');
  }
}
