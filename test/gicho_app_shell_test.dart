import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final destinations = <NavigationDestination>[
    const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
    const NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      label: 'Settings',
    ),
  ];

  for (final width in [390.0, 1400.0]) {
    testWidgets(
      'title prefix and title are separate controls at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final locales = GichoLocaleController();
        addTearDown(locales.dispose);
        var prefixTaps = 0;
        var titleTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: GichoAppShell(
              title: 'Ticket',
              locales: locales,
              destinations: destinations,
              titlePrefix: IconButton(
                tooltip: 'Open active ticket',
                onPressed: () => prefixTaps++,
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              onTitlePressed: () => titleTaps++,
              body: const Text('Items'),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Open active ticket'));
        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Ticket'),
          ),
        );
        expect(prefixTaps, 1);
        expect(titleTaps, 1);
      },
    );
  }

  for (final width in [390.0, 900.0]) {
    testWidgets('uses a dismissible drawer at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final locales = GichoLocaleController();
      addTearDown(locales.dispose);
      var selected = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: GichoAppShell(
            title: 'Example',
            locales: locales,
            destinations: destinations,
            onDestinationSelected: (index) => selected = index,
            body: const Text('Page content'),
          ),
        ),
      );
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byTooltip('Open navigation'), findsOneWidget);

      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close navigation'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close navigation'), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.byType(IconButton).first)
            .focusNode
            ?.hasFocus,
        isTrue,
      );

      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(find.byTooltip('Close navigation'), findsNothing);
    });
  }

  testWidgets('keeps an extended sidebar at large width', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final locales = GichoLocaleController();
    addTearDown(locales.dispose);
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: GichoAppShell(
          title: 'Example',
          locales: locales,
          destinations: destinations,
          onDestinationSelected: (index) => selected = index,
          body: const Text('Page content'),
        ),
      ),
    );
    expect(find.byTooltip('Open navigation'), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  for (final width in [390.0, 1400.0]) {
    testWidgets('disables unavailable destinations at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final locales = GichoLocaleController();
      addTearDown(locales.dispose);
      var selected = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: GichoAppShell(
            title: 'Example',
            locales: locales,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
                enabled: false,
              ),
            ],
            onDestinationSelected: (index) => selected = index,
            body: const Text('Page content'),
          ),
        ),
      );
      if (width < 1280) {
        await tester.tap(find.byTooltip('Open navigation'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationDrawerDestination>(
                find.widgetWithText(NavigationDrawerDestination, 'Settings'),
              )
              .enabled,
          isFalse,
        );
      } else {
        expect(
          tester
              .widget<NavigationRail>(find.byType(NavigationRail))
              .destinations[1]
              .disabled,
          isTrue,
        );
      }
      await tester.tap(find.text('Settings'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, -1);
    });
  }

  testWidgets('empty navigation keeps only the app-owned page', (tester) async {
    final locales = GichoLocaleController();
    addTearDown(locales.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: GichoAppShell(
          title: 'Example',
          locales: locales,
          body: const Text('Page content'),
        ),
      ),
    );
    expect(find.byTooltip('Open navigation'), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Page content'), findsOneWidget);
  });

  testWidgets('shows the compact brand once and lets a page hide it', (
    tester,
  ) async {
    final locales = GichoLocaleController();
    addTearDown(locales.dispose);

    Future<void> show({required bool showBrand}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GichoAppShell(
            title: 'Customer',
            brand: const GichoBrand(name: 'Customer'),
            showBrand: showBrand,
            locales: locales,
            body: const Text('Memberships'),
          ),
        ),
      );
    }

    await show(showBrand: true);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);

    await show(showBrand: false);
    expect(find.byIcon(Icons.layers_outlined), findsNothing);
    expect(find.text('Customer'), findsOneWidget);
  });
}
