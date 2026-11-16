# Source provenance and publication audit

Gicho starts from Flackage tag `0.0.14`, commit
`b64283cf617eb07d8365120013789e1487427cec`. No private Git history is imported.
The source copyright holder is `mozrin` (the source commits identify James
Hunter, the authenticated owner of that account). The owner explicitly approved
public MIT licensing of this copied package. Original `Copyright (c) 2026 mozrin`
notices are retained in the MIT grants for the older owner-authored snapshots;
the localization snapshot retains `Copyright (c) 2026 Moztopia` and its MIT license.
The original repositories, branches and consumers are unchanged.

## Ancillary inventory

Read-only review on 16 November 2026 found:

- `moztopia/flackage-localization` main:
  `faf86e287a69c1df6ad488825d02923650d38b1b`. Its eight example catalogs were
  already embedded at the earlier snapshot revision `7d71c37` under legacy/.
  Current additions are Orchard-owned catalogs, which are not needed or copied.
- `moztopia/flackage-examples` develop:
  `d2c8950224d866df004e94032cc55fd86dae0fa6`. Already embedded under legacy/.
  Working-tree lockfiles and local analysis overrides are not release inputs.
- `moztopia/flackage-extensions` develop:
  `88a32cb327929f3ecd5cdcbec1d8869b2cc13cc2`. Already embedded under legacy/.
  Mock authentication and animated startup extensions are historical references;
  Gicho's current startup API and bundled catalogs need no extension package.

The active package already has 20 in-source locale catalogs and no first-party
Git dependency. Gicho ships one root package; legacy pubspecs describe historical
code, not supported companion packages or a build/install requirement.

## Sanitization and attribution

The known Google API key in the place-lookup example was removed before any
source commit. No key value is recorded here. Configuration is user supplied.
Token/private-key/cloud-key patterns and credential-like configuration fields
are inspected without echoing secret values. Dependency manifests, URLs,
hidden files and binary assets are included in review. Old private-development
hostnames are replaced with example domains in copied documentation.

The obsolete ancillary localization logo is omitted: Gicho uses its own
owner-approved gecko artwork. Flutter-generated platform scaffolding/icons
retain the Flutter SDK license under third_party/flutter/LICENSE. This does
not grant rights to Flutter's trademarks. Other runtime dependency licenses
remain owned and supplied by their respective packages.

Historical snapshots have been mechanically renamed and sanitized, not upgraded
or accepted as current examples. Original source revisions above identify their
provenance; historical claims in old checkpoint notes are not Gicho validation.
No automated scan proves the absence of every possible secret or private datum;
pattern scanning is paired with manifest/configuration/asset review.

by-dolly
