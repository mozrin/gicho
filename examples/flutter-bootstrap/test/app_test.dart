import 'package:gicho_bootstrap_example/app.dart';
import 'package:gicho/gicho.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('retries startup before showing the ready app', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      buildApp(
        load: () async {
          attempts++;
          if (attempts == 1) {
            throw StateError('temporary failure');
          }
          return {
            'brand': {'name': 'Bootstrap Example'},
            'app': {'startupMessage': 'Ready from application configuration'},
          };
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not start.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Ready from application configuration'), findsOneWidget);
  });

  test('loads the consumer schema and YAML through package defaults', () async {
    final configuration = await const GichoConfigurationService()
        .loadApplication();
    expect(configuration['schemaVersion'], 1);
    final brand = GichoBrand.fromConfiguration(configuration);
    expect(brand.name, 'Bootstrap Example');
    expect(brand.logoAsset, 'assets/launch_logo.png');
    expect(brand.markAsset, 'assets/launch_logo.png');
    expect(
      configuration['app'],
      containsPair('startupMessage', 'Ready from application configuration'),
    );
    expect((configuration['app'] as Map)['startup'], isA<Map>());
  });

  test('missing optional app assets inherit package defaults', () async {
    final configuration = await const GichoConfigurationService()
        .loadApplication(
          consumerAsset: 'assets/gicho/absent.yaml',
          consumerSchemaAsset: 'assets/gicho/absent.schema.json',
        );
    expect(configuration['schemaVersion'], 1);
    expect(GichoBrand.fromConfiguration(configuration).name, 'Gicho');
    expect(configuration['app'], contains('startup'));
    expect(
      (configuration['app'] as Map)['startup'],
      containsPair('transition', 'fade'),
    );
  });

  test('loaded app schema rejects wrong values and versions', () async {
    for (final overrides in <Map<String, dynamic>>[
      {
        'app': {'startupMessage': 42},
      },
      {'schemaVersion': 2},
    ]) {
      expect(
        () => const GichoConfigurationService().loadApplication(
          overrides: overrides,
        ),
        throwsFormatException,
      );
    }
  });

  test('malformed present schema identifies its asset', () async {
    expect(
      () => const GichoConfigurationService().loadApplication(
        consumerSchemaAsset: 'assets/gicho/gicho.yaml',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('assets/gicho/gicho.yaml'),
        ),
      ),
    );
  });
}
