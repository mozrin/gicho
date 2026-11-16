import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows one title and returns to the invoking route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GichoModalPage(
                  title: 'Scan code',
                  backLabel: 'Back to memberships',
                  body: Text('Camera'),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Scan code'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to memberships'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('uses an app-provided return for a root modal page', (
    tester,
  ) async {
    var returned = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GichoModalPage(
          title: 'Details',
          backLabel: 'Back',
          onBack: () => returned = true,
          body: const Text('Content'),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Back'));
    expect(returned, isTrue);
  });

  testWidgets('hides Back for a guided entry page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GichoModalPage(
          title: 'Choose provider',
          showBackButton: false,
          body: Text('Provider options'),
        ),
      ),
    );

    expect(find.text('Choose provider'), findsOneWidget);
    expect(find.text('Provider options'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('keeps title and Back usable with large text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: GichoModalPage(title: 'About', body: Text('Information')),
        ),
      ),
    );

    expect(find.text('About'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the same compact brand in a modal app bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GichoModalPage(
          title: 'About',
          brand: GichoBrand(name: 'Example'),
          body: Text('Details'),
        ),
      ),
    );

    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
