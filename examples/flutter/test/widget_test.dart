import 'package:flutter_test/flutter_test.dart';

import 'package:distance_slider_example/app.dart';

void main() {
  testWidgets('renders the component gallery', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('Gicho gallery'), findsOneWidget);
    expect(find.text('Maximum distance'), findsWidgets);
    expect(find.text('1 km'), findsWidgets);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('About this gallery'), findsOneWidget);
    expect(find.text('Gicho component examples'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Maximum distance'), findsWidgets);
  });
}
