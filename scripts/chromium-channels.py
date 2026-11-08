#!/usr/bin/env python3
"""Plan the www-client/chromium slot rotation from the Linux release channels.

Each slot (stable, beta, unstable = Dev channel) holds one ebuild. A milestone
changes little once it leaves Dev, so an ebuild follows its major version from
slot to slot; only a new Dev major starts from a copy of the previous Dev ebuild.

The channels only say which major each slot follows. The version is the newest
release of that major that chromium-tarballs has published a source tarball
for; a major with no tarball yet leaves its slot as it is.

Prints the file operations in the order they must be applied, or nothing when
every slot is current. Exits 1 if the plan cannot be made.
"""

import json
import re
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PKG = REPO / "www-client" / "chromium"
CHANNELS = {"stable": "Stable", "beta": "Beta", "unstable": "Dev"}
RELEASES = "https://api.github.com/repos/chromium-linux-tarballs/chromium-tarballs/releases?per_page=100"


def fetch(url, method="GET"):
    req = urllib.request.Request(url, method=method, headers={"User-Agent": "fireburn-overlay-bump"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode() if method == "GET" else r.status


def key(v):
    return tuple(int(x) for x in v.split("."))


def published():
    """Versions that have a source tarball, not just a release entry."""
    out = set()
    for rel in json.loads(fetch(RELEASES)):
        if any(a["name"].endswith("-linux.tar.xz") for a in rel["assets"]):
            out.add(rel["tag_name"])
    return out


def main():
    ebuilds = {}
    for f in PKG.glob("chromium-*.ebuild"):
        v = f.stem.removeprefix("chromium-")
        m = re.search(r'^SLOT="([^"]+)"', f.read_text(), re.M)
        if m and m.group(1) in CHANNELS:
            ebuilds[m.group(1)] = v

    have = published()
    targets = {}
    for slot, channel in CHANNELS.items():
        data = json.loads(fetch("https://chromiumdash.appspot.com/fetch_releases"
                                f"?channel={channel}&platform=Linux&num=1"))
        major = data[0]["version"].split(".")[0]
        built = [v for v in have if v.split(".")[0] == major]
        if built:
            targets[slot] = max(built, key=key)
        else:
            targets[slot] = ebuilds[slot]
            print(f"hold     {slot:8} no source tarball for major {major} yet", file=sys.stderr)

    if all(ebuilds.get(s) == v for s, v in targets.items()):
        return 0

    by_major = {v.split(".")[0]: v for v in ebuilds.values()}
    newest = max(ebuilds.values(), key=key)
    ops, used = [], set()
    # Copies first, while their source files still have their old names.
    for slot, v in targets.items():
        major = v.split(".")[0]
        if ebuilds.get(slot) == v:
            used.add(v)
            ops.append(f"keep     {slot:8} chromium-{v}.ebuild (current)")
        elif major not in by_major:
            ops.insert(0, f"copy     {slot:8} chromium-{newest}.ebuild -> chromium-{v}.ebuild "
                          f"(new {slot} major {major}; start from the previous unstable ebuild, "
                          "expect patch and dependency changes)")
    for slot, v in targets.items():
        major = v.split(".")[0]
        src = by_major.get(major)
        if ebuilds.get(slot) == v or src is None:
            continue
        used.add(src)
        was = next(s for s, ev in ebuilds.items() if ev == src)
        if src == v and was == slot:
            continue
        if any(ebuilds.get(s) == src == t for s, t in targets.items()):
            # Another slot keeps this ebuild as it is, so the new slot gets a copy.
            ops.insert(0, f"copy     {slot:8} chromium-{src}.ebuild -> chromium-{v}.ebuild "
                          f"(same major as the {was} slot, which keeps its ebuild)")
        else:
            ops.append(f"move     {slot:8} chromium-{src}.ebuild -> chromium-{v}.ebuild "
                       f"(SLOT {was} -> {slot})")
    for v in ebuilds.values():
        if v not in used:
            ops.append(f"remove   chromium-{v}.ebuild")
    print("\n".join(op for op in ops if op))
    return 0


if __name__ == "__main__":
    sys.exit(main())
