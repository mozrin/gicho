import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('consumer router uses Gicho locale and theme setup', (
    tester,
  ) async {
    final locales = GichoLocaleController();
    final router = RouterConfig<Object>(routerDelegate: _ExampleRouter());
    addTearDown(locales.dispose);

    await tester.pumpWidget(
      GichoMaterialApp.router(
        locales: locales,
        title: () => 'Router example',
        theme: gichoTheme(seedColor: Colors.teal),
        routerConfig: router,
      ),
    );

    expect(find.text('Router content'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
      same(router),
    );
  });
}

class _ExampleRouter extends RouterDelegate<Object> with ChangeNotifier {
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Router content')));

  @override
  Future<bool> popRoute() async => false;

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}
