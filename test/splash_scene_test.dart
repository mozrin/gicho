import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gicho/gicho.dart';

class _SceneAssetBundle extends CachingAssetBundle {
  static final Future<ByteData> _pixel = _createPixel();

  static Future<ByteData> _createPixel() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(Colors.red, BlendMode.src);
    final image = await recorder.endRecording().toImage(1, 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!;
  }

  @override
  Future<ByteData> load(String key) => _pixel;
}

void main() {
  for (final (width, height, expected) in [
    (390.0, 844.0, 'portrait.png'),
    (834.0, 1112.0, 'landscape.png'),
    (1440.0, 900.0, 'landscape.png'),
  ]) {
    testWidgets('scene uses $expected at $width logical pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _SceneAssetBundle(),
          child: const MaterialApp(
            home: SplashScene(
              title: 'Harmony',
              portraitSceneAsset: 'portrait.png',
              landscapeSceneAsset: 'landscape.png',
              panel: Text('Initializing'),
            ),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, expected);
      expect(image.fit, BoxFit.cover);
      expect(find.text('Harmony'), findsOneWidget);
      expect(find.text('Initializing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
