import 'package:flutter/material.dart';
// Focused construct tests are colocated with their public contract.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import '../../features/branding/brand/index.dart';
import 'brand_image.dart';

void main() {
  testWidgets('uses the built-in symbol when an image is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GichoBrandImage(
            brand: GichoBrand(
              name: 'Example',
              logoAsset: 'assets/missing.png',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.text('Example'), findsOneWidget);
  });

  testWidgets('compact fallback keeps the brand accessible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GichoBrandImage(
            brand: GichoBrand(name: 'Example'),
            compact: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Example'), findsOneWidget);
  });
}
