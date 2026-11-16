# Flutter bootstrap example

This independent Android/Linux app demonstrates one responsibility:
`GichoBootstrap` loads the app's configuration, shows a splash while loading,
offers Retry on failure, and hands the resolved map to `GichoMaterialApp`
with a `GichoAppShell`. The normal loader uses Gicho's package defaults
and this app's YAML/schema assets. A host test injects one failure and verifies
Retry reaches the ready page.

## What to expect

Launch shows the package splash during `load`. With the default loader it
displays a page titled **Bootstrap Example** with **Ready from application
configuration** in its body. The brand and message come from this app's
Gicho configuration. Its full logo is an app-owned PNG; the same image is
used for the compact mark in this small example.
If loading fails, the package shows **Could not start.** and **Retry**;
Retry invokes the same consumer loader again. The test makes that failure
deterministic without a backend.

## Read the app

1. [`lib/main.dart`](lib/main.dart) calls `runApp(buildApp())` and contains no
   startup or page logic.
2. [`assets/gicho/gicho.yaml`](assets/gicho/gicho.yaml) sets the
   brand and app-owned startup message. Its
   [schema](assets/gicho/gicho.schema.json) declares only the app-owned
   key; the generic brand schema remains Gicho-owned.
3. [`lib/app.dart`](lib/app.dart) composes `GichoBootstrap` directly. Its
   `load` calls `GichoConfigurationService.loadApplication`; `readyBuilder`
   returns `GichoMaterialApp` and displays the resolved app value.
4. [`test/app_test.dart`](test/app_test.dart) checks real asset loading and
   injects a failing loader to verify Retry. Gicho owns the splash, retry
   state and stale-result protection; this example owns its YAML, schema and
   application copy.

There is no authentication, network service, Harmony data or provider setup
here. A real consumer replaces the loader and ready content while keeping the
same package boundary. Do not put a second entrypoint in this app's `lib/`.
The theme and locale controller are created once in `buildApp`; the ready app
receives them explicitly. This example uses package locale defaults and a
consumer brand, but does not yet exercise named theme assets.
See the [bootstrap API guide](../../lib/src/application/bootstrap/README.md)
for the loading and retry contract and the
[asset guide](../../assets/README.md) for the inheritance rules.

## Run and verify

From this directory, run `flutter pub get`, `flutter analyze` and
`flutter test`. Run `flutter run -d linux` for the desktop app. For Android,
select an Android target shown by `flutter devices` and run
`flutter run -d <device-id>` on a development device you control. The owner
performs physical-device testing. These targets have separate `android/` and
`linux/` scaffolds; other platforms are outside this example.
