import 'package:flutter_test/flutter_test.dart';

import 'package:gicho/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'package startup defaults resolve without consumer application code',
    () async {
      final values = await const GichoConfigurationService().load(
        defaultsAsset: 'packages/gicho/assets/gicho.yaml',
        schemaAsset: 'packages/gicho/assets/gicho.schema.json',
      );
      final settings = GichoStartupConfiguration.fromConfiguration(values);
      expect(settings.companyMinimum, Duration.zero);
      expect(settings.productMinimum, Duration.zero);
      expect(settings.loadingMinimum, Duration.zero);
    },
  );

  test('annual and fixed campaigns honor inclusive dates and country', () {
    final settings = GichoStartupConfiguration.fromConfiguration({
      'app': {
        'startup': {
          'companyMinimumMilliseconds': 0,
          'productMinimumMilliseconds': 0,
          'loadingMinimumMilliseconds': 0,
          'transitionMilliseconds': 0,
          'transition': 'fade',
          'productPortraitSceneAsset': 'default-portrait.png',
          'productLandscapeSceneAsset': 'default-landscape.png',
          'scheduledProductScenes': [
            {
              'id': 'christmas',
              'start': '12-01',
              'end': '12-25',
              'portraitSceneAsset': 'christmas-portrait.png',
              'landscapeSceneAsset': 'christmas-landscape.png',
            },
            {
              'id': 'songkran-2027',
              'start': '2027-04-13',
              'end': '2027-04-15',
              'countries': ['TH'],
              'portraitSceneAsset': 'songkran-portrait.png',
              'landscapeSceneAsset': 'songkran-landscape.png',
            },
          ],
        },
      },
    });

    expect(
      settings.productSceneFor(DateTime(2026, 12, 1)).portrait,
      'christmas-portrait.png',
    );
    expect(
      settings.productSceneFor(DateTime(2027, 12, 25)).landscape,
      'christmas-landscape.png',
    );
    expect(
      settings.productSceneFor(DateTime(2027, 12, 26)).portrait,
      'default-portrait.png',
    );
    expect(
      settings
          .productSceneFor(DateTime(2027, 4, 13), countryCode: 'TH')
          .portrait,
      'songkran-portrait.png',
    );
    expect(
      settings
          .productSceneFor(DateTime(2027, 4, 15), countryCode: 'TH')
          .landscape,
      'songkran-landscape.png',
    );
    expect(
      settings
          .productSceneFor(DateTime(2027, 4, 14), countryCode: 'US')
          .portrait,
      'default-portrait.png',
    );
    expect(
      settings.productSceneFor(DateTime(2027, 4, 14)).portrait,
      'default-portrait.png',
    );
    expect(
      settings
          .productSceneFor(DateTime(2028, 4, 14), countryCode: 'TH')
          .portrait,
      'default-portrait.png',
    );
    expect(settings.needsCountryFor(DateTime(2027, 4, 14)), isTrue);
    expect(settings.needsCountryFor(DateTime(2027, 12, 14)), isFalse);
    expect(settings.needsCountryFor(DateTime(2027, 5, 1)), isFalse);
  });
}
