import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  testWidgets('a page can enable one action despite its global default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: GichoAppBar(
            title: const Text('Page'),
            configuration: _configuration(configDisplay: false),
            actionOverrides: const {
              GichoAppBarFeature.configurationDisplay: true,
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.data_object), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
  });

  testWidgets('a page can hide one action despite its global default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: GichoAppBar(
            title: const Text('Page'),
            configuration: _configuration(configDisplay: true),
            actionOverrides: const {
              GichoAppBarFeature.configurationDisplay: false,
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.data_object), findsNothing);
  });

  testWidgets('can omit all package-owned actions while keeping app actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: GichoAppBar(
            title: const Text('Page'),
            configuration: _configuration(configDisplay: true),
            showStandardActions: false,
            actions: const [Icon(Icons.add)],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.data_object), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}

GichoCoreConfiguration _configuration({required bool configDisplay}) =>
    GichoCoreConfiguration.fromDocument(
      ConfigurationDocument({
        'appBar': {
          'actions': {
            'brightness': {'enabled': false},
            'theme': {'enabled': false},
            'language': {'enabled': false},
            'configDisplay': {'enabled': configDisplay},
            'logout': {'enabled': false},
          },
        },
      }),
    );
