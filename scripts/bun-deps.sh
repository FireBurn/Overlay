#!/usr/bin/env bash
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
#
# Print the dependency blocks for a dev-lang/bun ebuild from a Bun source tree:
# BUN_VENDOR (GitHub archives of vendored libraries), BUN_WEBKIT_COMMIT,
# BUN_NODEJS_HEADERS, CRATES (from Cargo.lock) and NPM_PKGS (from the bun.lock
# files the build installs).
#
# Usage: bun-deps.sh <bun-source-dir> [ebuild]
# With an ebuild, the blocks are replaced in place.

set -euo pipefail

src=$(realpath "${1:?usage: bun-deps.sh <bun-source-dir> [ebuild]}")
ebuild=${2:-}
here=$(dirname "$(realpath "$0")")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp" "$src/.gentoo-deps.mts"' EXIT

# Evaluate Bun's own dependency table for a Linux release build with local
# WebKit. The script has to live in the source tree for its imports.
cat > "$src/.gentoo-deps.mts" <<'EOF'
import { resolveConfig } from "./scripts/build/config.ts";
import { allDeps } from "./scripts/build/deps/index.ts";

const tc = { cc: "clang", cxx: "clang++", ar: "llvm-ar", ld: "ld.lld", strip: "llvm-strip",
	cmake: "cmake", bun: "bun", jsRuntime: "node", esbuild: "esbuild", cargo: "cargo",
	hostCc: "clang", hostCxx: "clang++" } as any;
const vendor: string[] = [];
let webkit = "", headers = "";
for (const arch of ["x64", "aarch64"]) {
	const cfg = resolveConfig({ buildType: "Release", webkit: "local", os: "linux", arch, abi: "gnu", linuxSysroot: "/" } as any, tc);
	webkit = cfg.webkitVersion;
	for (const d of allDeps) {
		if (d.enabled && !d.enabled(cfg)) continue;
		const s: any = typeof d.source === "function" ? d.source(cfg) : d.source;
		if (s.kind === "github-archive") {
			const line = `${d.name} ${s.repo} ${s.commit}`;
			if (!vendor.includes(line)) vendor.push(line);
		} else if (s.kind === "prebuilt" && d.name === "nodejs") {
			headers = s.url;
		}
	}
}
console.log(JSON.stringify({ vendor, webkit, headers }));
EOF
( cd "$src" && node --experimental-strip-types --disable-warning=MODULE_TYPELESS_PACKAGE_JSON .gentoo-deps.mts ) > "$tmp/deps.json"

python3 - "$src" "$tmp/deps.json" ${ebuild:+"$ebuild"} > "$tmp/blocks" <<'EOF'
import json, re, sys, tomllib
src, deps = sys.argv[1], json.load(open(sys.argv[2]))
print('BUN_VENDOR=(')
for line in deps["vendor"]:
    print(f'\t"{line}"')
print(')')
print(f'BUN_WEBKIT_COMMIT="{deps["webkit"]}"')
print(f'BUN_NODEJS_HEADERS="{deps["headers"]}"')
lock = tomllib.load(open(f"{src}/Cargo.lock", "rb"))
pkgs = list(lock["package"])
# Release builds rebuild std (-Zbuild-std), which needs std's own locked crates
rust = re.search(r'^RUST_MIN_VER="?([0-9.]+)',open(sys.argv[3]).read(), re.M) if len(sys.argv) > 3 else None
if rust:
    stdlock = f"/usr/lib/rust/{rust.group(1)}/lib/rustlib/src/rust/library/Cargo.lock"
    pkgs += tomllib.load(open(stdlock, "rb"))["package"]
else:
    print("warning: no ebuild given, std crates for -Zbuild-std not added", file=sys.stderr)
crates = sorted({f'{p["name"]}@{p["version"]}' for p in pkgs
                 if p.get("source", "").startswith("registry+")})
gits = [p for p in lock["package"] if p.get("source", "").startswith("git+")]
if gits:
    print("warning: git crates need GIT_CRATES: " + ", ".join(p["name"] for p in gits), file=sys.stderr)
print('CRATES="')
for c in crates:
    print(f'\t{c}')
print('"')
EOF

"$here/npm-deps.py" "$src/bun.lock" "$src/packages/bun-error/bun.lock" \
	"$src/src/node-fallbacks/bun.lock" >> "$tmp/blocks"

if [[ -z $ebuild ]]; then
	cat "$tmp/blocks"
	exit
fi

python3 - "$ebuild" "$tmp/blocks" <<'EOF'
import re, sys
path, blocks = sys.argv[1], open(sys.argv[2]).read()
text = open(path).read()
patterns = {
    "BUN_VENDOR": r'^BUN_VENDOR=\([^)]*\)',
    "BUN_WEBKIT_COMMIT": r'^BUN_WEBKIT_COMMIT="[^"]*"',
    "BUN_NODEJS_HEADERS": r'^BUN_NODEJS_HEADERS="[^"]*"',
    "CRATES": r'^CRATES="[^"]*"',
    "NPM_PKGS": r'^NPM_PKGS="[^"]*"',
}
for name, pat in patterns.items():
    new = re.search(pat, blocks, re.M).group(0)
    text, n = re.subn(pat, lambda _: new, text, count=1, flags=re.M)
    if not n:
        sys.exit(f"{path}: no {name} block")
open(path, "w").write(text)
EOF
