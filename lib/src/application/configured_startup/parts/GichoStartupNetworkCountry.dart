// ignore_for_file: file_names

import 'package:http/http.dart' as http;

/// Reads the Cloudflare network-country field without retaining trace data.
class GichoStartupNetworkCountry {
  const GichoStartupNetworkCountry();

  Future<String?> resolve({
    required Uri origin,
    required String path,
    http.Client? client,
  }) async {
    if (origin.scheme != 'https' ||
        origin.host.isEmpty ||
        !path.startsWith('/') ||
        path.startsWith('//')) {
      return null;
    }
    final relative = Uri.tryParse(path);
    if (relative == null ||
        relative.hasAuthority ||
        relative.hasScheme ||
        relative.hasQuery ||
        relative.hasFragment) {
      return null;
    }
    final ownedClient = client == null;
    final requester = client ?? http.Client();
    try {
      final request = http.Request('GET', origin.resolveUri(relative))
        ..followRedirects = false;
      final stream = await requester
          .send(request)
          .timeout(const Duration(seconds: 3));
      if (stream.statusCode != 200) {
        return null;
      }
      final body = await stream.stream.bytesToString().timeout(
        const Duration(seconds: 3),
      );
      for (final line in body.split('\n')) {
        if (!line.startsWith('loc=')) {
          continue;
        }
        final country = line.substring(4).trim();
        if (RegExp(r'^[A-Z]{2}$').hasMatch(country) && country != 'XX') {
          return country;
        }
        return null;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      if (ownedClient) {
        requester.close();
      }
    }
  }
}
