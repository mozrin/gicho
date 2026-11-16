> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# App foundation

`GichoBootstrap` is the standard package-owned application foundation. It
initializes logging, core configuration, themes, and optional localization, and
can install optional notifications. `GichoMaterialApp.router` below it builds
`MaterialApp.router` with the configured light theme, dark theme, theme mode,
locale, and `GichoRouter`.

It does **not** choose the application's layout. The consumer supplies the
router and owns every page, scaffold, app bar, navigation shell, drawer,
navigation rail, and bottom navigation bar. Package components such as
`GichoAppBar` are opt-in building blocks, not injected UI.

The consumer also owns its `GichoApp` widget. That widget is the place to
wrap the framework app with providers, overlays, or application-specific
behavior:

```dart
class GichoApp extends StatelessWidget {
  const GichoApp({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
    child: GichoBootstrap(
      child: GichoMaterialApp.router(router: appRouter),
    ),
  );
}
```

This leaves the executable entry point deliberately small:

```dart
void main() => runApp(const GichoApp());
```

All optional systems and launch stages start off. Turn one on explicitly when
the application needs it:

```dart
GichoBootstrap(
  startupEnabled: true,
  startupDelegate: StartupProcess(
    startupPreDelayDuration: const Duration(seconds: 2),
    startupPostDelayDuration: const Duration(seconds: 2),
    startupOverlays: [
      (context, state, complete) => StartupAnimation(
        onComplete: complete,
      ),
    ],
    startupQueue: [
      (process: loadConfiguration, type: StartupQueueType.asynchronous),
      (process: warmCache, type: StartupQueueType.asynchronous),
      (process: migrateStorage, type: StartupQueueType.synchronous),
      (process: registerServices, type: StartupQueueType.synchronous),
    ],
  ),
  authenticationEnabled: true,
  authenticationDelegate: ConsumerAuthenticationDelegate(),
  localizationsEnabled: true,
  notificationsEnabled: true,
  child: GichoMaterialApp.router(router: appRouter),
)
```

These switches affect framework setup; they do not choose a page layout.

The existing platform launch-icon process remains unchanged. The startup and
authentication stages are reserved extension points after it. Authentication
has no built-in implementation; an enabled application supplies an
`AuthenticationDelegate` from a Flextension or its own code. Their fixed order
is:

```text
platform launch icon -> startup (when enabled) -> authentication (when enabled) -> app
```

Either stage can be enabled independently.

With no custom startup delegate, Gicho retains the native launch icon for
two seconds, shows its minimal startup page, pauses for three seconds, and then
continues. Mock and real authentication behavior lives
outside Gicho and plugs into the neutral delegate contract.

Startup overlays execute end to end in list order. Each overlay calls its
`complete` callback when it is done. After the last overlay, the configured
overlay-duration pause begins.

Asynchronous queue entries next to one another start together. A synchronous
entry waits for all preceding asynchronous entries and then runs alone. Any
remaining asynchronous entries are awaited at the end. Startup finishes only
when both the overlay branch and queue branch are complete.

When either duration is null in Dart, `assets/gicho/startup.config.yaml` may
override the package defaults:

```yaml
startupPreDelayDurationSeconds: 2
startupPostDelayDurationSeconds: 2
```
