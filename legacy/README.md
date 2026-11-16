> Historical, mechanically renamed source reference. Unmaintained; not a current
> Gicho package, example, remote-catalog workflow or installation instruction.

# Legacy package references

These are historical source snapshots for selective package design and tests.
They are not part of the current Gicho public API or dependency graph.
Generated caches are excluded. The nested `.git` directories were removed;
this snapshot contains readable source without nested repository metadata.

| Snapshot | Original branch and commit | Purpose |
| --- | --- | --- |
| `gicho/` | `9-repair-startup-bootstrap-test` at `daac384` | Earlier shared app foundations, startup, localization, theme and tests. |
| `gicho-extensions/` | `develop` at `88a32cb` | Startup and mock authentication extensions. |
| `gicho-examples/` | `develop` at `d2c8950`, plus local edits to `example.minimal/analysis_options.yaml` and `pubspec.lock` | Example applications and integration behavior. |
| `gicho-localization/` | `wip/testing-the-merge` at `7d71c37` | Historical translation catalogs. |
| `orachard-gicho/` | Working-tree snapshot; no nested Git metadata | Orchard-era package variant and tests. |

Do not import these paths from current packages or consumers. Compare a
specific capability with its current contract, adapt it in the active package,
and verify it with an independent example and a real consumer before adoption.
