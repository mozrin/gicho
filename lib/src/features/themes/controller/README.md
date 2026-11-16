# ThemeController

Owns a consumer's available named themes, chosen default, user selection and
light/dark/system mode. `restore()` reads the device preference; a saved theme
outside the app's current allowed subset is ignored. `select()` and
`setMode()` notify listeners and save the user's choice. The consumer creates
one controller after loading Gicho configuration and passes it to
`GichoMaterialApp` and `ThemePicker`.
