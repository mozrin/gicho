# Configuration in the example

The example declares the flat `assets/gicho/` augmentation directory in
`example/pubspec.yaml`. It contains logging and localization overrides plus all
bundled locale catalogs. The logging override changes the configurable debug
color:

```yaml
colors:
  debug: purple
```

The package defaults and schema remain in `lib/src/logging/`. The schema locks
the info, warning, and error colors, so an application cannot replace them.

The example initializes configured logging before building the widget tree:

```dart
import 'package:moztopia/gicho.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await moztopiaLog.initialize();
  runApp(const App());
}
```

The Configuration Inspector dropdown selects logging or localization. Its
Package, App, and Merged tabs show the complete resolution process for either
feature. The Config app-bar map action separately displays the aggregate
in-memory configuration registry.
See the repository [configuration overview](../../../../docs/configuration.md)
for the file convention, validation rules, and direct `ConfigurationService`
API.
