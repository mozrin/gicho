# Gicho documentation

Start with [the root quick start](../README.md), the [wiki](https://github.com/mozrin/gicho/wiki), [migration guide](migration.md), [bundled localization](localization.md), and [validation evidence](validation.md).

The 0.0.9/0.0.10 checkpoint documents below describe the historical source baseline, not Gicho releases.

- [0.0.9 CMS planning checkpoint](0.0.9-checkpoint.md): usable APIs,
  independent examples, checks and deferred navigation work.
- [0.0.10 QR scanner checkpoint](0.0.10-checkpoint.md): generic scan API,
  independent Android example, host evidence and device acceptance limit.

- [Package structure and consumer migration](package-structure.md): the single
  Flutter package, dependency direction, and the former UI package transition.
- [Flutter foundation API](flutter-foundation.md): startup, localization,
  themes, application frames and controlled inputs.
- [Configuration service](../lib/src/services/configuration/README.md):
  schema validation, defaults, consumer assets and invocation overrides.
- [Configuration assets](../assets/README.md): package defaults, app schema
  extension, versioning and a runnable consumer example.
- [Localization](../lib/src/features/localization/README.md) and
  [themes](../lib/src/features/themes/README.md).
- [Branding](../lib/src/features/branding/README.md): resolved name, full logo,
  compact mark and missing-image fallback.
- [Scanner](../lib/src/features/scanner/README.md): embeddable QR and barcode camera
  capture, raw results and platform setup.
- [Supported languages](languages.md): the 20 registered codes, English
  minimum and consumer locale boundary.
- [Application shell](../lib/src/application/app_shell/README.md),
  [modal page](../lib/src/application/modal_page/README.md), and
  [brand header](../lib/src/ui/brand_header/README.md).
- [Distance selector specification](component-slider-distance.md).
- [Focused Flutter examples](../examples/README.md): independent Android and
  Linux apps for bootstrap, the distance slider and a modal page flow.
- [Interactive Flutter gallery](../examples/flutter/README.md): the older
  multi-scenario showcase.
