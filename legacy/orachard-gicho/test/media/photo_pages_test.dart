import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('camera page captures, retakes, switches, and confirms', (
    tester,
  ) async {
    final gateway = _PageCameraGateway();
    GichoPhoto? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await Navigator.of(context).push<GichoPhoto>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => GichoCameraPage(
                    gateway: gateway,
                    normalizer: const GichoPhotoNormalizer(),
                    copy: _cameraCopy,
                    aspectRatio: 4 / 5,
                    initialDevices: gateway.devices,
                    logSink: (_) {},
                  ),
                ),
              );
            },
            child: const Text('Open camera'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();
    expect(find.text('camera preview'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gicho-camera-switch')));
    await tester.pumpAndSettle();
    expect(gateway.openedDeviceIds, ['front', 'back']);

    await tester.tap(find.byKey(const ValueKey('gicho-camera-capture')));
    await _waitFor(
      tester,
      () => find
          .byKey(const ValueKey('gicho-camera-retake'))
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.byKey(const ValueKey('gicho-camera-retake')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('gicho-camera-retake')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('gicho-camera-capture')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('gicho-camera-capture')));
    await _waitFor(
      tester,
      () => find
          .byKey(const ValueKey('gicho-camera-use-photo'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.tap(find.byKey(const ValueKey('gicho-camera-use-photo')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.source, GichoPhotoSource.camera);
    expect(result!.width, 80);
    expect(result!.height, 100);
  });

  testWidgets('crop page returns new bytes with the requested aspect ratio', (
    tester,
  ) async {
    final source = GichoPhoto(
      bytes: _jpeg(400, 600),
      name: 'source.jpeg',
      mimeType: 'image/jpeg',
      width: 400,
      height: 600,
      source: GichoPhotoSource.device,
    );
    GichoPhoto? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await Navigator.of(context).push<GichoPhoto>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => GichoPhotoCropPage(
                    photo: source,
                    aspectRatio: 4 / 5,
                    copy: _cropCopy,
                    normalizer: const GichoPhotoNormalizer(),
                    logSink: (_) {},
                  ),
                ),
              );
            },
            child: const Text('Open crop'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open crop'));
    await _waitFor(tester, () {
      final finder = find.byKey(const ValueKey('gicho-photo-crop-confirm'));
      if (finder.evaluate().isEmpty) return false;
      return tester.widget<FilledButton>(finder).onPressed != null;
    });
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('gicho-photo-crop-confirm')),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('gicho-photo-crop-confirm')));
    await _waitFor(tester, () => result != null);

    expect(result, isNotNull);
    expect(result!.isCropped, isTrue);
    expect(result!.bytes, isNot(equals(source.bytes)));
    expect(result!.width * 5, result!.height * 4);
  });
}

const _cameraCopy = GichoCameraCopy(
  title: 'Camera',
  initializing: 'Initializing',
  capture: 'Capture',
  capturing: 'Capturing',
  retake: 'Retake',
  usePhoto: 'Use photo',
  switchCamera: 'Switch camera',
  retry: 'Retry',
  unavailable: 'No camera',
  unsupported: 'Camera unsupported',
  permissionDenied: 'Permission denied',
  permissionPermanentlyDenied: 'Enable camera in settings',
  restricted: 'Camera restricted',
  failure: 'Camera failed',
);

const _cropCopy = GichoPhotoCropCopy(
  title: 'Crop',
  instructions: 'Drag and zoom',
  usePhoto: 'Use photo',
  cropping: 'Cropping',
  retry: 'Retry',
  failure: 'Crop failed',
);

class _PageCameraGateway implements GichoCameraGateway {
  final devices = const [
    GichoCameraDevice(
      id: 'front',
      label: 'Front',
      lens: GichoCameraLens.front,
    ),
    GichoCameraDevice(
      id: 'back',
      label: 'Back',
      lens: GichoCameraLens.back,
    ),
  ];
  final openedDeviceIds = <String>[];

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<List<GichoCameraDevice>> discoverCameras() async => devices;

  @override
  Future<GichoCameraSession> openCamera(GichoCameraDevice device) async {
    openedDeviceIds.add(device.id);
    return _PageCameraSession();
  }
}

class _PageCameraSession implements GichoCameraSession {
  @override
  double get previewAspectRatio => 4 / 3;

  @override
  Widget buildPreview() => const ColoredBox(
    color: Colors.black,
    child: Center(child: Text('camera preview')),
  );

  @override
  Future<GichoRawPhoto> capturePhoto() async => GichoRawPhoto(
    bytes: _jpeg(80, 100),
    name: 'capture.jpeg',
    mimeType: 'image/jpeg',
    source: GichoPhotoSource.camera,
  );

  @override
  Future<void> dispose() async {}
}

Uint8List _jpeg(int width, int height) => Uint8List.fromList(
  image.encodeJpg(image.Image(width: width, height: height)),
);

Future<void> _waitFor(WidgetTester tester, bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 8));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for the expected asynchronous widget state.');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}
