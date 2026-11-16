import 'dart:async';

import 'package:example_minimal/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  testWidgets('runs startup and authentication before the app', (tester) async {
    final ready = Completer<void>();
    await tester.pumpWidget(ExampleMinimalApp(onReady: ready.complete));
    await tester.runAsync(() => ready.future);
    await tester.pump();

    expect(find.byType(StartupPage), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('LOGIN'), findsOneWidget);

    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Localization available: false'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Notifications available: true'),
      findsOneWidget,
    );
  });
}
