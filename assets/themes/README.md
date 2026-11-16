# Built-in themes

These are permanent Gicho theme definitions. Each YAML file names its
theme and supplies one Material seed color. Gicho generates light and dark
variants from that seed. Consumers select an available subset and default in
their own `assets/gicho/gicho.yaml`; they do not edit these files.

- `default.yaml`: balanced neutral blue.
- `ocean.yaml`: cool teal.
- `ember.yaml`: warm red-orange.

Use `ThemeCatalog.load()` to read these bundled definitions. An app may provide
its own theme definitions through a separate app-owned extension in the future;
the three built-in names and files remain stable.
