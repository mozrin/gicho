"""Verify a numeric public source tag with fresh caches and no Git helpers."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def main() -> None:
    """Resolve and test Gicho anonymously, retaining only local verification logs."""
    root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ref', default=(root / 'VERSION').read_text().strip())
    args = parser.parse_args()
    if not re.fullmatch(r'\d+\.\d+\.\d+', args.ref):
        raise SystemExit('A numeric immutable source tag is required.')
    output = root / 'build/verification/public-consumer'
    output.mkdir(parents=True, exist_ok=True)
    fixtures = Path(__file__).parent / 'fixtures'
    with tempfile.TemporaryDirectory(prefix='gicho-public-consumer-') as directory:
        scratch = Path(directory)
        app = scratch / 'app'
        (app / 'test').mkdir(parents=True)
        (app / 'pubspec.yaml').write_text(
            (fixtures / 'pubspec.template').read_text().replace('__REF__', args.ref)
        )
        shutil.copyfile(fixtures / 'consumer_test.dart', app / 'test/consumer_test.dart')
        (app / 'analysis_options.yaml').write_text('include: package:flutter_lints/flutter.yaml\n')
        empty_config = scratch / 'empty-git-config'
        empty_config.write_text('')
        environment = os.environ.copy()
        for name in ['GH_TOKEN', 'GITHUB_TOKEN', 'GIT_ASKPASS', 'SSH_ASKPASS']:
            environment.pop(name, None)
        environment.update({
            'PUB_CACHE': str(scratch / 'pub-cache'),
            'GIT_CONFIG_GLOBAL': str(empty_config),
            'GIT_CONFIG_NOSYSTEM': '1',
            'GIT_CONFIG_COUNT': '2',
            'GIT_CONFIG_KEY_0': 'credential.helper',
            'GIT_CONFIG_VALUE_0': '',
            'GIT_CONFIG_KEY_1': 'credential.interactive',
            'GIT_CONFIG_VALUE_1': 'false',
            'GIT_TERMINAL_PROMPT': '0',
        })
        commands = [
            ['flutter', 'pub', 'get'], ['flutter', 'analyze'],
            ['flutter', 'test', '--reporter', 'expanded'],
        ]
        for index, command in enumerate(commands):
            with (output / f'{index}.log').open('w') as log:
                result = subprocess.run(command, cwd=app, env=environment,
                                        stdout=log, stderr=subprocess.STDOUT)
            print(f'{" ".join(command)} => {result.returncode}', flush=True)
            if result.returncode:
                raise SystemExit(result.returncode)
        refs = subprocess.check_output(
            ['git', 'ls-remote', 'https://github.com/mozrin/gicho.git',
             f'refs/tags/{args.ref}', f'refs/tags/{args.ref}^{{}}'],
            env=environment, text=True,
        ).splitlines()
        if not refs:
            raise SystemExit('Published source tag is missing.')
        commit = next((line.split()[0] for line in refs if line.endswith('^{}')),
                      refs[0].split()[0])
        resolved = re.findall(r'resolved-ref:\s*["\x27]?([0-9a-f]{40})',
                              (app / 'pubspec.lock').read_text())
        if resolved != [commit]:
            raise SystemExit('Resolved Git dependency does not match the exact source tag.')
        report = {'tag': args.ref, 'commit': commit, 'isolated_pub_cache': True,
                  'git_credential_helpers': False, 'checks': commands, 'passed': True}
        (output / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
