# Internal package implementation

This directory contains implementation code that is not part of the supported
public import surface. Expose stable APIs deliberately through `lib/gicho.dart`.

- `application/` composes the whole app: bootstrap, Material app, shell and
  startup feedback.
- `features/` owns capabilities that may combine UI, state and logic.
- `ui/` owns reusable visual building blocks.
- `services/` owns pure reusable services with no UI.
- `i18n/` owns centralized package catalogs.

Ask the owner before adding another top-level group, including `utilities/`.
Avoid empty category folders. Internal source names do not repeat the package name;
the supported public API retains its established names during this move.
