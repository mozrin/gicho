# Core app and optional page-shell refactor

## Goal

Keep Gicho responsible for application-wide features without forcing a
consumer to use the layout demonstrated by `example.everything`.

The finished design should provide two independent layers:

1. `GichoMaterialApp` initializes and connects application-wide services.
2. An optional page shell helps consumers compose an app bar, drawer, content,
   and footer when they want that layout vocabulary.

Consumers must remain free to use the first layer without the second.

> The code below is a proposed API for approval. It documents the intended
> design before implementation; names and parameters can still be changed.

## Architectural rules

### Routes remain in Dart

Routes are the instructions that say which page opens for a URL or navigation
request. They often need to run real code, such as reading an item ID, checking
whether someone is signed in, or deciding where to redirect them. Dart can do
that work safely and can report mistakes during development. YAML is useful for
simple settings, but it is a poor place for application behavior and would make
the routing system harder to understand.

For example, the route stays close to the Dart page it creates and can safely
read a value from the URL:

```dart
GoRoute(
  path: '/products/:productId',
  builder: (context, state) => ProductPage(
    productId: state.pathParameters['productId']!,
  ),
)
```

### Gicho standardizes GoRouter

Gicho requires GoRouter and provides a `GichoRouter` facade that applies
the framework's standard routing setup. The consumer still writes the route
list in Dart because only the consumer knows which pages its application has.
The package's `pubspec.yaml` controls the supported GoRouter version, giving
Gicho applications a consistent routing foundation. Advanced consumers can
still reach the underlying `GoRouter` when they need capabilities that the
standard facade does not expose directly.

The intended public shape is approximately:

```dart
final class GichoRouter {
  GichoRouter({
    required List<RouteBase> routes,
    String initialLocation = '/',
    GoRouterRedirect? redirect,
  });

  RouterConfig<Object> get config;
  GoRouter get goRouter;
}
```

This is a facade around GoRouter, not a replacement implementation of routing.
Normal page code can continue using familiar navigation through the GoRouter
extensions exported by Gicho:

```dart
context.go('/settings');
context.push('/edit-profile');
context.pop();
```

### The consumer supplies the routes

The consumer passes its Dart route definitions to `GichoRouter`, then gives
that router to `GichoMaterialApp.router`. In plain terms, Gicho provides
the navigation engine and standard setup, while the consumer supplies the map
of its own pages. Gicho does not need to know the names or purposes of those
pages. A consumer can replace or reorganize its route list without changing the
package.

The consumer's router file would look approximately like this:

```dart
final appRouter = GichoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
```

### Gicho standardizes notifications

Consumer application code should use `GichoNotifications` instead of
depending directly on `ToastificationWrapper`. Gicho chooses and versions
Toastification in its own `pubspec.yaml`, then presents a stable package-owned
widget to consumers. If the underlying notification library changes later,
simple consumer applications should not need to rewrite their root widget.
Advanced notification behavior may still have an explicitly documented escape
hatch to the underlying library.

The proposed wrapper is deliberately small:

```dart
final class GichoNotifications extends StatelessWidget {
  const GichoNotifications({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => ToastificationWrapper(
    child: child,
  );
}
```

Consumer code sees only the Gicho-owned name:

```dart
GichoNotifications(
  child: GichoMaterialApp.router(router: appRouter),
)
```

### `GichoMaterialApp` does not inject a layout

`GichoMaterialApp` must not automatically add a scaffold, app bar, drawer,
footer, navigation rail, bottom navigation, or page. Its job is to connect
application-wide services such as themes and localization to Flutter's
`MaterialApp`. The consumer remains responsible for what appears on the screen
and where it appears. This allows one application to use a drawer while another
uses menu cards inside its content area.

The consumer connects its router without giving Gicho any layout widgets:

```dart
GichoMaterialApp.router(
  title: 'My application',
  router: appRouter,
)
```

### The page shell is optional

The page shell is a convenience component for consumers who want a familiar
page structure made from an app bar, drawer, content area, and footer. A
consumer can use it on every page, only on selected pages, or not at all. It is
not required in order to use Gicho themes, localization, or other features.
An ordinary Flutter `Scaffold` must always remain a valid alternative.

A page that wants the convenience shell could use it like this:

```dart
GichoPageShell(
  appBar: GichoAppBar(title: const Text('Dashboard')),
  drawer: const ApplicationDrawer(),
  body: const DashboardContent(),
  bottomNavigationBar: const ApplicationFooter(),
)
```

Nothing is shown for a region that the consumer does not supply.

### The router defines modal presentation

