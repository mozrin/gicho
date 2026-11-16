## Unreleased

- Add a provider-neutral store-entitlement facade with validated configuration,
  Qonversion adapter, background initialization, identity transitions,
  products, purchases, restore, observation, stale state, typed failures,
  Riverpod access, lifecycle logging, and test seams.
- Allow consuming apps to bound normalized photo resolution before cropping.
- Add app-neutral photo selection, camera capability/capture, EXIF
  normalization, and fixed-ratio crop foundations with typed failures,
  injectable adapters, and lifecycle logging.

## 0.0.1

- Initial Gicho package and example application.
- Single public entry point at `package:moztopia/gicho.dart`.
- Re-exports for assets, forms, localization, logging, networking,
  notifications, routing, state, storage, and themes.
- Schema-validated feature configuration with configured logging as the first
  implementation.
