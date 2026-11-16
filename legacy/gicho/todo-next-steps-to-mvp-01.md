# Next steps to MVP 01

## Assessment

Gicho is close to an **internal MVP candidate** for its simple-mode
foundation. The important shape is now present:

- one public import;
- `GichoBootstrap` for package startup and optional systems;
- `GichoMaterialApp.router` for theme-aware Material routing;
- `GichoRouter` as the GoRouter standardization point;
- `GichoNotifications` as the notification integration point;
- optional `GichoPageShell` and `GichoAppBar` building blocks;
- YAML-backed global app-bar defaults with page-level Dart overrides;
- a comprehensive example and a minimal example with every Flutter platform
  target.

The package is **not yet a release-ready MVP** because several public decisions
are still fresh, verification of the new foundation is thin, and top-level
documentation still describes older startup patterns. The next goal is not to
add more features. It is to make the current simple-mode experience stable,
truthful, documented, and repeatable.

## MVP 01 definition

MVP 01 should promise one thing clearly:

> A consumer can build a Flutter app with Gicho-owned startup, theming,
> routing, optional localization, and optional notifications, while keeping
> routes and layout in ordinary consumer Dart.

It should not promise server configuration sync, generated API clients,
advanced theme customization, a mandatory navigation shell, or automatic
notification delivery. Those are later work.

## What is already strong enough to keep

- Keep `GichoBootstrap` as the simple-mode foundation.
- Keep `GichoMaterialApp` free of injected layout.
- Keep consumer routes in Dart and configuration out of the route table.
- Keep `GichoPageShell` optional.
- Keep global app-bar feature defaults in core YAML and page exceptions in
  Dart.
- Keep a package-owned GoRouter version and a `GichoRouter` facade.
- Keep feature runtime state in feature folders:

  ```dart
  GichoLocalization.of(context).isAvailable
  GichoNotifications.of(context).isAvailable
  ```

- Keep `example.minimal` as the normal adoption story and
  `example.everything` as a showcase rather than a starting requirement.

## Release blockers — complete before calling it MVP 01

### 1. Freeze the simple-mode public API

Decide the final names and defaults before other applications adopt them. The
current bootstrap uses `localizationsEnabled` and `notificationsEnabled`; these
names and defaults must be intentional, documented, and covered by tests.

Recommended minimal consumer shape:

```dart
class GichoApp extends StatelessWidget {
  const GichoApp({super.key});

  @override
  Widget build(BuildContext context) => GichoBootstrap(
    child: GichoMaterialApp.router(router: appRouter),
  );
}
```

Applications opt into optional systems explicitly:

```dart
GichoBootstrap(
  localizationsEnabled: true,
  notificationsEnabled: true,
  child: GichoMaterialApp.router(router: appRouter),
)
```

MVP 01 default policy is settled: **every optional system starts off**.
Localization, notifications, and the four standard app-bar features require an
explicit consumer choice to turn them on. The only default behavior is the
non-optional foundation needed to start a themed Flutter application with its
consumer-owned router. This gives organization applications a reproducible
starting point without a preselected layout or a process of turning features
off before real work can begin.

The README must show these exact defaults, not merely optional parameters.

### 2. Define exact runtime-state semantics

`isAvailable` must have one precise meaning per feature.

- Localization: `true` means the localization provider is installed below the
  current context and translation lookup can be used.
- Notifications: `true` means the notification UI layer is installed below the
  current context.

Do not describe `isAvailable` as a guarantee that a remote catalog is current,
that the network works, or that a toast call will succeed in every situation.
Document the distinction between **installed**, **ready**, and future states
such as **loading** or **failed** if those are introduced later.

### 3. Define notifications as an opt-in application capability

`notificationsEnabled: false` means the application was built without the
Gicho notification layer. It is a starting-composition choice, made before
the consumer writes notification-dependent UI. It is not a runtime kill switch,
and it does not promise that a finished application can disable notifications
after it has implemented calls to Toastification or other notification APIs.

For MVP 01, document this contract plainly:

- Start with notifications off when the application does not need them.
- Turn notifications on before writing notification behavior.
- Once an application depends on notifications, it should keep the layer
  enabled or deliberately remove that behavior as part of a normal refactor.
- `GichoNotifications.of(context).isAvailable` is useful for components
  that are intentionally reusable in both kinds of application; it is not a
  workaround for turning off an already-adopted feature.

### 4. Add foundation-focused tests

The package has solid tests for configuration, localization parsing, logging,
and exports. It needs direct tests for the new foundation APIs.

- [ ] `GichoBootstrap` initializes core/theme/logging before its child is
  shown.
- [x] Localization disabled: no English catalog is required, and
  `GichoLocalization.of(context).isAvailable` is false.
- [x] Localization enabled with no `assets/gicho/en.json`: startup continues
  with an empty fallback map and logs a warning.
- [ ] Localization enabled with `{}` English: startup succeeds and availability
  is true.
