# Gallery features

These are app-owned scenarios in the older interactive gallery. Each feature
has a named folder, a public `index.dart`, and its own README.

- [`component_gallery/`](component_gallery/README.md) owns the gallery screen,
  demo settings, and its navigation callbacks.
- [`startup_demo/`](startup_demo/README.md) owns simulated startup results used
  by the gallery to exercise Gicho's startup widgets.

The gallery remains a broad showcase while independent examples under
[`examples/`](../../../README.md) show one scenario per app. New consumer apps
should put their own screens under `lib/features/<feature>/` and import
Gicho through its public package entry point.