A modal page is not merely a page with some controls hidden; it is a navigation
decision about how the page enters, sits on, and leaves the page stack. The
consumer's router therefore decides whether a page is a full-screen dialog,
uses a special transition, or is opened normally. It also decides what happens
when the user presses Back. Gicho can provide useful widgets for the page,
but it should not silently change those navigation rules.

For example, the router—not the page shell—marks this route as a full-screen
dialog:

```dart
GoRoute(
  path: '/settings',
  pageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    fullscreenDialog: true,
    child: const SettingsPage(),
  ),
)
```

### The page shell controls appearance, not navigation

The page shell may display the visual form commonly used by a modal page: a
back arrow, no drawer, no footer, and no app-bar actions. Those choices describe
what the page looks like. They do not make the page modal or place it on the
navigation stack. The router performs the navigation, while the page shell
simply renders the regions requested by the page.

The page itself asks only for the chrome it wants:

```dart
GichoPageShell(
  appBar: GichoAppBar(
    title: const Text('Settings'),
    leading: const BackButton(),
    showStandardActions: false,
  ),
  body: const SettingsContent(),
)
```

There is no drawer or footer because neither region was supplied.

### Core YAML controls global package features

Core YAML answers application-wide questions such as whether the package's
brightness, theme color, language, and configuration buttons are shown by
default.
It does not list the consumer's routes or describe the layout of individual
pages. Keeping those concerns separate prevents a renamed page from breaking a
configuration file. The YAML remains a small set of understandable policy
switches, while Dart remains the source of truth for application structure.

For example, YAML can disable the language selector everywhere:

```yaml
appBar:
  actions:
    language:
      enabled: false
```

It should not contain entries such as `settingsPage`, `/settings`, or
`showFooter`.

In this design, the YAML value is the global default rather than an absolute
ban. An individual page may explicitly reverse that default in Dart. The
resolution order is:

1. an explicit override on the current page;
2. the global value from `core.config.yaml`;
3. the package default when neither of the above supplies a value.

This gives the consumer both useful patterns without identifying pages in
YAML.

To show the language selector on only one page, disable it globally:

```yaml
appBar:
  actions:
    language:
      enabled: false
```

Then enable it on that page in Dart:

```dart
GichoAppBar(
  title: const Text('Language settings'),
  actionOverrides: const {
    GichoAppBarFeature.languageSelector: true,
  },
)
```

To show the language selector everywhere except one page, enable it globally:

```yaml
appBar:
  actions:
    language:
      enabled: true
```

Then disable it on the exceptional page:

```dart
GichoAppBar(
  title: const Text('Focused editor'),
  actionOverrides: const {
    GichoAppBarFeature.languageSelector: false,
  },
)
```

`GichoAppBarFeature` is a typed enum containing `brightnessToggle`,
`themeSelector`, `languageSelector`, and `configurationDisplay`. Using an enum
avoids misspelled action names and lets Dart report mistakes before the
application runs.

## Proposed package structure

```text
lib/src/core/
├── app/
│   ├── app.dart
│   ├── app_bootstrap.dart
│   └── exports_app.dart
├── components/
│   ├── app_bar/
│   ├── config_display/
│   └── page_shell/
│       ├── page_shell.dart
│       └── exports_page_shell.dart
├── core.config.yaml
├── core.config.schema.json
├── core_configuration.dart
└── moztopia_core.dart

lib/src/routing/
├── gicho_router.dart
└── exports_routing.dart

lib/src/notifications/
├── gicho_notifications.dart
├── toastification.dart
└── exports_notifications.dart
```

Do not put consumer navigation shells or example page layouts under
`lib/src/core/`.

`core_configuration.dart` contains the typed configuration models and the code
that parses `core.config.yaml`. Its filename describes the information it
represents rather than saying only that the feature is "configured."
`moztopia_core.dart` contains the initialization service and the global
`moztopiaCore` instance. Keeping those responsibilities separate prevents the
configuration model from becoming mixed with application lifecycle code.

## Phase 1: stabilize the application foundation

- [ ] Rename `configured_core.dart` to `core_configuration.dart`.
- [ ] Keep `GichoCoreConfiguration`, app-bar feature policy, and YAML parsing
  in `core_configuration.dart`.
- [ ] Move `MoztopiaCore` and the `moztopiaCore` global instance into
  `moztopia_core.dart`.
- [ ] Export both files through the existing core barrel.
- [ ] Add `GichoNotifications` as the simple-mode wrapper around the
  package-supported Toastification implementation.
