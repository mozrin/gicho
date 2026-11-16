import 'package:gicho_page_flow_example/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a modal page and returns to the shell', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Open About'));
    await tester.pumpAndSettle();
    expect(
      find.text('A focused page without shell navigation'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open About'), findsOneWidget);
  });
}
