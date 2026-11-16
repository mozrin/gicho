# Migrating from Flackage

Migration is a consumer decision; Gicho's creation does not change existing apps.
Use a reviewed numeric Gicho source tag in your Git dependency, with no package
subdirectory. Replace the dependency key `flackage` with `gicho`, the repository
URL with `https://github.com/mozrin/gicho.git`, and imports with
`package:gicho/gicho.dart`.

Rename `Flackage` prefixes to `Gicho`, `flackage` prefixes to `gicho`, and
`FLACKAGE` prefixes to `GICHO`. Apply the same substitution to app-owned asset
folders, YAML/schema names, preference keys and test fixtures. Existing saved
preferences under old prefixes are not automatically migrated: apps that need
continuity must explicitly copy their old keys before using Gicho controllers.

The copied API behavior is retained. Consumer-owned configuration now lives at
`assets/gicho/gicho.yaml` and optional `assets/gicho/gicho.schema.json`.
Keep both asset declarations and code references aligned. The seven examples
show complete bootstrap, Material app and shell composition.

The package includes its own localization and themes. No localization repository,
companion package or private Flackage credential is needed. Historical extension
APIs are not supported Gicho APIs; use the deliberate exports in lib/gicho.dart.
External authentication and business behavior remain application responsibilities.
Run dependency resolution, analysis, tests and representative runtime checks in
each consumer when it elects to migrate. Orchard has not been migrated.
