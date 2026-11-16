import 'package:distance_slider_example/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup demo routes between sign-in, home and retry', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Startup demo'));
    await tester.pumpAndSettle();

    expect(find.text('The app is ready for sign-in.'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.text('Simulate sign-in'));
    await tester.pumpAndSettle();
    expect(find.text('The app is ready for its home screen.'), findsOneWidget);

    await tester.tap(find.text('Restart with failure'));
    await tester.pumpAndSettle();
    expect(find.text('Startup failed'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('The app is ready for its home screen.'), findsOneWidget);
  });
}
