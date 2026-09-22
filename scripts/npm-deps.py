#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Generate NPM_PKGS for npm.eclass from JavaScript lockfiles.

Supports package-lock.json / npm-shrinkwrap.json (v2, v3), pnpm-lock.yaml
(v6 to v9), bun.lock and yarn.lock (Yarn 2+).  Several lockfiles can be given;
their packages are merged.  Platform-specific packages get "|cond" USE
conditions, and packages for other operating systems or arches are dropped.

Usage:
  npm-deps.py [--arches amd64,arm64] LOCKFILE... [--ebuild FILE]

With --ebuild, the NPM_PKGS="..." block in FILE is replaced in place;
otherwise the block is printed.  Packages that cannot come from the registry
(git, file or URL dependencies) are reported on stderr.
"""

import argparse
import json
import re
import sys
from pathlib import Path

REGISTRY_RE = re.compile(r"^https://registry\.(?:npmjs\.org|yarnpkg\.com)/(.+)/-/[^/]+\.tgz$")

CPU = {"x64": "amd64", "arm64": "arm64", "ia32": "x86", "arm": "arm", "ppc64": "ppc64",
       "riscv64": "riscv", "loong64": "loong", "s390x": "s390"}
LIBC = {"glibc": "elibc_glibc", "musl": "elibc_musl"}


def as_list(v):
    if v is None:
        return []
    return [v] if isinstance(v, str) else list(v)


def allowed(values, target):
    """npm "os"/"cpu" semantics: positive entries whitelist, "!x" excludes."""
    values = as_list(values)
    if not values:
        return True
    if f"!{target}" in values:
        return False
    positives = [v for v in values if not v.startswith("!")]
    return not positives or target in positives


def conditions(os_, cpu, libc, arches):
    """List of condition strings (one per arch) or None if unusable on Linux.

    An empty string means unconditional."""
    if not allowed(os_, "linux"):
        return None
    cpus = as_list(cpu)
    libcs = as_list(libc)
    libc_cond = ""
    if libcs:
        ok = [LIBC[l] for l in LIBC if allowed(libcs, l)]
        if not ok:
            return None
        if len(ok) == 1:
            libc_cond = ok[0]
    if not cpus:
        return [libc_cond]
    out = []
    for npm_cpu, arch in CPU.items():
        if arch in arches and allowed(cpus, npm_cpu):
            out.append(",".join(c for c in (arch, libc_cond) if c))
    # Every supported arch allowed: no arch condition needed.
    if len(out) == len(arches) and all(allowed(cpus, c) for c, a in CPU.items() if a in arches):
        return [libc_cond]
    return out or None


class Collector:
    def __init__(self, arches):
        self.arches = arches
        self.pkgs = {}  # (name, version) -> set of conds
        self.stubs = set()  # (name, version) for other platforms
        self.skipped = []

    def add(self, name, version, os_=None, cpu=None, libc=None):
        conds = conditions(os_, cpu, libc, self.arches)
        if conds is None:
            # pnpm reads the metadata of packages it will never install
            self.stubs.add((name, version))
            return
        cur = self.pkgs.setdefault((name, version), set())
        cur.update(conds)

    def skip(self, what, why):
        self.skipped.append(f"{what}: {why}")

    def render(self):
        lines = []
        for (name, version), conds in sorted(self.pkgs.items()):
            if "" in conds:
                lines.append(f"{name}@{version}")
            else:
                lines.extend(f"{name}@{version}|{c}" for c in sorted(conds))
        return lines


def name_from_url(url):
    m = REGISTRY_RE.match(url)
    return m.group(1).replace("%2f", "/").replace("%2F", "/") if m else None


def parse_npm(path, col):
    lock = json.loads(path.read_text())
    if lock.get("lockfileVersion", 1) < 2:
        sys.exit(f"{path}: lockfileVersion 1 is not supported, regenerate with npm >= 7")
    for key, meta in lock["packages"].items():
        if not key or meta.get("link") or "node_modules/" not in key:
            continue
        resolved = meta.get("resolved", "")
        if meta.get("inBundle"):
            continue
        name = name_from_url(resolved) if resolved else None
        if not name:
            if resolved:
                col.skip(key, resolved)
            continue
        col.add(name, meta["version"], meta.get("os"), meta.get("cpu"), meta.get("libc"))


def split_spec(spec):
    """'@scope/name@1.2.3(peer@1)' -> ('@scope/name', '1.2.3')."""
    spec = re.sub(r"\(.*$", "", spec)
    at = spec.rindex("@")
    return spec[:at].lstrip("/"), spec[at + 1:]


def parse_pnpm(path, col):
    import yaml
    lock = yaml.safe_load(path.read_text())
    ver = float(str(lock.get("lockfileVersion", "0")))
    for key, meta in (lock.get("packages") or {}).items():
        res = meta.get("resolution", {})
        if "integrity" not in res or "tarball" in res and not name_from_url(res["tarball"]):
            col.skip(key, json.dumps(res))
            continue
        if ver < 9:
            key = key.lstrip("/")
            key = re.sub(r"_.*$", "", key)
        name, version = split_spec(meta.get("name") and f"{meta['name']}@{meta['version']}" or key)
        if version.startswith(("link:", "file:", "workspace:")):
            continue
        col.add(name, version, meta.get("os"), meta.get("cpu"), meta.get("libc"))


def parse_bun(path, col):
    text = path.read_text()
    text = re.sub(r",(\s*[}\]])", r"\1", text)  # JSONC trailing commas
    lock = json.loads(text)
    for key, entry in lock.get("packages", {}).items():
        spec = entry[0]
        name, version = split_spec(spec)
        if version.startswith(("workspace:", "link:", "file:", "root:")):
            continue
        if len(entry) < 4 or not isinstance(entry[1], str) or entry[1] not in ("",) and not entry[1].startswith("https://registry.npmjs.org"):
            col.skip(spec, "not a registry package")
            continue
        meta = entry[2] if isinstance(entry[2], dict) else {}
        col.add(name, version, meta.get("os"), meta.get("cpu"), meta.get("libc"))


def parse_yarn(path, col):
    import yaml
    lock = yaml.safe_load(path.read_text())
    if "__metadata" not in lock:
        sys.exit(f"{path}: Yarn 1 lockfiles are not supported")
    # Yarn fetches the original of every patch: resolution (e.g. its builtin
    # compat patch for fsevents) on all platforms, so keep those unconditionally
    patched = set()
    for key, meta in lock.items():
        m = re.match(r"^(@?[^@]+)@patch:(@?[^@]+)@npm%3A([^#]+)#", meta.get("resolution", "") if isinstance(meta, dict) else "")
        if m:
            patched.add((m.group(2), m.group(3)))
    for key, meta in lock.items():
        if key == "__metadata":
            continue
        res = meta.get("resolution", "")
        m = re.match(r"^(@?[^@]+)@npm:(.+)$", res)
        if not m:
            if not re.search(r"@(workspace|patch|link|portal|file):", res):
                col.skip(res, "not a registry package")
            continue
        os_ = cpu = libc = None
        for cond in (meta.get("conditions") or "").split("&"):
            k, _, v = cond.strip().partition("=")
            if k == "os": os_ = [v]
            elif k == "cpu": cpu = [v]
            elif k == "libc": libc = [v]
        if (m.group(1), m.group(2)) in patched:
            os_ = cpu = libc = None
        col.add(m.group(1), m.group(2), os_, cpu, libc)


def parse(path, col):
    n = path.name
    if n in ("package-lock.json", "npm-shrinkwrap.json"):
        parse_npm(path, col)
    elif n == "pnpm-lock.yaml":
        parse_pnpm(path, col)
    elif n == "bun.lock":
        parse_bun(path, col)
    elif n == "yarn.lock":
        parse_yarn(path, col)
    else:
        sys.exit(f"{path}: unknown lockfile type")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("lockfiles", nargs="+", type=Path)
    ap.add_argument("--arches", default="amd64,arm64")
    ap.add_argument("--ebuild", type=Path)
    ap.add_argument("--strict", action="store_true",
                    help="fail if a dependency cannot be represented")
    args = ap.parse_args()

    col = Collector(args.arches.split(","))
    for lf in args.lockfiles:
        parse(lf, col)

    block = 'NPM_PKGS="\n' + "".join(f"\t{l}\n" for l in col.render()) + '"'
    stubs = sorted(f"{n}@{v}" for n, v in col.stubs if (n, v) not in col.pkgs)
    stub_block = 'NPM_STUB_PKGS="\n' + "".join(f"\t{l}\n" for l in stubs) + '"'
    for s in col.skipped:
        print(f"skipped {s}", file=sys.stderr)
    print(f"{len(col.pkgs)} packages, {len(col.stubs)} other-platform stubs", file=sys.stderr)
    if args.strict and col.skipped:
        sys.exit("unhandled dependencies in lockfile")

    if args.ebuild:
        text = args.ebuild.read_text()
        new, n = re.subn(r'^NPM_PKGS="[^"]*"', lambda _: block, text, count=1, flags=re.M)
        if not n:
            sys.exit(f"{args.ebuild}: no NPM_PKGS block found")
        new, n = re.subn(r'^NPM_STUB_PKGS="[^"]*"', lambda _: stub_block, new, count=1, flags=re.M)
        if not n and stubs:
            if args.strict:
                sys.exit(f"{args.ebuild}: no NPM_STUB_PKGS block; add one for pnpm")
            print(f"{args.ebuild}: no NPM_STUB_PKGS block; add one for pnpm", file=sys.stderr)
        args.ebuild.write_text(new)
    else:
        print(block)
        if stubs:
            print(stub_block)


if __name__ == "__main__":
    main()
