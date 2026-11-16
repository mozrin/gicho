import 'package:gicho_scanner_example/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offers two meanings and Back cancels the scanner', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('Scan employee QR'), findsOneWidget);
    expect(find.text('Scan menu QR'), findsOneWidget);

    await tester.tap(find.text('Scan employee QR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Point the camera at an employee QR code.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Scan menu QR'), findsOneWidget);
  });

  for (final width in [390.0, 834.0, 1440.0]) {
    testWidgets('scanner fits a $width logical-pixel viewport', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Scan menu QR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Point the camera at a menu QR code.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
