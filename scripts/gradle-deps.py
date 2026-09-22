#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Generate GRADLE_DEPS for gradle.eclass from a Gradle cache.

Usage: gradle-deps.py GRADLE_USER_HOME [--ebuild FILE]

Run the build once online with its own --gradle-user-home, then point this
at that directory.  Every artifact Gradle resolved is written out as

	group:artifact:version:filename[:repository]

with the repository worked out by asking each of Maven Central, the
Gradle plugin portal and Google which one serves the file.  With --ebuild
the GRADLE_DEPS="..." block in FILE is replaced in place.
"""

import argparse
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

REPOS = [
    ("central", "https://repo1.maven.org/maven2"),
    ("plugins", "https://plugins.gradle.org/m2"),
    ("google", "https://dl.google.com/dl/android/maven2"),
]

ap = argparse.ArgumentParser(description=__doc__,
                             formatter_class=argparse.RawDescriptionHelpFormatter)
ap.add_argument("gradle_home", type=Path)
ap.add_argument("--ebuild", type=Path)
ap.add_argument("--jobs", type=int, default=16)
ap.add_argument("--strict", action="store_true",
                help="fail if any artifact is absent from the known repositories")
args = ap.parse_args()

cache = args.gradle_home / "caches" / "modules-2" / "files-2.1"
if not cache.is_dir():
    sys.exit(f"{cache}: no Gradle module cache there")

# <group>/<artifact>/<version>/<sha1>/<file>
found = set()
for f in cache.glob("*/*/*/*/*"):
    if not f.is_file():
        continue
    group, artifact, version = f.parts[-5:-2]
    found.add((group, artifact, version, f.name))

print(f"{len(found)} artifacts in {cache}", file=sys.stderr)


def serving_repo(dep):
    """Which repository serves this file, or None if none of them do."""
    group, artifact, version, name = dep
    path = f"{group.replace('.', '/')}/{artifact}/{version}/{name}"
    for repo, base in REPOS:
        req = urllib.request.Request(f"{base}/{path}", method="HEAD")
        try:
            with urllib.request.urlopen(req, timeout=60):
                return repo
        except (urllib.error.HTTPError, urllib.error.URLError, OSError):
            continue
    return None


with ThreadPoolExecutor(max_workers=args.jobs) as pool:
    repos = list(pool.map(serving_repo, sorted(found)))

lines, missing = [], []
for dep, repo in zip(sorted(found), repos):
    group, artifact, version, name = dep
    if repo is None:
        missing.append(f"{group}:{artifact}:{version}:{name}")
        continue
    entry = f"{group}:{artifact}:{version}:{name}"
    lines.append(entry if repo == "central" else f"{entry}:{repo}")

for m in missing:
    print(f"not served by any known repository, add by hand: {m}", file=sys.stderr)
if args.strict and (missing or not found):
    sys.exit("unresolved or empty Gradle dependency cache")

block = 'GRADLE_DEPS="\n' + "".join(f"\t{line}\n" for line in lines) + '"'

if args.ebuild:
    import re
    text = args.ebuild.read_text()
    text, n = re.subn(r'^GRADLE_DEPS="[^"]*"', lambda _: block, text, count=1, flags=re.M)
    if not n:
        sys.exit(f"{args.ebuild}: no GRADLE_DEPS block found")
    args.ebuild.write_text(text)
    print(f"wrote {len(lines)} artifacts to {args.ebuild}", file=sys.stderr)
else:
    print(block)
