# Configured startup

`GichoStartup` owns the complete company, product and live initialization
sequence. Applications supply a validated Gicho configuration map, their
startup callback, the ready-page builder, and app-owned copy. They do not need
their own splash widgets or progress panel.

`GichoStartupConfiguration.fromConfiguration` reads `app.startup` from the
merged Gicho YAML. Images are application assets; provide portrait and
landscape paths in pairs for each stage. Gicho selects portrait below 768
logical pixels and landscape at wider sizes. `GichoStartupLabels` lets a
consumer pass its centralized translated copy without embedding localization
tables in this construct.

`productPortraitSceneAsset` and `productLandscapeSceneAsset` form the default
scene. Ordered `scheduledProductScenes` may override it. Each entry has an
inclusive `start` and `end` in `MM-DD` for annual recurrence or `YYYY-MM-DD`
for a one-time range, plus portrait and landscape asset paths. An optional
`countries` list limits the scene to ISO 3166-1 alpha-2 country codes; an
entry without it applies globally. The first matching entry wins. The
startup date is captured once from the device's local calendar. Unknown
country never matches a country-limited entry. The selected product scene
also appears behind live progress unless a separate loading pair is set.
