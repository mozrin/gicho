# Gicho changelog

## 0.1.0 — 2026-11-16

Initial public Gicho source release, derived from the audited Flackage 0.0.14
snapshot without private Git history. One MIT-licensed root package, bundled
localization and themes, seven maintained examples, tropical gecko branding,
and repository-local publication/verification tooling.

The package entry is package:gicho/gicho.dart. Configuration, API prefixes,
imports, asset names and persisted preference prefixes use Gicho naming.
Existing Flackage repositories and consumers, including Orchard, are unchanged.
See docs/migration.md for deliberate consumer migration and preference continuity.

Localization also restores the documented English app-catalog fallback when a
selected-language app key is missing, with interpolation and unknown-key
regression coverage.

Example corrections include inherited bootstrap expectations, Material-backed
slider controls and credential-free, explicitly labelled offline place lookup.
Provider-specific attribution, catalog integrity and adapter session/error tests
are included. Web scaffolding supports host verification of all seven apps.
See docs/validation.md for exact checks and service/hardware limits.

Version rationale: Gicho has no prior published consumer contract. Its initial
repository baseline is 0.0.0; the first functional package release is 0.1.0 under
the shared first-feature rule. Flackage versions are provenance, not Gicho's
version history. The rename is a deliberate migration for opt-in consumers,
not an in-place breaking update to existing Flackage users.

## Historical source records

> Historical source-baseline record, renamed for readability. These entries
> describe the source before Gicho; they are not Gicho release or validation evidence.

## Unreleased

- Consolidate the generic Flutter foundation into the root `gicho` package.
- Rename the public import to `package:gicho/gicho.dart`; migrate existing
  `gicho_ui` dependencies and imports together with consumer lockfiles.
- Preserve configuration, localization, startup, theme and UI behavior.

## 0.0.1

* TODO: Describe initial release.
