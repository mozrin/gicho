import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  testWidgets('uses only the scaffold regions supplied by the consumer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GichoPageShell(body: Text('Consumer body'))),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(find.text('Consumer body'), findsOneWidget);
    expect(scaffold.appBar, isNull);
    expect(scaffold.drawer, isNull);
    expect(scaffold.bottomNavigationBar, isNull);
  });

  testWidgets('passes supplied regions through to Flutter Scaffold', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GichoPageShell(
          appBar: AppBar(title: const Text('Title')),
          drawer: const Drawer(child: Text('Drawer')),
          bottomNavigationBar: const Text('Footer'),
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
          ),
          body: const Text('Consumer body'),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(find.text('Title'), findsOneWidget);
    expect(scaffold.drawer, isNotNull);
    expect(scaffold.bottomNavigationBar, isNotNull);
    expect(scaffold.floatingActionButton, isNotNull);
  });
}
