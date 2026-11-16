import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('installs unavailable feature states by default', (tester) async {
    await _pumpBootstrap(tester, const _AvailabilityProbe());

    expect(
      find.text(
        'startup=false authentication=false '
        'localization=false notifications=false',
      ),
      findsOneWidget,
    );
    expect(find.byType(StartupStage), findsNothing);
    expect(find.byType(AuthenticationStage), findsNothing);
    expect(find.byType(ToastificationWrapper), findsNothing);
  });

  testWidgets('installs startup and authentication stages when requested', (
    tester,
  ) async {
    final queueCompletion = Completer<void>();
    final startupDelegate = StartupProcess(
      startupPreDelayDuration: const Duration(seconds: 1),
      startupPostDelayDuration: const Duration(seconds: 1),
      startupOverlays: [
        (context, state, complete) => Directionality(
          textDirection: ui.TextDirection.ltr,
          child: TextButton(
            onPressed: complete,
            child: const Text('COMPLETE STARTUP OVERLAY'),
          ),
        ),
      ],
      startupQueue: [
        (
          process: () => queueCompletion.future,
          type: StartupQueueType.synchronous,
        ),
      ],
    );

    await _pumpBootstrap(
      tester,
      const _AvailabilityProbe(),
      startupEnabled: true,
      startupDelegate: startupDelegate,
      authenticationEnabled: true,
      authenticationDelegate: _MockAuthenticationDelegate(),
    );

    // Bootstrap defers the first frame until the pre-delay has elapsed.
    expect(find.byType(StartupStage), findsNothing);
    expect(find.text('COMPLETE STARTUP OVERLAY'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(StartupStage), findsOneWidget);
    expect(find.byType(AuthenticationStage), findsNothing);
    expect(find.text('COMPLETE STARTUP OVERLAY'), findsOneWidget);
    expect(find.text('MOCK AUTHENTICATION'), findsNothing);

    // The overlay and queue must both complete before the post-delay starts.
    queueCompletion.complete();
    await tester.pump();
    expect(find.text('MOCK AUTHENTICATION'), findsNothing);

    await tester.tap(find.text('COMPLETE STARTUP OVERLAY'));
    await tester.pump();
    expect(find.text('MOCK AUTHENTICATION'), findsNothing);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('COMPLETE STARTUP OVERLAY'), findsNothing);
    expect(find.text('MOCK AUTHENTICATION'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('EXIT'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('LOGIN'));
    await tester.pump();

    expect(find.text('MOCK AUTHENTICATION'), findsNothing);
    expect(
      find.text(
        'startup=true authentication=true '
        'localization=false notifications=false',
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byType(AuthenticationStage),
        matching: find.byType(StartupStage),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byType(_AvailabilityProbe),
        matching: find.byType(AuthenticationStage),
      ),
      findsOneWidget,
    );
  });

  testWidgets('installs the notification layer only when requested', (
    tester,
  ) async {
    await _pumpBootstrap(
      tester,
      const _AvailabilityProbe(),
      notificationsEnabled: true,
    );

    expect(
      find.text(
        'startup=false authentication=false '
        'localization=false notifications=true',
      ),
      findsOneWidget,
    );
    expect(find.byType(ToastificationWrapper), findsOneWidget);
  });

  testWidgets('starts a consumer router without imposing page layout', (
    tester,
  ) async {
    final router = GichoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _AvailabilityProbe(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpBootstrap(tester, GichoMaterialApp.router(router: router));

    expect(
      find.text(
        'startup=false authentication=false '
        'localization=false notifications=false',
      ),
      findsOneWidget,
    );
    expect(find.byType(Scaffold), findsNothing);
  });
}

Future<void> _pumpBootstrap(
  WidgetTester tester,
  Widget child, {
  bool startupEnabled = false,
  StartupDelegate? startupDelegate,
  bool authenticationEnabled = false,
  AuthenticationDelegate? authenticationDelegate,
  bool notificationsEnabled = false,
}) async {
  final ready = Completer<void>();
  await tester.pumpWidget(
    GichoBootstrap(
      key: UniqueKey(),
      startupEnabled: startupEnabled,
      startupDelegate: startupDelegate,
      authenticationEnabled: authenticationEnabled,
      authenticationDelegate: authenticationDelegate,
      notificationsEnabled: notificationsEnabled,
      onReady: ready.complete,
      child: child,
    ),
  );
  await tester.runAsync(() => ready.future);
  await tester.pump();
}

class _MockAuthenticationDelegate implements AuthenticationDelegate {
  final ValueNotifier<AuthenticationState> _state = ValueNotifier(
    AuthenticationState.checking,
  );

  @override
  ValueListenable<AuthenticationState> get state => _state;

  @override
  Future<void> initialize() async {
    _state.value = AuthenticationState.unauthenticated;
  }

  @override
  Widget buildAuthentication(BuildContext context) => Directionality(
    textDirection: ui.TextDirection.ltr,
    child: Column(
      children: [
        const Text('MOCK AUTHENTICATION'),
        TextButton(
          onPressed: () => _state.value = AuthenticationState.authenticated,
          child: const Text('LOGIN'),
        ),
        const Text('EXIT'),
      ],
    ),
  );

  @override
  Future<void> logout() async {
    _state.value = AuthenticationState.unauthenticated;
  }

  @override
  void dispose() => _state.dispose();
}

class _AvailabilityProbe extends StatelessWidget {
  const _AvailabilityProbe();

  @override
  Widget build(BuildContext context) => Text(
    'startup=${StartupStage.of(context).isAvailable} '
    'authentication=${AuthenticationStage.of(context).isAvailable} '
    'localization=${GichoLocalization.of(context).isAvailable} '
    'notifications=${GichoNotifications.of(context).isAvailable}',
    textDirection: ui.TextDirection.ltr,
  );
}
