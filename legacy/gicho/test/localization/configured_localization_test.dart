import 'package:flutter_test/flutter_test.dart';
import 'package:moztopia/gicho.dart';

void main() {
  test('parses local and remote source settings', () {
    final settings = LocalizationConfiguration.fromDocument(
      ConfigurationDocument({
        'fallbackLanguage': 'en',
        'localSource': 'assets',
        'remoteEnabled': true,
        'remoteSource': 'git',
        'remoteLoadMode': 'background',
        'remoteRepository': 'https://github.com/mozrin/gicho',
        'remotePath': 'example.everything',
        'remoteReference': 'main',
      }),
    );

    expect(settings.fallbackLanguage.languageCode, 'en');
    expect(settings.localSource, LocalizationLocalSource.assets);
    expect(settings.remoteEnabled, isTrue);
    expect(settings.remoteLoadMode, LocalizationRemoteLoadMode.background);
    expect(
      settings.remoteRepository,
      Uri.parse('https://github.com/mozrin/gicho'),
    );
    expect(settings.remotePath, 'example.everything');
  });

  test('remote repository and path are required when enabled', () {
    expect(
      () => LocalizationConfiguration.fromDocument(
        ConfigurationDocument({
          'fallbackLanguage': 'en',
          'localSource': 'assets',
          'remoteEnabled': true,
          'remoteSource': 'git',
          'remoteLoadMode': 'blocking',
          'remoteReference': 'main',
        }),
      ),
      throwsA(isA<ConfigurationException>()),
    );
  });
}
