import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes generic app-link and browser-launch primitives', () {
    expect(AppLinks(), isA<AppLinks>());
    expect(LaunchMode.externalApplication, isA<LaunchMode>());
  });
}
