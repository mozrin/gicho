# Public tagged consumer acceptance

After publishing the immutable source tag, execute:

`python3 tools/verify_public_consumer/verify_public_consumer.py --ref 0.1.0`

This executes Flutter dependency resolution, analysis and two representative
public-entry tests in a temporary app with a fresh PUB_CACHE. Git credential
helpers/system/global config and interactive prompts are disabled for the child
commands; GitHub token variables are removed. No private first-party dependency
or local package path is used. The resolved Git commit must equal the public tag.

The fixture tests packaged YAML defaults, app-over-package translation precedence,
English fallback, Thai copy and an Arabic RTL application shell. Temporary app/cache
files are removed on exit. Local logs/result.json stay under ignored
build/verification/public-consumer/; publish only a reviewed result summary.

Requirements: existing Python 3.10+, Flutter/Dart, Git and network access to GitHub
and pub.dev. This script installs no workstation tooling or Git credentials.
