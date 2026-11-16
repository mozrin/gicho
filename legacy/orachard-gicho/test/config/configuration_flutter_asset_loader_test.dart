import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('does not request an optional asset absent from the manifest', () async {
    final bundle = _ManifestBundle({'present.yaml': 'value: present'});
    final loader = FlutterAssetConfigurationLoader(bundle: bundle);

    expect(await loader.load('missing.yaml', optional: true), isNull);
    expect(bundle.requests, ['AssetManifest.bin']);
  });

  test('loads an optional asset present in the manifest', () async {
    final bundle = _ManifestBundle({'present.yaml': 'value: present'});
    final loader = FlutterAssetConfigurationLoader(bundle: bundle);

    expect(await loader.load('present.yaml', optional: true), 'value: present');
    expect(bundle.requests, ['AssetManifest.bin', 'present.yaml']);
  });
}

class _ManifestBundle extends CachingAssetBundle {
  _ManifestBundle(this.assets);

  final Map<String, String> assets;
  final List<String> requests = [];

  @override
  Future<ByteData> load(String key) async {
    requests.add(key);
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final key in assets.keys)
          key: [
            {'asset': key},
          ],
      })!;
    }
    final value = assets[key];
    if (value == null) throw FlutterError('Missing asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}
