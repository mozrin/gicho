# Gicho Flutter example

`lib/main.dart` only starts the app. `lib/app.dart` returns
`GichoMaterialApp` directly with its locale, theme and home. The existing
interactive gallery screen lives in
[`lib/features/component_gallery/`](lib/features/component_gallery/README.md),
so scenario controls do not obscure application setup. Focused examples have
their own directories under [`examples/`](../README.md). This gallery has one
entrypoint and does not hide another app in `lib/`.

This independent app exercises the public `gicho` package. The component
gallery keeps the distance slider interactive. Open its navigation drawer and
select **Startup demo** to run `StartupGate` and `StartupSplash` through signed-out,
signed-in, failure and retry states. The simulated session is app-owned;
Gicho has no authentication dependency or account policy.

The demo also uses `GichoLocaleController` with an app-owned English catalog
and renders the shared language picker. Only English is enabled in this demo;
the [package registry](../../docs/languages.md) supports 20 languages. The
example can enable another locale after translating its app-owned copy. Its
localization keys live in `lib/i18n/en.dart`; missing
keys would render exactly as written.

The gallery uses `gichoTheme` and `GichoAppShell`. Its **About** action
opens a `GichoModalPage` without the shell's ancillary navigation. The same
destinations appear in a dismissible drawer at phone/tablet widths and an
extended sidebar at large widths; the example owns the route to Startup demo.
Package widget tests cover 390, 900 and 1400 logical-pixel widths, Escape
dismissal and focus restoration.

Run `flutter analyze` and `flutter test` here. The startup test follows the
rendered gallery navigation, sign-in handoff, failure and retry path. The
package tests cover loading and ignoring a late result from an old context.
The router composition test shows an app-owned `RouterConfig` passed to
`GichoMaterialApp.router` without a Harmony dependency.

## Browser development

Run `flutter run -d chrome` to build and launch this app in a browser. Linux
scaffolding is also available. Choose a connected Android device for native
mobile checks. Build/startup alone does not establish interactive acceptance;
exercise this example's documented scenario and see the root validation record.
