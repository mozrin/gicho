import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes Flutter SVG through the Gicho public library', () {
    final picture = SvgPicture.string(
      '<svg viewBox="0 0 1 1"><path d="M0 0h1v1H0z"/></svg>',
    );

    expect(picture, isA<SvgPicture>());
  });
}
