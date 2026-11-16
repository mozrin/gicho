import 'package:gicho/gicho.dart';
import 'package:gicho_place_lookup_example/app.dart';
import 'package:gicho_place_lookup_example/features/place_choice/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'keyless example searches and selects without exposing exact identity',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline demo:'), findsOneWidget);
      expect(find.byType(PlaceLookup), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Bang');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Google Maps'), findsNothing);
      await tester.tap(find.text('Bangkok'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Returned area:'), findsOneWidget);
      expect(find.text('Exact place ID returned: false'), findsOneWidget);
      expect(find.textContaining('(within 3.0 km)'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing offline privacy to zero returns the sample place identity',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlaceLookupMapScreen(configuration: {})),
        ),
      );
      await tester.pumpAndSettle();
      final slider = tester.widget<Slider>(find.byType(Slider).first);
      slider.onChanged!(0);
      await tester.pump();
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Cairo');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ListTile, 'Cairo'));
      await tester.tap(find.widgetWithText(ListTile, 'Cairo'));
      await tester.pumpAndSettle();
      expect(find.text('Exact place ID returned: true'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
