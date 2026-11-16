# Gicho 0.1.0 validation

The final code checkpoint is `f06f5da9fc562f1ab8daabd1c3f400094911afb5`.
Subsequent release preparation changes version metadata, documentation and the
public-consumer verification tool, not the validated package/example code.
Environment: Flutter 3.47.6, Dart 3.13.5, Linux x64 and Chrome; no workstation
tooling was installed. [Machine-readable evidence](validation-results.json)
records exact check commands and the resolved dependency versions tested.

## Package and all maintained examples

All **31 checks passed** after correcting the English app-catalog fallback:
package dependency resolution, analysis and tests, plus dependency resolution,
analysis, tests and development JavaScript web builds for all seven apps.
The package has **80 passing tests**, including colocated lib/ tests. The apps
have **18 passing tests**: gallery 3, bootstrap 5, distance slider 1, page flow 1,
place lookup 2, scanner 4 and themes 2. Four publication-gate regression tests
also pass. All 20 bundled catalogs have matching keys/placeholders; tests cover
application override precedence, English fallback, interpolation and Arabic RTL.

Execute `python3 tools/verify_examples/verify_examples.py --build-web` to repeat
those checks. Execute `python3 -m unittest discover -s tools/publication_audit -v`
and `python3 tools/publication_audit/publication_audit.py` for the source gate.
Generated locks, builds and raw logs remain local and untracked.

## Runtime checks

Every maintained app was built and launched in Chrome debug mode, with actual
browser interactions rather than compilation alone:

- Gallery: no-limit selection updates the saved value; simulated sign-in moves
  startup to its home-ready state.
- Bootstrap: packaged defaults and consumer YAML load, showing configured copy
  and the approved gecko artwork. Tests separately exercise failure/retry.
- Distance slider: controls render at 390px mobile width without overflow or
  console errors after replacing the painted ListTile ancestor with Material.
- Page flow: About opens as a focused page; Back returns to the shell.
- Place lookup: labelled offline search returns a sample city, selection returns
  an approximate 3 km area, and the exact place ID is withheld. Tests also cover
  zero-radius identity return and provider-specific attribution.
- Scanner: scan route opens, reports unavailable camera and safely cancels.
  This host enumerated zero video-input devices.
- Themes: Ember/Dark selection persists after browser reload.

The gallery also built as a Linux debug executable after the final code fix and
remained running during an eight-second startup observation. Native interaction
is not claimed by that startup observation. GitHub README artwork and wiki links
were browser-verified at desktop and 390px width; the image loaded and the page
had no horizontal overflow.

## External-service and platform limits

Live Google calls were not performed: a user-owned restricted development key
and enabled Google services are required. The example has a clearly labelled
credential-free offline mode. Mocked HTTP tests verify adapter sessions and
errors, not Google's live service. Its development Google adapter is deliberately
blocked in release mode; production apps supply an appropriate secure provider.

Physical QR/barcode decoding, autofocus and torch remain unverified without an
appropriate camera. The web route/error/cancel checks and format/acceptance tests
do not establish physical device behavior. mobile_scanner has no Linux/Windows
camera backend; Google map preview targets Android/iOS/web, with an explicit
unsupported-platform message otherwise. Native Android/iOS/macOS/Windows builds
and Wasm runtime acceptance are outside this available-host verification.
Historical legacy/ snapshots are unmaintained, excluded from analysis and never
part of the supported package dependency graph.

## Publication and clean consumer

The immutable numeric source tag must identify the reviewed develop integration
commit with VERSION and pubspec.yaml both at 0.1.0. Final tag/commit and clean
public-consumer results are recorded after source freeze in
[release issue #4](https://github.com/mozrin/gicho/issues/4) and the
[wiki validation page](https://github.com/mozrin/gicho/wiki/Validation).

After tagging, execute
`python3 tools/verify_public_consumer/verify_public_consumer.py --ref 0.1.0`.
It uses a fresh cache and disables Git credential helpers/prompts and token
variables, then resolves the exact public tag, analyzes, and tests packaged YAML,
translation overrides/fallback and an Arabic RTL shell through the public entry.
Its two fixture tests passed against the candidate before tagging. A Git source
tag is not pub.dev publication, an application deployment or Orchard migration.

by-dolly
