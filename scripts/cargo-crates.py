#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
"""Generate CRATES and GIT_CRATES for cargo.eclass from a Cargo.lock.

Usage: cargo-crates.py Cargo.lock [--ebuild FILE] [--no-git]

Registry crates go into CRATES.  Git dependencies go into GIT_CRATES: each
pinned repository is downloaded once to find the directory of every crate
it provides.  GitHub and GitLab repositories are supported.

With --ebuild, the CRATES="..." and declare -A GIT_CRATES=(...) blocks in
FILE are replaced in place.  --no-git leaves GIT_CRATES alone.  With
--licenses DISTDIR (run once the crates are fetched), the LICENSE+= block
after "# Dependent crate licenses" is filled from each crate's metadata.
"""

import argparse
import io
import re
import sys
import tarfile
import tomllib
import urllib.request
from pathlib import Path

ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
ap.add_argument("lockfile", type=Path)
ap.add_argument("--ebuild", type=Path)
ap.add_argument("--no-git", action="store_true")
ap.add_argument("--licenses", metavar="DISTDIR",
                help="also fill the '# Dependent crate licenses' LICENSE+= block from the fetched crates")
args = ap.parse_args()

lock = tomllib.loads(args.lockfile.read_text())
crates = sorted({f'{p["name"]}@{p["version"]}' for p in lock["package"]
                 if p.get("source", "").startswith("registry+")})
print(f"{len(crates)} crates", file=sys.stderr)


def archive_url(repo, commit):
    """Tarball URL and the top directory name cargo.eclass will unpack to."""
    name = repo.rstrip("/").removesuffix(".git").rsplit("/", 1)[1]
    if repo.startswith("https://github.com/"):
        return f"{repo.removesuffix('.git')}/archive/{commit}.tar.gz", name
    if repo.startswith("https://gitlab.com/"):
        return f"{repo.removesuffix('.git')}/-/archive/{commit}/{name}-{commit}.tar.gz", name
    return None, name


def git_crates():
    """{crate: "uri;commit;dir"} for every git dependency."""
    wanted = {}
    for p in lock["package"]:
        src = p.get("source", "")
        if src.startswith("git+"):
            repo, commit = re.match(r"git\+([^?#]+)(?:\?[^#]*)?#([0-9a-f]+)", src).groups()
            wanted.setdefault((repo, commit), set()).add(p["name"])
    out = {}
    for (repo, commit), names in sorted(wanted.items()):
        url, name = archive_url(repo, commit)
        if url is None:
            print(f"unsupported git host, add by hand: {repo}", file=sys.stderr)
            continue
        print(f"scanning {repo} @ {commit[:10]} for {len(names)} crate(s)", file=sys.stderr)
        data = urllib.request.urlopen(url, timeout=300).read()
        found = {}
        with tarfile.open(fileobj=io.BytesIO(data)) as tar:
            for m in tar.getmembers():
                if not m.isfile() or not m.name.endswith("/Cargo.toml"):
                    continue
                try:
                    toml = tomllib.loads(tar.extractfile(m).read().decode())
                except (tomllib.TOMLDecodeError, UnicodeDecodeError):
                    continue
                pkg = toml.get("package", {}).get("name")
                if pkg in names:
                    # the archive's top directory is <repo>-<commit>
                    rel = m.name.split("/", 1)[1].rsplit("/", 1)[0] if "/" in m.name.split("/", 1)[1] else ""
                    found[pkg] = f"{name}-%commit%" + (f"/{rel}" if rel else "")
        for n in sorted(names):
            if n not in found:
                print(f"could not find crate {n} in {repo}", file=sys.stderr)
                continue
            uri = repo.removesuffix(".git")
            out[n] = f"{uri};{commit};{found[n]}"
    return out


block = 'CRATES="\n' + "".join(f"\t{c}\n" for c in crates) + '"'
git_block = None
if not args.no_git and any(p.get("source", "").startswith("git+") for p in lock["package"]):
    gc = git_crates()
    git_block = "declare -A GIT_CRATES=(\n" + "".join(
        f"\t[{k}]='{v}'\n" for k, v in sorted(gc.items())) + ")"

