import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gicho/gicho.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'Google adapter keeps one session through suggestions and resolution',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'suggestions': [
                {
                  'placePrediction': {
                    'placeId': 'sample-city',
                    'text': {'text': 'Bangkok'},
                    'structuredFormat': {
                      'mainText': {'text': 'Bangkok'},
                    },
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'id': 'sample-city',
            'displayName': {'text': 'Bangkok'},
            'location': {'latitude': 13.7563, 'longitude': 100.5018},
          }),
          200,
        );
      });
      final provider = GooglePlaceLookupProvider(
        apiKey: 'development-test-key',
        client: client,
      );
      final first = await provider.suggest('Bang');
      final second = await provider.suggest('Bangk');
      expect(first.single.sessionId, second.single.sessionId);
      final place = await provider.resolve(second.single);
      expect(place.label, 'Bangkok');
      expect(place.latitude, 13.7563);
      expect(
        requests.last.url.queryParameters['sessionToken'],
        first.single.sessionId,
      );
      expect(
        requests.every(
          (request) =>
              request.headers['x-goog-api-key'] == 'development-test-key',
        ),
        isTrue,
      );
      final next = await provider.suggest('Bangkok');
      expect(next.single.sessionId, isNot(first.single.sessionId));
      provider.close();
    },
  );

  test(
    'Google adapter surfaces service failure and rejects missing configuration',
    () async {
      expect(() => GooglePlaceLookupProvider(apiKey: ''), throwsArgumentError);
      final provider = GooglePlaceLookupProvider(
        apiKey: 'development-test-key',
        client: MockClient((_) async => http.Response('rate limited', 429)),
      );
      await expectLater(provider.suggest('Bangkok'), throwsStateError);
      provider.close();
    },
  );
}
