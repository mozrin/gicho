import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'changed increment reaches the adjacent multiple before stepping onward',
    (tester) async {
      var value = DistanceSelectorValue.finite(192);
      var increment = 1;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return DistanceSlider(
                  value: value,
                  maximumDistance: 300,
                  increment: increment,
                  allowNoLimit: false,
                  onChanged: (next) => setState(() => value = next),
                );
              },
            ),
          ),
        ),
      );
      update(() => increment = 25);
      await tester.pumpAndSettle();
      expect(value.maximumDistanceKm, 192);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      for (final expected in [200, 225, 250]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(value.maximumDistanceKm, expected);
      }
      update(() => value = DistanceSelectorValue.finite(182));
      await tester.pumpAndSettle();
      for (final expected in [175, 150, 125]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(value.maximumDistanceKm, expected);
      }
    },
  );

  testWidgets(
    'keeps track and value geometry stable while dragging and toggling',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var value = DistanceSelectorValue.finite(1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(40),
              child: StatefulBuilder(
                builder: (context, setState) => DistanceSlider(
                  value: value,
                  maximumDistance: 300,
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          ),
        ),
      );
      final slider = find.byType(Slider);
      final edit = find.byKey(
        const ValueKey<String>('distance-slider-current-value'),
      );
      final trackRect = tester.getRect(slider);
      final editRect = tester.getRect(edit);
      expect(trackRect.width, greaterThan(140));
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(value.maximumDistanceKm, greaterThan(1));
      final remembered = value;
      expect(tester.getRect(slider), trackRect);
      expect(tester.getRect(edit), editRect);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(value.noLimit, isTrue);
      expect(tester.getRect(slider), trackRect);
      expect(tester.getRect(edit), editRect);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(value, remembered);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('adapts to viewport, text scale and optional controls', (
    tester,
  ) async {
    for (final width in <double>[320, 390, 768, 1280]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      for (final scale in <double>[1, 2]) {
        for (final label in <String?>['Maximum distance', null]) {
          for (final allowNoLimit in <bool>[true, false]) {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(40),
                      child: DistanceSlider(
                        value: DistanceSelectorValue.finite(100),
                        maximumDistance: 300,
                        label: label,
                        allowNoLimit: allowNoLimit,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'width=$width scale=$scale label=$label noLimit=$allowNoLimit',
            );
          }
        }
      }
    }
    await tester.binding.setSurfaceSize(null);
  });

  group('distance options', () {
    test('preserve the range boundaries by default', () {
      expect(distanceOptions.first, 1);
      expect(distanceOptions.skip(1).first, 2);
      expect(distanceOptions.last, 500);
    });

    test('reject an invalid increment', () {
      expect(() => distanceOptionsForIncrement(0), throwsArgumentError);
    });

    test('uses one-kilometre stops through the default threshold', () {
      expect(distanceOptions.take(20), List<int>.generate(20, (i) => i + 1));
      expect(distanceOptions.skip(20).first, 25);
    });

    test('can start directly at increment stops', () {
      expect(
        distanceOptionsForIncrement(5, incrementThreshold: 0).take(3),
        <int>[1, 5, 10],
      );
      expect(
        distanceOptionsForIncrement(5, incrementThreshold: null).take(3),
        <int>[1, 5, 10],
      );
    });

    test('aligns coarse stops to multiples rather than threshold offsets', () {
      expect(distanceOptionsForIncrement(5).skip(20).take(3), [25, 30, 35]);
      expect(distanceOptionsForIncrement(25).skip(20).take(3), [25, 50, 75]);
      expect(
        distanceOptionsForIncrement(5, incrementThreshold: 22).skip(22).take(3),
        [25, 30, 35],
      );
    });

    test('aligns from a custom minimum and preserves the maximum boundary', () {
      expect(distanceOptionsForIncrement(25, minimum: 32, maximum: 83), [
        32,
        50,
        75,
        83,
      ]);
      expect(
        distanceOptionsForIncrement(
          25,
          minimum: 50,
          maximum: 83,
          incrementThreshold: null,
        ),
        [50, 75, 83],
      );
    });
  });

  group('normalizeDistanceKm', () {
    test('clamps and rounds unsupported values up', () {
      expect(normalizeDistanceKm(0), 1);
      expect(normalizeDistanceKm(20), 20);
      expect(normalizeDistanceKm(21), 20);
      expect(normalizeDistanceKm(22), 20);
      expect(normalizeDistanceKm(498), 500);
      expect(normalizeDistanceKm(501), 500);
    });
  });

  group('clampDistanceKm', () {
    test('preserves manual values between the minimum and maximum', () {
      expect(clampDistanceKm(52), 52);
      expect(clampDistanceKm(0), 1);
      expect(clampDistanceKm(501), 500);
    });
  });

  test('uses miles as a suffix without converting the value', () {
    expect(DistanceUnit.miles.formatDisplayValue(52), '52');
  });

  testWidgets('accepts a manually entered maximum distance', (tester) async {
    var value = DistanceSelectorValue.finite(25);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: DistanceSlider(
              value: value,
              onChanged: (nextValue) => setState(() => value = nextValue),
              maximumDistance: 500,
            ),
          ),
        ),
      ),
    );
    final initialControlSize = tester.getSize(
      find.byKey(const ValueKey<String>('distance-slider-current-value')),
    );

    await tester.tap(find.widgetWithText(TextButton, '25 km'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '52');
    await tester.tap(find.widgetWithText(FilledButton, 'Set'));
    await tester.pumpAndSettle();

    expect(value, DistanceSelectorValue.finite(52));
    expect(tester.widget<Slider>(find.byType(Slider)).value, greaterThan(0));
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('distance-slider-current-value')),
      ),
      initialControlSize,
    );
  });

  testWidgets('keeps the range visible when no limit is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DistanceSlider(
            value: const DistanceSelectorValue.noLimit(),
            maximumDistance: 500,
            label: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('1 km'), findsWidgets);
    expect(find.text('500 km'), findsOneWidget);
    expect(find.text('Maximum distance'), findsNothing);
    expect(find.text('No limit'), findsWidgets);
  });

  testWidgets('fits a narrow mobile viewport without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: DistanceSlider(
              value: DistanceSelectorValue.finite(1),
              maximumDistance: 300,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
