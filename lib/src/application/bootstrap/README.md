# GichoBootstrap

`GichoBootstrap<T>` runs a consumer-owned asynchronous preparation task
before building the configured application. Gicho supplies a themed splash
and failure/retry view, while `StartupGate<T>` handles retry and ignores stale
completions. The consumer supplies title and status copy, theme, loader and
ready app. `loadingScreen` replaces the default splash. `minimumDurationFor`
uses the resolved configuration to keep that screen visible for a minimum time
measured from the start of loading. A failed load never calls `readyBuilder`.
With `holdNativeLaunch: true`, Gicho defers Flutter's first frame until
configuration succeeds or fails. The consumer can then build configured
introductory scenes without briefly showing an unconfigured Flutter screen.
The native launch is released for a retryable error as well as for success.

```dart
GichoBootstrap<AppConfiguration>(
  load: loadAppConfiguration,
  title: 'My app',
  theme: appTheme,
  failureMessage: 'Could not start.',
  retryLabel: 'Retry',
  readyBuilder: (_, configuration) => MyApp(configuration: configuration),
)
```

The public API is exported by [index.dart](index.dart). Its private loading and
failure presentations are documented in [parts/](parts/README.md). The
bootstrap does not interpret `T`, own a session, choose authentication
providers, install routes or initialize global services. The consumer may place
`GichoMaterialApp` inside `readyBuilder` once its configuration is ready.
