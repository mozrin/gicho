"""Execute package and maintained-example checks with local, inspectable logs."""

import argparse
import json
from pathlib import Path
import subprocess


def main() -> None:
    """Run dependency resolution, analysis, tests and optional debug web builds."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-web', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    output = root / 'build/verification'
    output.mkdir(parents=True, exist_ok=True)
    apps = sorted(path for path in (root / 'examples').iterdir()
                  if (path / 'pubspec.yaml').is_file())
    if len(apps) != 7:
        raise SystemExit('Expected seven maintained examples; review the inventory.')
    results = []
    for package in [root, *apps]:
        name = 'package' if package == root else package.name
        commands = [
            ['flutter', 'pub', 'get'],
            ['flutter', 'analyze'],
            ['flutter', 'test', 'test', 'lib', '--reporter', 'expanded']
            if package == root else ['flutter', 'test', '--reporter', 'expanded'],
        ]
        if args.build_web and package != root:
            commands.append(['flutter', 'build', 'web', '--debug'])
        for index, command in enumerate(commands):
            log = output / f'{name}-{index}.log'
            with log.open('w') as stream:
                result = subprocess.run(command, cwd=package, stdout=stream,
                                        stderr=subprocess.STDOUT)
            results.append({'package': name, 'command': command,
                            'exit_code': result.returncode, 'log': log.name})
            (output / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
            print(f'{name}: {" ".join(command)} => {result.returncode}', flush=True)
    raise SystemExit(1 if any(result['exit_code'] for result in results) else 0)


if __name__ == '__main__':
    main()
