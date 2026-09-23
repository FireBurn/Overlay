#!/usr/bin/env python3
"""Report the latest upstream version of overlay packages.

Sources come from scripts/upstream-sources. Packages without an entry are
inferred from metadata.xml remote-ids and SRC_URI where possible.

Output is one tab-separated line per package:
  package status local upstream group batch source note
status: newer, current, older, agent, skip, live, error
"""

import argparse
import json
import re
import subprocess
import sys
import threading
import urllib.request
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path

from portage.versions import catpkgsplit, vercmp, ververify

REPO = Path(__file__).resolve().parent.parent
SOURCES = REPO / "scripts" / "upstream-sources"
TIMEOUT = 60


class LookupError_(Exception):
    pass


_cache, _cache_lock = {}, threading.Lock()


def cached(fn):
    """Share one fetch between threads asking for the same URL."""
    def wrapper(*key):
        with _cache_lock:
            fut = _cache.get((fn, key))
            owner = fut is None
            if owner:
                fut = _cache[(fn, key)] = Future()
        if owner:
            try:
                fut.set_result(fn(*key))
            except Exception as e:
                fut.set_exception(e)
        return fut.result()
    return wrapper


@cached
def http(url):
    req = urllib.request.Request(url, headers={"User-Agent": "fireburn-overlay-bump"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return r.read().decode()
    except Exception as e:
        raise LookupError_(f"{url}: {e}") from None


def run(cmd):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        raise LookupError_(f"{cmd[0]} timed out") from None
    if p.returncode:
        raise LookupError_(f"{' '.join(cmd)}: {p.stderr.strip()[:200]}")
    return p.stdout


@cached
def gh_json(path):
    return json.loads(run(["gh", "api", path]))


@cached
def git_tags(url):
    out = run(["git", "ls-remote", "--tags", "--refs", url])
    return [line.split("refs/tags/", 1)[1] for line in out.splitlines() if "refs/tags/" in line]


def parse_line(line):
    words = line.split()
    key, rest = words[0], words[1:]
    args, opts = [], {}
    for w in rest:
        m = re.fullmatch(r"(prefix|suffix|sep|pad|match|pre|batch)=(.*)", w)
        if m:
            opts[m.group(1)] = m.group(2)
        else:
            args.append(w)
    return key, args, opts


def load_sources():
    groups, pkgs = {}, {}
    for raw in SOURCES.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        key, args, opts = parse_line(line)
        if key.startswith("@"):
            groups[key] = (args, opts)
        else:
            pkgs[key] = (args, opts)
    resolved = {}
    for pkg, (args, opts) in pkgs.items():
        group = ""
        if args and args[0].startswith("@"):
            group = args[0]
            if group not in groups:
                raise SystemExit(f"{SOURCES}: {pkg} uses unknown group {group}")
            gargs, gopts = groups[group]
            args, opts = gargs, {**gopts, **opts}
        resolved[pkg] = (group, args, opts)
    return resolved


def tag_to_pv(tag, opts):
    pv = tag
    prefix, suffix = opts.get("prefix", ""), opts.get("suffix", "")
    if prefix:
        if not pv.startswith(prefix):
            return None
        pv = pv[len(prefix):]
    if suffix:
        if not pv.endswith(suffix):
            return None
        pv = pv[: -len(suffix)]
    if "sep" in opts:
        pv = pv.replace(opts["sep"], ".")
    if "pad" in opts and re.fullmatch(r"\d+(\.\d+)*", pv):
        parts = pv.split(".")
        pv = ".".join(parts + ["0"] * (int(opts["pad"]) - len(parts)))
    if "match" in opts and not re.search(opts["match"], pv):
        return None
    return pv if ververify(pv) else None


def best(candidates, opts):
    pvs = [pv for pv in (tag_to_pv(t, opts) for t in candidates) if pv]
    if not pvs:
        raise LookupError_("no version-like tags")
    top = pvs[0]
    for pv in pvs[1:]:
        if vercmp(pv, top) > 0:
            top = pv
    return top


def lookup(method, args, opts, local):
    if method == "github-release":
        rels = gh_json(f"repos/{args[0]}/releases?per_page=100")
        pre = opts.get("pre") == "1"
        return best([r["tag_name"] for r in rels
                     if not r["draft"] and (pre or not r["prerelease"])], opts)
    if method == "github-tag":
        return best(git_tags(f"https://github.com/{args[0]}.git"), opts)
    if method == "git-tag":
        return best(git_tags(args[0]), opts)
    if method == "gitlab-tag":
        host = opts.get("host", "gitlab.com")
        proj = args[0].replace("/", "%2F")
        tags = json.loads(http(f"https://{host}/api/v4/projects/{proj}/repository/tags?per_page=100"))
        return best([t["name"] for t in tags], opts)
    if method == "github-commit":
        c = gh_json(f"repos/{args[0]}/commits?per_page=1")[0]
        date = c["commit"]["committer"]["date"][:10].replace("-", "")
        if re.fullmatch(r"\d{8}", local):
            return date
        base = re.sub(r"_p\d+$", "", local)
        return f"{base}_p{date}"
    if method == "pypi":
        return json.loads(http(f"https://pypi.org/pypi/{args[0]}/json"))["info"]["version"]
    if method == "npm":
        return json.loads(http(f"https://registry.npmjs.org/{args[0]}/latest"))["version"]
    if method == "text":
        return best([http(args[0]).strip()], opts)
    if method == "json":
        data = json.loads(http(args[0]))
        for k in args[1].split("."):
            data = data[k]
        return best([str(data)], opts)
    if method == "page":
        # URL REGEX pairs; each URL may use {} for the previous step's match.
        found = ""
        for url, rx in zip(args[::2], args[1::2]):
            found = best(re.findall(rx, http(url.format(found)), re.M), opts)
        return found
    raise LookupError_(f"unknown method {method}")


def ebuild_versions(pkg):
    cat, pn = pkg.split("/")
    out = []
    for f in (REPO / pkg).glob(f"{pn}-*.ebuild"):
        split = catpkgsplit(f"{cat}/{f.stem}")
        if split:
            out.append(split[2])
    return out


def is_live(pv):
    return "9999" in pv.split(".")


def local_version(pkg):
    pvs = [pv for pv in ebuild_versions(pkg) if not is_live(pv)]
    if not pvs:
        return None
    top = pvs[0]
    for pv in pvs[1:]:
        if vercmp(pv, top) > 0:
            top = pv
    return top


def infer(pkg):
    """Guess a source from metadata.xml and SRC_URI. Returns a sources line or None."""
    meta = REPO / pkg / "metadata.xml"
    text = meta.read_text() if meta.exists() else ""
    ids = dict(re.findall(r'<remote-id type="([^"]+)">([^<]+)<', text))
    if "pypi" in ids:
        return f"pypi {ids['pypi']}"
    if "github" in ids:
        repo = ids["github"]
        prefix = ""
        for f in sorted((REPO / pkg).glob("*.ebuild")):
            m = re.search(r"(?:refs/tags/|archive/|download/)([^/\"$ ]*)\$\{PV\}", f.read_text())
            if m:
                prefix = m.group(1)
                break
        return f"github-release {repo}" + (f" prefix={prefix}" if prefix else "")
    return None


def all_packages():
    return sorted({str(p.parent.relative_to(REPO)) for p in REPO.glob("*/*/*.ebuild")})


def check(pkg, sources):
    local = local_version(pkg)
    if local is None:
        return [pkg, "live", "", "", "", "", "", "only live ebuilds"]
    if pkg in sources:
        group, args, opts = sources[pkg]
        inferred = ""
    else:
        line = infer(pkg)
        if not line:
            return [pkg, "agent", local, "", "", "", "",
                    "no upstream-sources entry and nothing to infer"]
        _, args, opts = parse_line(f"{pkg} {line}")
        group, inferred = "", line
    method = args[0]
    source = " ".join(args)
    if method in ("agent", "skip"):
        return [pkg, method, local, "", group, "", source, " ".join(args[1:])]
    local_base = re.sub(r"-r\d+$", "", local)
    try:
        up = lookup(method, args[1:], opts, local_base)
    except Exception as e:
        note = f"lookup failed: {e}"
        if inferred:
            note += f"; inferred '{inferred}'"
        return [pkg, "agent" if inferred else "error", local, "", group,
                opts.get("batch", ""), source, note]
    c = vercmp(up, local_base)
    status = "newer" if c > 0 else "current" if c == 0 else "older"
    note = f"inferred; record as: {pkg} {inferred}" if inferred else ""
    return [pkg, status, local, up, group, opts.get("batch", ""), source, note]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("packages", nargs="*")
    ap.add_argument("-j", "--jobs", type=int, default=12)
    a = ap.parse_args()
    sources = load_sources()
    pkgs = a.packages or all_packages()
    with ThreadPoolExecutor(a.jobs) as ex:
        for row in ex.map(lambda p: check(p, sources), pkgs):
            print("\t".join(x.replace("\t", " ") for x in row), flush=True)


if __name__ == "__main__":
    sys.exit(main())