# --- licenses ------------------------------------------------------------
SPDX = {
    "Apache-2.0": "Apache-2.0", "MIT": "MIT", "MIT-0": "MIT-0", "ISC": "ISC",
    "BSD-2-Clause": "BSD-2", "BSD-3-Clause": "BSD", "0BSD": "0BSD", "Zlib": "ZLIB",
    "MPL-2.0": "MPL-2.0", "Unlicense": "Unlicense", "BSL-1.0": "Boost-1.0",
    "CC0-1.0": "CC0-1.0", "Unicode-DFS-2016": "Unicode-DFS-2016",
    "Unicode-3.0": "Unicode-3.0", "OFL-1.1": "OFL-1.1", "WTFPL": "WTFPL-2",
    "NCSA": "UoI-NCSA", "bzip2-1.0.6": "BZIP2", "CDLA-Permissive-2.0": "CDLA-Permissive-2.0",
    "LGPL-2.1-or-later": "LGPL-2.1+", "LGPL-2.1": "LGPL-2.1", "LGPL-3.0": "LGPL-3",
    "GPL-2.0": "GPL-2", "GPL-2.0-only": "GPL-2", "GPL-2.0-or-later": "GPL-2+",
    "GPL-3.0": "GPL-3", "GPL-3.0-only": "GPL-3", "GPL-3.0-or-later": "GPL-3+",
    "Apache-2.0 WITH LLVM-exception": "Apache-2.0-with-LLVM-exceptions",
}


def spdx_to_gentoo(expr, where):
    """SPDX expression -> Gentoo LICENSE fragment (a string), None if unmappable."""
    expr = expr.replace("/", " OR ")
    expr = re.sub(r"(\S+) WITH (\S+)", lambda m: m.group(0).replace(" ", "\x00"), expr)
    toks = re.findall(r"\(|\)|[^\s()]+", expr)
    pos = 0

    def atom(t):
        t = t.replace("\x00", " ")
        g = SPDX.get(t)
        if g is None and t.startswith("LicenseRef-"):
            return None
        if g is None:
            print(f"unknown license {t!r} in {where}", file=sys.stderr)
        return g

    def parse_or():
        nonlocal pos
        parts = [parse_and()]
        while pos < len(toks) and toks[pos] == "OR":
            pos += 1
            parts.append(parse_and())
        parts = [p for p in parts if p]
        if not parts:
            return None
        return parts[0] if len(parts) == 1 else "|| ( " + " ".join(sorted(set(parts))) + " )"

    def parse_and():
        nonlocal pos
        parts = [parse_atom()]
        while pos < len(toks) and toks[pos] == "AND":
            pos += 1
            parts.append(parse_atom())
        if any(p is None for p in parts):
            return None
        return " ".join(parts)

    def parse_atom():
        nonlocal pos
        t = toks[pos]
        pos += 1
        if t == "(":
            r = parse_or()
            pos += 1
            return r if r is None or " " not in r or r.startswith("||") else f"( {r} )"
        return atom(t)

    return parse_or()


def crate_licenses(distdir):
    import tarfile as tf
    exprs = set()
    for c in crates:
        name, ver = c.rsplit("@", 1)
        path = Path(distdir) / f"{name}-{ver}.crate"
        if not path.exists():
            print(f"missing {path.name} (fetch the Manifest first)", file=sys.stderr)
            continue
        with tf.open(path) as t:
            toml = tomllib.loads(t.extractfile(f"{name}-{ver}/Cargo.toml").read().decode())
        lic = toml.get("package", {}).get("license")
        if not lic:
            print(f"{c}: no license field (license-file only), check by hand", file=sys.stderr)
            continue
        g = spdx_to_gentoo(lic, c)
        if g:
            exprs.add(g)
    # plain licenses first, then the alternatives that are not already covered
    # (an AND of plain licenses needs every one of them, so split those up)
    plain_set = {t for e in exprs if not e.startswith("||") and "(" not in e for t in e.split()}
    plain = sorted(plain_set)
    groups = sorted(e for e in exprs if (e.startswith("||") or "(" in e)
                    and not (e.startswith("|| (") and set(e[5:-2].split()) & plain_set))
    return plain, groups


if args.licenses:
    plain, groups = crate_licenses(args.licenses)
    lines, cur = [], "\t"
    for p in plain:
        if len(cur) + len(p) > 72:
            lines.append(cur.rstrip())
            cur = "\t"
        cur += p + " "
    lines.append(cur.rstrip())
    lines += [f"\t{g}" for g in groups]
    lic_block = 'LICENSE+="\n' + "\n".join(lines) + '\n"'

if args.ebuild:
    text = args.ebuild.read_text()
    if args.licenses:
        text, n = re.subn(r'^(# Dependent crate licenses\n)LICENSE\+="[^"]*"',
                          lambda m: m.group(1) + lic_block, text, count=1, flags=re.M)
        if not n:
            print(f"{args.ebuild}: no '# Dependent crate licenses' LICENSE+= block", file=sys.stderr)
    text, n = re.subn(r'^CRATES="[^"]*"', lambda _: block, text, count=1, flags=re.M)
    if not n:
        sys.exit(f"{args.ebuild}: no CRATES block found")
    if git_block:
        text, n = re.subn(r"^declare -A GIT_CRATES=\(\n.*?^\)", lambda _: git_block,
                          text, count=1, flags=re.M | re.S)
        if not n:
            text = text.replace(block, block + "\n\n" + git_block, 1)
    args.ebuild.write_text(text)
else:
    print(block)
    if git_block:
        print("\n" + git_block)
