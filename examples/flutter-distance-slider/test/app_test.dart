import 'package:gicho/gicho.dart';
import 'package:gicho_distance_slider_example/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Gicho slider at the example starting value', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    final slider = tester.widget<DistanceSlider>(find.byType(DistanceSlider));
    expect(slider.value.maximumDistanceKm, 10);
    expect(slider.maximumDistance, 100);
    expect(tester.takeException(), isNull);
  });
}
