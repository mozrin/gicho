import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes Dio through the Gicho public library', () {
    final client = Dio(BaseOptions(baseUrl: 'https://example.com'));

    expect(client.options.baseUrl, 'https://example.com');
  });
}
