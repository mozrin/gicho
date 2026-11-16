# One self-contained Flutter package

Gicho is the root `gicho` package, with public entry `package:gicho/gicho.dart`.
Internal application, feature, UI, service and i18n folders are responsibilities,
not companion packages. Existing source organization is preserved during the
rename. All 20 package catalogs are bundled in lib/src/i18n; consumers supply
application overrides in their own catalogs. No first-party repository fetch or
remote catalog server is needed for normal package startup, tests or builds.

The seven maintained apps under examples/ depend on the repository root using
`path: ../..`. Historical snapshots under legacy/ are unmaintained references,
excluded from analysis and disconnected from the supported dependency graph.
Do not run their old pubspecs as current examples.

See [migration](migration.md), [localization](localization.md) and
[source provenance](provenance.md). No existing consumer has been migrated.
