# Publication audit

Execute `python3 tools/publication_audit/publication_audit.py` from the repository
root before staging/publishing copied material. This standard-library tool requires
Git and Python 3.10+. It inspects tracked and nonignored untracked candidates,
including hidden and binary files, and reports only filenames and rule names.
It never echoes matched secrets. Ignored local files are outside publication;
force-tracked ignored files are still inspected.

Execute regression tests with
`python3 -m unittest discover -s tools/publication_audit -v`.

This pattern gate supplements human review of provenance, licenses, assets,
configuration fields and manifests. It cannot establish universal secret absence
or redistribution rights. Review any new Git dependency before changing its gate.
