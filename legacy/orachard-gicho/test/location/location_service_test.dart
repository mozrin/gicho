import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  group('GichoLocationService', () {
    test('returns coordinates from the platform-neutral gateway', () async {
      final gateway = _FakeGateway(
        result: const GichoCoordinates(
          latitude: 13.7563,
          longitude: 100.5018,
        ),
      );
      final messages = <String>[];
      final service = GichoLocationService(
        gateway: gateway,
        logSink: messages.add,
      );

      final result = await service.current(
        request: const GichoLocationRequest(
          accuracy: GichoLocationAccuracy.low,
        ),
      );

      expect(result.latitude, 13.7563);
      expect(result.longitude, 100.5018);
      expect(gateway.lastRequest?.accuracy, GichoLocationAccuracy.low);
      expect(messages, [
        'Location acquisition requested',
        'Location acquisition completed',
      ]);
    });

    test('preserves typed failures without logging coordinates', () async {
      final messages = <String>[];
      final service = GichoLocationService(
        gateway: _FakeGateway(
          error: const GichoLocationException(
            GichoLocationFailureKind.permissionDenied,
          ),
        ),
        logSink: messages.add,
      );

      await expectLater(
        service.current(),
        throwsA(
          isA<GichoLocationException>().having(
            (error) => error.kind,
            'kind',
            GichoLocationFailureKind.permissionDenied,
          ),
        ),
      );
      expect(messages.last, 'Location acquisition failed: permissionDenied');
    });
  });
}

final class _FakeGateway implements GichoLocationGateway {
  _FakeGateway({this.result, this.error});

  final GichoCoordinates? result;
  final GichoLocationException? error;
  GichoLocationRequest? lastRequest;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<GichoCoordinates> current(GichoLocationRequest request) async {
    lastRequest = request;
    if (error case final value?) throw value;
    return result!;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
