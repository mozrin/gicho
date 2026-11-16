"""Regression coverage for the public-copy credential and dependency gate."""

import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from publication_audit import _inspect


class PublicationAuditTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        subprocess.run(['git', 'init', '--quiet', str(self.root)], check=True)

    def tearDown(self):
        self.directory.cleanup()

    def test_detects_google_key_without_returning_its_value(self):
        secret = 'AIza' + 'A' * 35
        (self.root / 'configuration.yaml').write_text('key: ' + secret)
        result = _inspect(self.root)
        self.assertEqual(result['findings'], [
            {'path': 'configuration.yaml', 'rule': 'google-api-key'},
        ])
        self.assertNotIn(secret, json.dumps(result))

    def test_checks_hidden_and_binary_candidates(self):
        (self.root / '.credentials').write_bytes(b'ghp_' + b'A' * 36)
        (self.root / 'image.png').write_bytes(b'\x89PNG\0AKIA' + b'A' * 16)
        self.assertEqual(len(_inspect(self.root)['findings']), 2)

    def test_ignores_untracked_private_configuration_but_checks_tracked_files(self):
        (self.root / '.gitignore').write_text('.env\n')
        (self.root / '.env').write_text('key: ' + 'AIza' + 'A' * 35)
        self.assertEqual(_inspect(self.root)['findings'], [])
        subprocess.run(['git', '-C', str(self.root), 'add', '-f', '.env'], check=True)
        self.assertEqual(_inspect(self.root)['findings'][0]['rule'], 'google-api-key')

    def test_rejects_private_dependencies_in_maintained_examples(self):
        app = self.root / 'examples/demo'
        app.mkdir(parents=True)
        (app / 'pubspec.yaml').write_text('dependencies:\n  old:\n    git: private-source\n')
        self.assertEqual(_inspect(self.root)['findings'][0]['rule'],
                         'first-party-git-dependency-requires-review')


if __name__ == '__main__':
    unittest.main()
