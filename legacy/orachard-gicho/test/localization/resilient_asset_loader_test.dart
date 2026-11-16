import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('missing catalogs degrade to an empty translation map', () async {
    Object? reportedError;
    final loader = ResilientAssetLoader(
      const _FailingLoader(),
      onError: (error, _, _, _) => reportedError = error,
    );

    final catalog = await loader.load('assets/gicho', const Locale('en'));

    expect(catalog, isEmpty);
    expect(reportedError, isA<StateError>());
  });
}

class _FailingLoader extends AssetLoader {
  const _FailingLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    throw StateError('Catalog unavailable');
  }
}