- [ ] Keep Toastification version selection inside the Gicho package.
- [ ] Document whether advanced consumers access Toastification directly or
  through a clearly named property/service; do not leak it into the simple
  consumer example.
- [ ] Confirm `GichoMaterialApp.router` owns only:
  - package bootstrap;
  - configured light and dark themes;
  - current theme mode;
  - configured localization;
  - the configured `GichoRouter` supplied by the consumer;
  - standard `MaterialApp.router` composition hooks.
- [ ] Keep the consumer executable tiny:

  ```dart
  import 'package:flutter/material.dart';

  import 'app.dart';

  void main() => runApp(const GichoApp());
  ```

- [ ] Keep consumer `app.dart` as the extension seam for providers, overlays,
  observers, and other application-specific wrappers.

  ```dart
  final appRouter = GichoRouter(routes: applicationRoutes);

  class GichoApp extends StatelessWidget {
    const GichoApp({super.key});

    @override
    Widget build(BuildContext context) => ProviderScope(
      child: GichoNotifications(
        child: GichoMaterialApp.router(router: appRouter),
      ),
    );
  }
  ```

- [ ] Review bootstrap options and expose only options consumers genuinely
  need. Avoid making test-only concerns part of the primary API.
- [ ] Document the simple path and the advanced/manual-bootstrap path.

## Phase 2: standardize GoRouter

- [ ] Add a `GichoRouter` facade under `lib/src/routing/`.
- [ ] Require GoRouter as the routing engine and manage its compatible version
  in the package `pubspec.yaml`.

  ```yaml
  dependencies:
    go_router: ^17.4.0
  ```

  Consumer applications import GoRouter types from
  `package:moztopia/gicho.dart`; they should not choose an unrelated
  GoRouter version independently.
- [ ] Accept consumer-owned GoRouter route types, including `GoRoute`,
  `ShellRoute`, and `StatefulShellRoute`.
- [ ] Apply Gicho defaults for concerns that truly should be uniform, such
  as diagnostics, error presentation hooks, observers, and shared redirects.
- [ ] Do not invent Gicho copies of every GoRouter route or navigation type.
- [ ] Expose the underlying `GoRouter` so advanced consumers retain the full
  GoRouter API.

  ```dart
  appRouter.goRouter.go('/settings');
  ```

- [ ] Make `GichoRouter` directly usable by `GichoMaterialApp.router`.
- [ ] Document this responsibility split:

  ```dart
  final router = GichoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
  ```

  Gicho owns the routing engine and standard setup. The consumer owns the
  route list and page behavior.

## Phase 3: define the opt-in page shell

- [ ] Create a plainly named page-shell component under
  `core/components/page_shell/`.
- [ ] Make content the only required region.
- [ ] Support optional regions using widgets or builders rather than coupling
  the shell to the example implementation:
  - app bar;
  - drawer;
  - end drawer;
  - body/content;
  - footer or bottom navigation;
  - floating action button.
- [ ] Allow consumers to supply ordinary Flutter widgets for every region.
- [ ] Provide useful defaults only where they are unambiguous.
- [ ] Do not add a large collection of boolean flags when nullable regions or
  typed presentation objects communicate the intent more clearly.
- [ ] Ensure a consumer can skip the shell and use a normal Flutter `Scaffold`.

  ```dart
  class CardMenuPage extends StatelessWidget {
    const CardMenuPage({super.key});

    @override
    Widget build(BuildContext context) => Scaffold(
      body: GridView(
        children: const [
          AccountMenuCard(),
          ReportsMenuCard(),
          SettingsMenuCard(),
        ],
      ),
    );
  }
  ```

## Phase 4: app-bar behavior

- [ ] Keep the four package-owned global actions:
  - brightness selector;
  - theme color selector;
  - language selector;
  - configuration display.
- [ ] Continue controlling their global availability through
  `core.config.yaml`.
- [ ] Treat each global `enabled` value as the default for pages that do not
  provide an override.
- [ ] Add a typed per-page override map to `GichoAppBar`:

  ```dart
  enum GichoAppBarFeature {
    brightnessToggle,
    themeSelector,
    languageSelector,
    configurationDisplay,
  }

  GichoAppBar(
    title: const Text('Example'),
    actionOverrides: const {
      GichoAppBarFeature.languageSelector: false,
      GichoAppBarFeature.configurationDisplay: true,
    },
  )
  ```

- [ ] Resolve each standard action with
  `page override ?? global configuration ?? package default`.
- [ ] Keep per-page overrides in Dart beside the page that uses them. Do not
  add page names, paths, or page-specific overrides to YAML.