- [x] Notifications enabled and disabled publish the correct availability
  state.
- [ ] `GichoLocalization.of` and `GichoNotifications.of` give a clear
  error outside `GichoBootstrap`.
- [ ] `GichoMaterialApp.router` uses the configured theme and respects the
  localization system state.
- [ ] `GichoRouter` accepts a consumer route and exposes its underlying
  `GoRouter`.
- [x] `GichoPageShell` renders only regions supplied by the consumer.
- [x] `GichoAppBar` resolves
  `page override → global YAML default → package default` correctly.

### 5. Test the examples as real consumers

The examples are part of the public product, not merely developer scratch
space.

- [x] Update `example.minimal` to keep its `GichoRouter` in a stable field
  or top-level value rather than constructing a new router inside `build`.
- [x] Add a small widget test to `example.minimal` that proves the bootstrap
  states shown on screen match its configured values.
- [ ] Keep `example.everything` tests using the public foundation path wherever
  practical; reserve manual initialization for a focused fixture only.
- [ ] Run `flutter test` for the package, `example.minimal`, and
  `example.everything` before release.
- [ ] Smoke-build at least web and one desktop/mobile target from the examples
  in CI. Analyze alone does not prove generated platform runners build.

### 6. Make documentation match the current API

The top-level README and several feature READMEs still show older patterns such
as direct `GoRouter`, direct notification wrappers, or manual feature startup.
Replace those with one canonical quick start.

```dart
void main() => runApp(const GichoApp());

class GichoApp extends StatelessWidget {
  const GichoApp({super.key});

  @override
  Widget build(BuildContext context) => GichoBootstrap(
    child: GichoMaterialApp.router(router: appRouter),
  );
}
```

The documentation must also state clearly:

- localization is optional and requires `assets/gicho/en.json` only when
  `localizationsEnabled: true`;
- `{}` is a valid English catalog;
- `GichoPageShell` and `GichoAppBar` are optional;
- routes and page layout remain consumer-owned;
- `GichoRouter` standardizes GoRouter but does not replace its full API;
- notification availability is queryable and what disabled notifications mean.

Update stale language that says English is always mandatory, that
`GichoMaterialApp` initializes everything itself, or that a consumer should
use `ToastificationWrapper` at the root.

### 7. Establish repeatable CI and release checks

Before an MVP tag, add a visible automated workflow that runs on pull requests
and release branches:

```text
flutter analyze                 # package
flutter test                    # package
flutter analyze                 # example.minimal
flutter test                    # example.minimal
flutter analyze                 # example.everything
flutter test                    # example.everything
flutter build web               # at least one example
```

Add platform builds gradually if the current CI runners support them. The
important MVP property is that a clean checkout has one authoritative,
automated validation path.

### 8. Prepare release metadata

- [ ] Update `CHANGELOG.md` with the actual MVP 01 public API.
- [ ] Confirm the package name (`moztopia`) and repository-facing name
  (Gicho) are explained consistently.
- [ ] Decide whether this is private Git-only distribution or a future
  pub.dev-ready package; document the supported installation path only.
- [ ] Tag a tested commit and pin examples to the intended compatible package
  version/ref for release verification.
- [ ] Ensure the README points to both `example.minimal` and
  `example.everything`.

## Important but not release-blocking

### Navigation shell

Follow [`todo-nav-shell.md`](todo-nav-shell.md), starting with removal of
unnecessary local example boilerplate. Do not make `GichoNavigationShell` a
release requirement. The current optional page shell is enough for MVP 01.

### Advanced theme mode

The simple theme tier is a good MVP boundary. Keep advanced component,
typography, and per-widget theme customization out of MVP 01 until its
configuration contract is designed separately.

### Remote configuration and resource sync

The ideas in `TODO.md` are substantial future product work. They need a
security, cache, atomicity, and offline policy of their own. Do not merge them
into the MVP foundation just because configuration already exists.

### Generated API clients

Likewise, OpenAPI generation should be its own proposal and release milestone.
It should not be coupled to the stable startup API.

## Suggested release sequence

1. Freeze the bootstrap defaults and public names.
2. Finish foundation and example tests.
3. Repair all stale documentation around the canonical quick start.
4. Add CI that runs analyze, tests, and a representative build.
5. Update changelog and release notes.
6. Run the full release checklist from a clean checkout.
7. Tag the first MVP release.

## MVP 01 exit checklist

- [ ] A new consumer can copy the minimal example and run it.
- [ ] A consumer can enable or disable localization and notifications with
  clear behavior and clear errors.
- [x] A descendant widget can query real feature availability.
- [ ] Theme, routing, and core app-bar features work through public APIs only.
- [ ] Every documented quick-start symbol exists and compiles.
- [ ] Package and examples pass analyze and their test suites.
- [ ] CI verifies that result on a clean checkout.
- [ ] Release notes explain what MVP 01 supports and what remains future work.
