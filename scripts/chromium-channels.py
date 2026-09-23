#!/usr/bin/env python3
"""Plan the www-client/chromium slot rotation from the Linux release channels.

Each slot (stable, beta, unstable = Dev channel) holds one ebuild. A milestone
changes little once it leaves Dev, so an ebuild follows its major version from
slot to slot; only a new Dev major starts from a copy of the previous Dev ebuild.

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
TARBALL = ("https://github.com/chromium-linux-tarballs/chromium-tarballs/releases/"
           "download/{v}/chromium-{v}-linux.tar.xz")


def fetch(url, method="GET"):
    req = urllib.request.Request(url, method=method, headers={"User-Agent": "fireburn-overlay-bump"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode() if method == "GET" else r.status


def key(v):
    return tuple(int(x) for x in v.split("."))


def main():
    ebuilds = {}
    for f in PKG.glob("chromium-*.ebuild"):
        v = f.stem.removeprefix("chromium-")
        m = re.search(r'^SLOT="([^"]+)"', f.read_text(), re.M)
        if m and m.group(1) in CHANNELS:
            ebuilds[m.group(1)] = v

    targets = {}
    for slot, channel in CHANNELS.items():
        data = json.loads(fetch("https://chromiumdash.appspot.com/fetch_releases"
                                f"?channel={channel}&platform=Linux&num=1"))
        targets[slot] = data[0]["version"]

    if all(ebuilds.get(s) == v for s, v in targets.items()):
        return 0

    missing = []
    for slot, v in targets.items():
        if ebuilds.get(slot) == v:
            continue
        try:
            fetch(TARBALL.format(v=v), "HEAD")
        except Exception:
            missing.append(f"{slot} {v}")
    if missing:
        print("source tarball not published yet: " + ", ".join(missing))
        return 1

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
        ops.append(f"move     {slot:8} chromium-{src}.ebuild -> chromium-{v}.ebuild "
                   f"(SLOT {was} -> {slot})" if src != v or was != slot else "")
    for v in ebuilds.values():
        if v not in used:
            ops.append(f"remove   chromium-{v}.ebuild")
    print("\n".join(op for op in ops if op))
    return 0


if __name__ == "__main__":
    sys.exit(main())
