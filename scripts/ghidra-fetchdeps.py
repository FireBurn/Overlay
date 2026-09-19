#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Generate the fetchDependencies SRC_URI block for dev-util/ghidra.

Usage: ghidra-fetchdeps.py GHIDRA_SOURCE_DIR [--ebuild FILE]

Ghidra fetches a set of files that are not in any Maven repository with
gradle/support/fetchDependencies.gradle, which lists each one's name, URL
and sha256.  This reads that list, drops the Windows and macOS-only
files, groups the rest under the USE flag that needs them and writes it
out as GHIDRA_DEP_URIS, replacing the block of the same name in FILE.

The name each file has to be installed under is not always the name it is
served as, so the ebuild maps distfile back to name itself; this only
emits the SRC_URI.
"""

import argparse
import re
import sys
from pathlib import Path

ap = argparse.ArgumentParser(description=__doc__,
                             formatter_class=argparse.RawDescriptionHelpFormatter)
ap.add_argument("source", type=Path)
ap.add_argument("--ebuild", type=Path)
args = ap.parse_args()

gradle = (args.source / "gradle/support/fetchDependencies.gradle").read_text()
props = dict(re.findall(r'^ext\.(Z3\w*)\s*=\s*"([^"]+)"', gradle, re.M))
props["RELEASE_VERSION"] = re.search(
    r"application\.version=(\S+)",
    (args.source / "Ghidra/application.properties").read_text()).group(1)

body = gradle[gradle.index("ext.deps = ["):]
body = body[:body.index("\n]\n")]


def subst(s):
    for k, v in props.items():
        s = s.replace("${" + k + "}", v)
    return s


# which USE flag needs each destination, and which are for other platforms
BY_DEST = {
    "FLAT_REPO_DIR": "",
    "FID_DIR": "fidb",
    "GhidraServer": "server",
    "BSim": "bsim",
    "GhidraDev": "eclipse",
    "Debugger-rmi-trace": "debugger",
    "PyGhidra": "python",
    "SymbolicSummaryZ3": "z3",
}
OTHER_PLATFORM = re.compile(
    r"win_amd64|-win\.|macosx|-osx-|^dbgmodel|^pywin32|^comtypes|^win32more|"
    r"^pybag|^capstone")

groups = {}
for entry in re.findall(r"\[\s*\n(.*?)\n\t\]", body, re.S):
    name = subst(re.search(r'name:\s*"([^"]+)"', entry).group(1))
    url = subst(re.search(r'url:\s*"([^"]+)"', entry).group(1))
    if OTHER_PLATFORM.search(name):
        continue
    dest = re.search(r"destination:\s*(.*)", entry, re.S).group(1)
    if "z3-" in name:
        use = "z3"
    elif "java-sarif" in name:
        use = "sarif"
    elif dest.lstrip().startswith("["):
        # wanted by more than one module, so fetch it whatever is enabled
        use = ""
    else:
        use = next((v for k, v in BY_DEST.items() if k in dest), None)
        if use is None:
            print(f"no USE flag for {name}, add one by hand", file=sys.stderr)
            continue
    # the distfile name has to be unique across the whole tree, and has to
    # survive being a shell word
    distfile = name.replace(" ", "-")
    if ".fidb" in distfile or "java-sarif" in distfile or distfile == "AXMLPrinter2.jar":
        distfile = f"ghidra-{props['RELEASE_VERSION']}-{distfile}"
    groups.setdefault(use, []).append((url, distfile))

lines = []
for use in sorted(groups, key=lambda u: (u != "", u)):
    entries = sorted(groups[use])
    indent = "\t" if use == "" else "\t\t"
    if use:
        lines.append(f"\t{use}? (")
    for url, distfile in entries:
        lines.append(f"{indent}{url}"
                     + (f"\n{indent}\t-> {distfile}" if url.rsplit("/", 1)[1] != distfile else ""))
    if use:
        lines.append("\t)")

block = 'GHIDRA_DEP_URIS="\n' + "\n".join(lines) + '\n"'

if args.ebuild:
    text = args.ebuild.read_text()
    text, n = re.subn(r'^GHIDRA_DEP_URIS="[^"]*"', lambda _: block, text, count=1, flags=re.M)
    if not n:
        sys.exit(f"{args.ebuild}: no GHIDRA_DEP_URIS block found")
    args.ebuild.write_text(text)
    print(f"wrote {sum(len(v) for v in groups.values())} files to {args.ebuild}",
          file=sys.stderr)
else:
    print(block)
