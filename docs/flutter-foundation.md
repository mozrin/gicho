# Flutter foundation

`gicho` is the single generic Flutter package at the repository root.
Its public entry is `package:gicho/gicho.dart`. `GichoBootstrap<T>`
composes shared splash and retry presentation around an app-supplied
preparation task, then hands the result to the ready application. `StartupGate<T>`
runs an app-supplied startup task and renders loading, ready or error content;
`StartupSplash` provides a theme-aware loading screen with app-supplied copy.
The result type is owned by the app, so the gate can hand off to native sign-in
or an authenticated home screen without Gicho knowing about Authackage.
`GichoLocaleController` owns the canonical supported-locale registry,
key-driven package/app catalog lookup and exact-key behavior for missing copy.
`GichoLanguagePicker` lists only the app-enabled registered locales.
Gicho registers the [20 supported languages](languages.md). Its `zh`
catalog contains Simplified Chinese text. Apps must enable English and may
enable more registered locales after translating their own copy.
`gichoTheme` builds a shared Material 3 look from an app-supplied seed and
brightness. `ThemeCatalog` loads permanent Default, Ocean and Ember choices;
`ThemeController` applies an app-selected subset/default and a saved user
choice; `ThemePicker` exposes that selection and system/light/dark modes.
`GichoAppShell` uses a modal drawer below 1280 logical pixels
and a persistent extended rail at 1280 and above. The app supplies its own
destinations and callbacks; Gicho owns no route map or auth authority.
`GichoModalPage` provides a full-screen guided page with a title and
optional Back control; consumers own its content, route origin and navigation
fallback. It is not a floating dialog. Both the shell and modal page use the
same internal page frame for their app bar, actions and safe-area body.
`GichoMaterialApp.router` accepts a consumer-owned `RouterConfig` while
applying the same locale and theme setup as the home-based constructor. Apps
may instead provide their own `MaterialApp`.
The distance slider is a controlled Flutter component for choosing a
maximum distance from the deliberately non-linear domain `1…20, 25…500` km.
It also supports an explicit no-limit state, keyboard-accessible slider
interaction, and validated direct numeric entry.

Implementation is organized below `lib/src/` by responsibility: whole-app
composition in `application/`, capabilities in `features/`, reusable visual
building blocks in `ui/`, pure services in `services/`, and package copy in
`i18n/`. Add `utilities/` only when a broadly useful, UI-free helper exists.

## Use

```dart
import 'package:gicho/gicho.dart';

DistanceSelectorValue value = DistanceSelectorValue.finite(25);

DistanceSlider(
  value: value,
  onChanged: (nextValue) => setState(() => value = nextValue),
  maximumDistance: 300,
)
```

`DistanceSelectorValue` is atomic: use `DistanceSelectorValue.finite(km)` for
a finite value or `const DistanceSelectorValue.noLimit()` for no maximum.
Finite values supplied to the constructor are normalized to the supported
domain. The `DistanceSlider` remains controlled: persist and provide each value
received through `onChanged`.

```dart
StartupGate<Session?>(
  load: client.session,
  loadingBuilder: (_) => const StartupSplash(title: 'My app'),
  errorBuilder: (_, error, retry) => TextButton(
    onPressed: retry,
    child: const Text('Try again'),
  ),
  readyBuilder: (_, session) => session == null
      ? const SignInScreen()
      : const HomeScreen(),
)
```

The app supplies localized copy and owns the session result. Recreate the gate
with a new key after account or environment changes; it ignores completions
from its disposed context. See the runnable startup demo in `examples/flutter`.

For the outer configuration stage, `GichoBootstrap<T>` uses `StartupGate<T>`
with shared themed loading and failure/retry views. The consumer still supplies
the preparation task, copy, theme and ready app. See
[its public contract](../lib/src/application/bootstrap/README.md).

```dart
final locales = GichoLocaleController(
  appCatalogs: {'en': {'app.welcome': 'Welcome'}},
);

GichoLanguagePicker(controller: locales);
locales.text('app.welcome'); // Welcome
locales.text('app.missing'); // app.missing
```

The application owns and disposes the controller. Its values override package
copy for the same fully qualified key. There is no other-language fallback.

```dart
GichoMaterialApp(
  locales: locales,
  title: () => locales.text('app.title'),
  theme: gichoTheme(seedColor: const Color(0xFF17634F)),
  home: GichoAppShell(
    title: 'My app',
    locales: locales,
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    ],
    onDestinationSelected: (index) => openSection(index),
    body: const HomeContent(),
  ),
)
```

`GichoMaterialApp` owns Material app setup and listens to the app-owned
locale controller. The app supplies its localized title, theme and home; it
still owns the controller lifetime, navigation choices, startup tasks and
authentication. See [its public contract](../lib/src/application/material_app/README.md).

## Test

```sh
flutter test
```

The runnable cross-platform example is in `examples/flutter`.

# Configuration inheritance

The public `GichoConfigurationService` loads any package's defaults and
schema, then resolves optional consumer YAML/schema and programmatic overrides.
For the standard Gicho asset paths, call `loadApplication()`; it validates
app-owned keys under `app` without changing Gicho-owned keys.
See [the service contract](../lib/src/services/configuration/README.md)
See also the [package asset guide](../assets/README.md).
