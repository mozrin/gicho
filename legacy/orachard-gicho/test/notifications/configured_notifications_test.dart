import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled defaults provide enabled in-app plumbing and no events',
    () async {
      final configuration = await MoztopiaNotifications().initialize();

      expect(
        configuration.isChannelEnabled(GichoNotificationChannel.inApp),
        isTrue,
      );
      expect(
        configuration.isChannelEnabled(GichoNotificationChannel.push),
        isFalse,
      );
      expect(
        configuration.isChannelEnabled(GichoNotificationChannel.email),
        isFalse,
      );
      expect(configuration.catalog, isEmpty);
    },
  );

  test(
    'application override defines its catalog and channel support',
    () async {
      final configuration = await _configuration('''
channels:
  push:
    enabled: true
catalog:
  - type: recordChanged
    category: activity
    action: openRecord
    icon: favorite
    title: app.notifications.record.title
    detail: app.notifications.record.detail
    unavailableDetail: app.notifications.record.unavailable
    channels: [inApp, push]
''');

      final entry = configuration.entryFor('recordChanged')!;
      expect(entry.packageOwned, isFalse);
      expect(entry.action, 'openRecord');
      expect(entry.icon, GichoNotificationIcon.favorite);
      expect(entry.channels, {
        GichoNotificationChannel.inApp,
        GichoNotificationChannel.push,
      });
      expect(
        configuration.isChannelEnabled(GichoNotificationChannel.push),
        isTrue,
      );
    },
  );

  test('schema rejects unknown channels and unsafe catalog values', () async {
    for (final appConfig in [
      '''
channels:
  sms:
    enabled: true
''',
      '''
catalog:
  - type: record changed
    category: activity
    icon: favorite
    title: app.notifications.record.title
    detail: app.notifications.record.detail
    channels: [inApp]
''',
      '''
catalog:
  - type: recordChanged
    category: activity
    icon: custom-heart
    title: app.notifications.record.title
    detail: app.notifications.record.detail
    channels: [inApp]
''',
    ]) {
      expect(
        () => _configuration(appConfig),
        throwsA(isA<ConfigurationException>()),
      );
    }
  });
}

Future<GichoNotificationsConfiguration> _configuration(
  String appConfig,
) async {
  final packageConfig = await rootBundle.loadString(
    ConfigurationService.packageConfigAsset('notifications'),
  );
  final schema = await rootBundle.loadString(
    ConfigurationService.packageSchemaAsset('notifications'),
  );
  final registry = ConfigurationRegistry(
    service: ConfigurationService(
      loader: _NotificationsLoader({
        ConfigurationService.packageConfigAsset('notifications'): packageConfig,
        ConfigurationService.packageSchemaAsset('notifications'): schema,
        ConfigurationService.appConfigAsset('notifications'): appConfig,
      }),
    ),
  );
  return MoztopiaNotifications(configurationRegistry: registry).initialize();
}

final class _NotificationsLoader implements ConfigurationAssetLoader {
  const _NotificationsLoader(this.assets);

  final Map<String, String> assets;

  @override
  Future<String?> load(String asset, {bool optional = false}) async {
    final value = assets[asset];
    if (value != null || optional) return value;
    throw ConfigurationException('Asset not found.', location: asset);
  }
}
