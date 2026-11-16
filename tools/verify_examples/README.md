# Maintained example verification

Execute `python3 tools/verify_examples/verify_examples.py` from the repository.
It checks the root package (including colocated lib/ tests) and all seven
maintained examples. Add `--build-web` for explicit development web builds.
The script executes the displayed Flutter commands sequentially, preserves
all outcomes, and exits nonzero if any check fails.

Requirements: existing Python 3.10+, Flutter/Dart and Git on PATH. Nothing is
installed by this script. It writes local logs/results under ignored
build/verification/; do not publish raw logs. Inspect results.json and individual
logs, then record only reviewed, sanitized evidence in docs/validation.md.

Builds do not establish functional acceptance. Run each app in Chrome or an
appropriate supported native target and exercise its documented scenario.
External-service credentials and physical camera/device acceptance are separate.
