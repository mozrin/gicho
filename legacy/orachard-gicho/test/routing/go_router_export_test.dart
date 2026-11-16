import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('exposes go_router through the Gicho public library', () {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox())],
    );

    expect(router, isA<RouterConfig<RouteMatchList>>());
  });
}
