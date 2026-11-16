import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GichoPhotoFlow', () {
    test('normalizes a real device selection and logs its lifecycle', () async {
      final logs = <String>[];
      final flow = GichoPhotoFlow(
        cameraGateway: _FakeCameraGateway(supported: false),
        picker: _FakePicker(
          selected: GichoRawPhoto(
            bytes: _jpeg(80, 100),
            name: 'portrait.jpeg',
            mimeType: 'image/jpeg',
            source: GichoPhotoSource.device,
          ),
        ),
        normalizer: const GichoPhotoNormalizer(),
        logSink: logs.add,
      );

      final photo = await flow.chooseFromDevice();

      expect(photo, isNotNull);
      expect(photo!.mimeType, 'image/jpeg');
      expect(photo.name, 'portrait.jpeg');
      expect(photo.width, 80);
      expect(photo.height, 100);
      expect(photo.source, GichoPhotoSource.device);
      expect(photo.isCropped, isFalse);
      expect(logs.first, contains('selection started'));
      expect(logs.last, contains('selection completed'));
    });

    test(
      'bounds an oversized source before it reaches the crop page',
      () async {
        final flow = GichoPhotoFlow(
          cameraGateway: _FakeCameraGateway(supported: false),
          picker: _FakePicker(
            selected: GichoRawPhoto(
              bytes: _jpeg(120, 60),
              name: 'large-landscape.jpeg',
              mimeType: 'image/jpeg',
              source: GichoPhotoSource.device,
            ),
          ),
          normalizer: const GichoPhotoNormalizer(maximumDimension: 80),
          logSink: (_) {},
        );

        final photo = await flow.chooseFromDevice();

        expect(photo, isNotNull);
        expect(photo!.width, 80);
        expect(photo.height, 40);
        expect(photo.isCropped, isFalse);
      },
    );

    test('returns null when device selection is cancelled', () async {
      final logs = <String>[];
      final flow = GichoPhotoFlow(
        cameraGateway: _FakeCameraGateway(supported: false),
        picker: _FakePicker(),
        normalizer: const GichoPhotoNormalizer(),
        logSink: logs.add,
      );

      expect(await flow.chooseFromDevice(), isNull);
      expect(logs.last, contains('cancelled'));
    });

    test('keeps invalid image bytes as a typed decode failure', () async {
      final flow = GichoPhotoFlow(
        cameraGateway: _FakeCameraGateway(supported: false),
        picker: _FakePicker(
          selected: GichoRawPhoto(
            bytes: Uint8List.fromList([1, 2, 3]),
            name: 'invalid.jpeg',
            mimeType: 'image/jpeg',
            source: GichoPhotoSource.device,
          ),
        ),
        normalizer: const GichoPhotoNormalizer(),
        logSink: (_) {},
      );

      await expectLater(
        flow.chooseFromDevice(),
        throwsA(
          isA<GichoPhotoException>().having(
            (error) => error.kind,
            'kind',
            GichoPhotoFailureKind.decodeFailed,
          ),
        ),
      );
    });

    test('reports an unsupported camera without invoking discovery', () async {
      final gateway = _FakeCameraGateway(supported: false);
      final flow = GichoPhotoFlow(
        cameraGateway: gateway,
        picker: _FakePicker(),
        normalizer: const GichoPhotoNormalizer(),
        logSink: (_) {},
      );

      final capability = await flow.inspectCameraCapability();

      expect(capability.state, GichoCameraCapabilityState.unsupported);
      expect(capability.isAvailable, isFalse);
      expect(gateway.discoveryCount, 0);
    });

    test('keeps camera permission denial typed', () async {
      final flow = GichoPhotoFlow(
        cameraGateway: _FakeCameraGateway(
          failure: const GichoPhotoException(
            GichoPhotoFailureKind.permissionPermanentlyDenied,
          ),
        ),
        picker: _FakePicker(),
        normalizer: const GichoPhotoNormalizer(),
        logSink: (_) {},
      );

      final capability = await flow.inspectCameraCapability();

      expect(
        capability.state,
        GichoCameraCapabilityState.permissionPermanentlyDenied,
      );
      expect(
        capability.failure?.kind,
        GichoPhotoFailureKind.permissionPermanentlyDenied,
      );
    });

    test('returns discovered cameras as an available capability', () async {
      final flow = GichoPhotoFlow(
        cameraGateway: _FakeCameraGateway(
          devices: const [
            GichoCameraDevice(
              id: 'front',
              label: 'Front camera',
              lens: GichoCameraLens.front,
            ),
          ],
        ),
        picker: _FakePicker(),
        normalizer: const GichoPhotoNormalizer(),
        logSink: (_) {},
      );

      final capability = await flow.inspectCameraCapability();

      expect(capability.state, GichoCameraCapabilityState.available);
      expect(capability.isAvailable, isTrue);
      expect(capability.devices.single.lens, GichoCameraLens.front);
    });

    test(
      'recovers and normalizes interrupted Android selection data',
      () async {
        final flow = GichoPhotoFlow(
          cameraGateway: _FakeCameraGateway(supported: false),
          picker: _FakePicker(
            recovered: GichoRawPhoto(
              bytes: _jpeg(60, 75),
              name: 'recovered.jpeg',
              source: GichoPhotoSource.device,
            ),
          ),
          normalizer: const GichoPhotoNormalizer(),
          logSink: (_) {},
        );

        final recovered = await flow.recoverLostPhoto();

        expect(recovered, isNotNull);
        expect(recovered!.width, 60);
        expect(recovered.height, 75);
      },
    );
  });
}

class _FakePicker implements GichoPhotoPickerAdapter {
  _FakePicker({this.selected, this.recovered});

  final GichoRawPhoto? selected;
  final GichoRawPhoto? recovered;

  @override
  Future<GichoRawPhoto?> chooseFromDevice() async => selected;

  @override
  Future<GichoRawPhoto?> recoverLostPhoto() async => recovered;
}

class _FakeCameraGateway implements GichoCameraGateway {
  _FakeCameraGateway({
    this.supported = true,
    this.failure,
    this.devices = const [],
  });

  final bool supported;
  final GichoPhotoException? failure;
  final List<GichoCameraDevice> devices;
  int discoveryCount = 0;

  @override
  bool get isSupportedPlatform => supported;

  @override
  Future<List<GichoCameraDevice>> discoverCameras() async {
    discoveryCount += 1;
    if (failure != null) throw failure!;
    return devices;
  }

  @override
  Future<GichoCameraSession> openCamera(GichoCameraDevice device) =>
      throw UnimplementedError();
}

Uint8List _jpeg(int width, int height) => Uint8List.fromList(
  image.encodeJpg(image.Image(width: width, height: height)),
);
