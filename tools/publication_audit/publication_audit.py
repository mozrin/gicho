"""Inspect Git publication candidates without printing sensitive matched values."""

import argparse
import json
from pathlib import Path
import re
import subprocess


_SECRET_PATTERNS = {
    'google-api-key': re.compile(rb'AIza[0-9A-Za-z_-]{30,}'),
    'github-token': re.compile(rb'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'),
    'private-key': re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'aws-access-key': re.compile(rb'AKIA[0-9A-Z]{16}'),
    'slack-token': re.compile(rb'xox[baprs]-[A-Za-z0-9-]{20,}'),
}


def _inspect(root: Path) -> dict:
    """Return candidate counts and sanitized findings for a Git checkout."""
    result = subprocess.run(
        ['git', '-C', str(root), 'ls-files', '-z', '--cached', '--others', '--exclude-standard'],
        check=True, capture_output=True,
    )
    paths = sorted(set(result.stdout.decode().split('\0')) - {''})
    findings = []
    for name in paths:
        path = root / name
        if path.is_symlink():
            findings.append({'path': name, 'rule': 'symlink-requires-review'})
            continue
        if not path.is_file():
            continue
        data = path.read_bytes()
        for rule, pattern in _SECRET_PATTERNS.items():
            if pattern.search(data):
                findings.append({'path': name, 'rule': rule})
        if path.suffix.lower() in {'.jks', '.keystore', '.p12', '.pfx', '.pem'}:
            findings.append({'path': name, 'rule': 'credential-file'})
        if name.startswith(('lib/', 'assets/', 'examples/')):
            if re.search(rb'package:flackage|packages/flackage|github\.com/moztopia/flackage', data):
                findings.append({'path': name, 'rule': 'old-active-package-reference'})
        if path.name == 'pubspec.yaml' and not name.startswith('legacy/'):
            if re.search(rb'(?m)^\s+(?:git:|url:.*github\.com)', data):
                findings.append({'path': name, 'rule': 'first-party-git-dependency-requires-review'})
    return {'candidate_files': len(paths), 'findings': findings}


def main() -> None:
    """Print sanitized audit results and fail if a candidate requires review."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    result = _inspect(args.root.resolve())
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if result['findings'] else 0)


if __name__ == '__main__':
    main()