- [ ] Let each page choose whether it uses `GichoAppBar` at all.
- [ ] Let each page suppress all standard actions without changing global
  configuration.
- [ ] Let each page provide its own leading widget, including a back button.
- [ ] Let each page add consumer-owned actions in Dart.

  ```dart
  GichoAppBar(
    title: const Text('Orders'),
    actions: [
      IconButton(
        tooltip: 'Create order',
        onPressed: createOrder,
        icon: const Icon(Icons.add),
      ),
    ],
  )
  ```

- [ ] Do not infer a hamburger icon or back arrow from a YAML route name.

## Phase 5: route and page responsibilities

- [ ] Keep route declarations and stable route names in consumer-owned Dart
  passed to `GichoRouter`.
- [ ] Use router code to decide whether a page is pushed normally, displayed as
  a dialog, uses a full-screen dialog page, or has custom transitions.
- [ ] Use page code to select its visible shell regions.
- [ ] Demonstrate these three cases:
  1. a standard page with app bar, drawer, content, and footer;
  2. a modal page with a back button, content, no drawer, no footer, and no
     global app-bar actions;
  3. a content-only page that supplies its navigation as cards and uses none of
     the package shell regions.

The complete responsibility split should be visible in code:

```dart
// The router decides that this is a modal route.
GoRoute(
  path: '/edit-profile',
  pageBuilder: (context, state) => MaterialPage(
    fullscreenDialog: true,
    child: const EditProfilePage(),
  ),
)

// The page decides which visual regions it displays.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) => GichoPageShell(
    appBar: GichoAppBar(
      title: const Text('Edit profile'),
      leading: const BackButton(),
      showStandardActions: false,
    ),
    body: const EditProfileForm(),
  );
}
```

## Phase 6: refactor `example.everything`

- [ ] Keep its current navigation shell in the example project; do not migrate
  that layout into the package.
- [ ] Replace repeated scaffold composition with the optional package page
  shell only where doing so makes the demonstration clearer.
- [ ] Keep the example's drawer entries, bottom navigation destinations, rail
  behavior, page IDs, and route table in example-owned Dart.
- [ ] Add a modal example showing a back arrow and no footer, drawer, or
  app-bar actions.
- [ ] Add or preserve a content-driven example proving the shell is optional.
- [ ] Explain in the example README that its layout is one demonstration, not
  a Gicho requirement.

## Configuration boundary

Keep `core.config.yaml` limited to global package behavior, currently:

```yaml
appBar:
  actions:
    brightness:
      enabled: true
    theme:
      enabled: true
    language:
      enabled: true
    configDisplay:
      enabled: true
```

Do not add route paths, route builders, page IDs, drawer entries, footer tabs,
or per-page shell settings to this file during this refactor.

The global app-bar values are defaults. Pages may override individual standard
actions in Dart through `GichoAppBar.actionOverrides`; those page-specific
choices do not belong in YAML.

If a future requirement demonstrates that non-code presentation overrides are
valuable, design that separately after the Dart API is stable.

## Acceptance criteria

- [ ] A consumer can use `GichoMaterialApp.router` with entirely custom
  layouts.
- [ ] A consumer can use the optional page shell for consistent regions.
- [ ] A consumer can mix shell-based and ordinary Flutter pages in one router.
- [ ] Every simple-mode application routes through `GichoRouter` and
  therefore uses the package-supported GoRouter version and standard defaults.
- [ ] Advanced consumers can access the underlying `GoRouter` without replacing
  the Gicho application foundation.
- [ ] Simple consumer code uses `GichoNotifications` and does not reference
  `ToastificationWrapper` directly.
- [ ] A route can present a full-screen modal with a back button and no other
  shell regions.
- [ ] Package configuration controls the four global app-bar features only.
- [ ] Any page can explicitly enable or disable each standard app-bar feature,
  regardless of its global default.
- [ ] No package code imports or knows about `example.everything` navigation.
- [ ] `main.dart` remains tiny.
- [ ] `flutter analyze` succeeds for the package and affected examples.
- [ ] The user runs the relevant test suites after linting succeeds.

## Recommended implementation order

1. Finalize and document the `GichoMaterialApp` boundary.
2. Build the `GichoRouter` facade over GoRouter.
3. Add the `GichoNotifications` facade over Toastification.
4. Design the smallest useful page-shell Dart API.
5. Add per-page control over standard app-bar actions in Dart.
6. Refactor only the suitable example pages onto the shell.
7. Add modal and content-only demonstrations.
8. Run `flutter analyze` and hand test execution to the user.
