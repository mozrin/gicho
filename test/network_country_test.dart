import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gicho/src/application/configured_startup/parts/GichoStartupNetworkCountry.dart';

void main() {
  const resolver = GichoStartupNetworkCountry();
  final origin = Uri.parse('https://harmony.moztopia.com');

  test('reads only the network country from same-origin trace', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://harmony.moztopia.com/cdn-cgi/trace',
      );
      expect(request.followRedirects, isFalse);
      return http.Response('ip=203.0.113.1\nloc=TH\ncolo=BKK\n', 200);
    });
    expect(
      await resolver.resolve(
        origin: origin,
        path: '/cdn-cgi/trace',
        client: client,
      ),
      'TH',
    );
  });

  test('rejects unknown country, redirects and external paths', () async {
    final unknown = MockClient((_) async => http.Response('loc=XX\n', 200));
    final redirect = MockClient((_) async => http.Response('', 302));
    expect(
      await resolver.resolve(
        origin: origin,
        path: '/cdn-cgi/trace',
        client: unknown,
      ),
      isNull,
    );
    expect(
      await resolver.resolve(
        origin: origin,
        path: '/cdn-cgi/trace',
        client: redirect,
      ),
      isNull,
    );
    expect(
      await resolver.resolve(
        origin: origin,
        path: '//elsewhere.example/trace',
        client: unknown,
      ),
      isNull,
    );
    expect(
      await resolver.resolve(
        origin: Uri.parse('http://harmony.moztopia.com'),
        path: '/cdn-cgi/trace',
        client: unknown,
      ),
      isNull,
    );
  });
}
