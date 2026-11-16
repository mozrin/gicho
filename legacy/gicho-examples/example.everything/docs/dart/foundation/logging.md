# Logging in the example

The example uses Gicho's configured `moztopiaLog` API. It supports trace,
debug, info, warning, error, and fatal events and initializes lazily on first
use.

```dart
import 'package:moztopia/gicho.dart';

await moztopiaLog.debug('Opening settings');
await moztopiaLog.info('Application started');
await moztopiaLog.warn('A recoverable problem occurred');
await moztopiaLog.error(
  'A request failed',
  error: error,
  stackTrace: stackTrace,
);
```

Call `await moztopiaLog.initialize()` during application startup when later
code needs the synchronous `moztopiaLog.logger` getter. The initialization
loads the package logging defaults and optional
`assets/gicho/logging.config.yaml` override.

The DNav5 logging screen emits examples at every level, including structured
objects and attached errors. Easy Localization messages are redirected to the
same configured logger. The configured printer does not emit level emojis.

Do not include passwords, access tokens, private keys, personal data, or other
secrets in log messages.
