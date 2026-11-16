# Themes

Gicho permanently supplies Default, Ocean and Ember in
[`assets/themes/`](../../../assets/themes/README.md). The [catalog](catalog/README.md)
loads their seed colors and builds both light and dark Material themes through
the [theme builder](theme_builder/README.md). There is no Harmony palette in
these generic definitions.

The [controller](controller/README.md) accepts the app's configured available
subset and default, restores a device-local user choice, and follows system
appearance until the user selects Light or Dark. Pass the same controller to
`GichoMaterialApp(themes: themes, ...)` and the shared
[`ThemePicker`](picker/README.md). The picker owns its translated labels in
Gicho's central catalogs. The
[independent example](../../../examples/flutter-themes/README.md) shows the
complete startup composition.

The existing `gichoTheme(seedColor: color)` builder remains available when
an app needs a custom seed color without the named-theme controller.
For an application-owned palette, the [mode-only controller](mode_controller/README.md)
persists account-scoped light/dark/system selection without a named theme.
