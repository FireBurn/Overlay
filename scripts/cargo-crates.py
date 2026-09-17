#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Generate CRATES for cargo.eclass from a Cargo.lock.

Usage: cargo-crates.py Cargo.lock [--ebuild FILE]

With --ebuild, the CRATES="..." block in FILE is replaced in place.  Git
dependencies are reported on stderr; they need GIT_CRATES.
"""

import argparse
import re
import sys
import tomllib
from pathlib import Path

ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
ap.add_argument("lockfile", type=Path)
ap.add_argument("--ebuild", type=Path)
args = ap.parse_args()

lock = tomllib.loads(args.lockfile.read_text())
crates = sorted({f'{p["name"]}@{p["version"]}' for p in lock["package"]
                 if p.get("source", "").startswith("registry+")})
for p in lock["package"]:
    if p.get("source", "").startswith("git+"):
        print(f'git crate needs GIT_CRATES: {p["name"]} {p["source"]}', file=sys.stderr)
print(f"{len(crates)} crates", file=sys.stderr)

block = 'CRATES="\n' + "".join(f"\t{c}\n" for c in crates) + '"'
if args.ebuild:
    text = args.ebuild.read_text()
    new, n = re.subn(r'^CRATES="[^"]*"', lambda _: block, text, count=1, flags=re.M)
    if not n:
        sys.exit(f"{args.ebuild}: no CRATES block found")
    args.ebuild.write_text(new)
else:
    print(block)
