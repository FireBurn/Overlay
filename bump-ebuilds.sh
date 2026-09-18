#!/bin/bash
# bump-ebuilds.sh — check tracked ebuilds for newer upstream versions and bump them.
#
# The deterministic work (version checks, simple bumps, Manifest, validation,
# commit) runs here in bash. The LLM agent (ebuild-bumper) is invoked only for
# the complex Rust packages (codex, zed), and only when a newer stable version
# exists AND its crate tarball is already published upstream.
#
# A "simple" bump is just a rename + Manifest refresh, because those ebuilds
# derive PV from the filename and reference it via ${PV}. No LLM is involved.

set -uo pipefail
cd "$(dirname "$0")"

BRANCH="master"

# --- tracked packages -----------------------------------------------------
# "category/package" paths. To track a new package, add it here; if it is a
# complex Rust crate that needs dependency tracking, also add it to COMPLEX_PKGS.
ALL_PKGS=(
    dev-util/claude-code
    dev-util/antigravity-cli
    dev-util/opencode
    dev-util/qwen-code
    dev-util/pi
    dev-util/codex
    app-editors/zed
    games-util/heroic
)
COMPLEX_PKGS=( dev-util/codex app-editors/zed )

# --- CLI ------------------------------------------------------------------
DRY_RUN=0
PUSH=1
PKG=""
usage() {
    cat <<'EOF'
Usage: bump-ebuilds.sh [options] [package]

Check tracked ebuilds for newer upstream versions and bump them.

Options:
  -n, --dry-run    Report what would change without touching anything
      --no-push    Commit bumps but do not push to origin
  -h, --help       Show this help

With no package argument, all tracked packages are checked.
EOF
}
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        --no-push)    PUSH=0 ;;
        -h|--help)    usage; exit 0 ;;
        -*)           echo "unknown option: $arg" >&2; usage >&2; exit 2 ;;
        *)            PKG="$arg" ;;
    esac
done

if [[ -n "$PKG" ]]; then
    if [[ "$PKG" != */* ]]; then            # accept a bare "claude-code"
        hit=""
        for p in "${ALL_PKGS[@]}"; do [[ "${p##*/}" == "$PKG" ]] && hit="$p"; done
        [[ -n "$hit" ]] || { echo "unknown package: $PKG" >&2; exit 2; }
        PKG="$hit"
    fi
    WORK=("$PKG")
else
    WORK=("${ALL_PKGS[@]}")
fi

log()  { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
info() { printf '   %s\n' "$1"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

pn_of()      { echo "${1##*/}"; }
is_complex() { local p; for p in "${COMPLEX_PKGS[@]}"; do [[ "$p" == "$1" ]] && return 0; done; return 1; }

# --- version helpers ------------------------------------------------------
# vercmp A B -> prints gt / eq / lt (sufficient for stable versions).
vercmp() {
    local a="$1" b="$2"
    [[ "$a" == "$b" ]] && { echo eq; return; }
    local -a A B
    IFS='.' read -ra A <<<"$a"; IFS='.' read -ra B <<<"$b"
    local n=${#A[@]}; (( ${#B[@]} > n )) && n=${#B[@]}
    local i x y xi yi xs ys
    for ((i = 0; i < n; i++)); do
        x="${A[i]:-0}"; y="${B[i]:-0}"
        xi="${x%%[!0-9]*}"; yi="${y%%[!0-9]*}"
        [[ -z "$xi" ]] && xi=0; [[ -z "$yi" ]] && yi=0
        (( 10#$xi > 10#$yi )) && { echo gt; return; }
        (( 10#$xi < 10#$yi )) && { echo lt; return; }
        xs="${x#"$xi"}"; ys="${y#"$yi"}"
        [[ -n "$xs" && -z "$ys" ]] && { echo lt; return; }
        [[ -z "$xs" && -n "$ys" ]] && { echo gt; return; }
    done
    echo eq
}

# Latest stable upstream PV ("" if it cannot be determined).
latest_pv() {
    local pkg="$1"
    if [[ "$pkg" == dev-util/claude-code ]]; then
        # The "latest" endpoint returns the version string directly.
        curl -fsSL "https://downloads.claude.ai/claude-code-releases/latest" 2>/dev/null | tr -d '[:space:]'
        return
    fi
    local repo prefix t pv best=""
    case "$pkg" in
        dev-util/antigravity-cli) repo=google-antigravity/antigravity-cli; prefix="" ;;
        dev-util/codex)           repo=openai/codex;               prefix="rust-v" ;;
        dev-util/opencode)        repo=anomalyco/opencode;         prefix="v" ;;
        dev-util/qwen-code)       repo=QwenLM/qwen-code;           prefix="v" ;;
        dev-util/pi)              repo=earendil-works/pi;          prefix="v" ;;
        app-editors/zed)          repo=zed-industries/zed;         prefix="v" ;;
        games-util/heroic)        repo=Heroic-Games-Launcher/HeroicGamesLauncher; prefix="v" ;;
        *) return 0 ;;
    esac
    # Keep only stable releases whose tag carries this package's prefix, then
    # take the highest PV. The prefix is what separates e.g. codex's rust-v*
    # tags from its python-v* tags, or qwen-code's v* from sdk-typescript-v*.
    while IFS= read -r t; do
        [[ -n "$t" ]] || continue
        if [[ -n "$prefix" ]]; then
            [[ "$t" == "$prefix"* ]] || continue
            pv="${t#"$prefix"}"
        else
            [[ "$t" =~ ^[0-9] ]] || continue
            pv="$t"
        fi
        [[ -n "$pv" ]] || continue
        if [[ -z "$best" ]] || [[ "$(vercmp "$pv" "$best")" == gt ]]; then best="$pv"; fi
    done < <(gh release list --repo "$repo" --limit 30 \
                --json tagName,isPrerelease \
                --jq '.[] | select(.isPrerelease|not) | .tagName' 2>/dev/null)
    printf '%s' "$best"
}

# Current non-9999 ebuild file (highest version if there are several).
current_ebuild() {
    local pkg="$1" pn
    pn="$(pn_of "$pkg")"
    ls "$pkg/$pn"-*.ebuild 2>/dev/null | grep -v -- '-9999' | sort -V | tail -n1
}

# Current PV (without revision) from the non-9999 ebuild filename.
current_pv() {
    local pkg="$1" pn f
    pn="$(pn_of "$pkg")"
    f="$(current_ebuild "$pkg")"
    [[ -n "$f" ]] || return 1
    basename "$f" .ebuild | sed -E "s/^$pn-//; s/-r[0-9]+$//"
}

# Upstream lockfiles (repo-relative) for packages built with npm.eclass.
# Their NPM_PKGS block is regenerated from these on every bump.
npm_lockfiles() {
    case "$1" in
        dev-util/pi)         echo "earendil-works/pi v package-lock.json" ;;
        dev-util/qwen-code)  echo "QwenLM/qwen-code v pnpm-lock.yaml" ;;
        dev-util/opencode)   echo "anomalyco/opencode v bun.lock" ;;
        games-util/heroic)   echo "Heroic-Games-Launcher/HeroicGamesLauncher v pnpm-lock.yaml" ;;
    esac
}

# Upstream Cargo.lock (repo-relative) for packages built with cargo.eclass.
# Their CRATES block is regenerated from it on every bump.
cargo_lockfiles() {
    case "$1" in
        dev-util/codex)  echo "openai/codex rust-v codex-rs/Cargo.lock" ;;
        app-editors/zed) echo "zed-industries/zed v Cargo.lock" ;;
    esac
}

# Regenerate CRATES for a new PV. Git dependencies are reported but not
# updated: GIT_CRATES still needs a human (or the agent) to check them.
update_crates() {
    local pkg="$1" pv="$2" ebuild="$3" spec repo prefix f tmp
    spec="$(cargo_lockfiles "$pkg")"
    [[ -n "$spec" ]] || return 0
    set -- $spec; repo="$1"; prefix="$2"; f="$3"
    tmp="$(mktemp -d)"
    if ! curl -fsSL "https://raw.githubusercontent.com/$repo/$prefix$pv/$f" -o "$tmp/Cargo.lock"; then
        rm -rf "$tmp"
        echo "ERROR: cannot fetch $f for $pkg $pv" >&2
        return 1
    fi
    ./scripts/cargo-crates.py "$tmp/Cargo.lock" --ebuild "$ebuild" || { rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"
}

# Regenerate NPM_PKGS (and ESBUILD_SLOT, if the ebuild pins one) for a new PV.
update_npm_pkgs() {
    local pkg="$1" pv="$2" ebuild="$3" spec repo prefix tmp f lock=() esb
    spec="$(npm_lockfiles "$pkg")"
    [[ -n "$spec" ]] || return 0
    read -r repo prefix f <<<"$spec"
    tmp="$(mktemp -d)"
    for f in ${spec#* * }; do
        mkdir -p "$tmp/$(dirname "$f")"
        curl -fsSL "https://raw.githubusercontent.com/$repo/$prefix$pv/$f" -o "$tmp/$f" ||
            { rm -rf "$tmp"; echo "ERROR: cannot fetch $f for $pkg $pv" >&2; return 1; }
        lock+=("$tmp/$f")
    done
    ./scripts/npm-deps.py "${lock[@]}" --ebuild "$ebuild" || { rm -rf "$tmp"; return 1; }

    if grep -q '^ESBUILD_SLOT=' "$ebuild" && [[ "${lock[0]}" == *package-lock.json ]]; then
        esb="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["packages"]["node_modules/esbuild"]["version"])' "${lock[0]}")"
        sed -i "s/^ESBUILD_SLOT=.*/ESBUILD_SLOT=\"$esb\"/" "$ebuild"
        if ! ls dev-util/esbuild/esbuild-"$esb".ebuild >/dev/null 2>&1; then
            info "warning: $pkg $pv needs dev-util/esbuild:$esb, which has no ebuild yet"
        fi
    fi
    rm -rf "$tmp"
}

# The one upstream artifact that gates a bump (HEAD-checked before we start).
readiness_url() {
    local pkg="$1" pv="$2"
    case "$pkg" in
        dev-util/claude-code)
            echo "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/$pv/linux-x64/claude" ;;
        dev-util/antigravity-cli)
            echo "https://github.com/google-antigravity/antigravity-cli/releases/download/$pv/agy_cli_linux_x64.tar.gz" ;;
        dev-util/opencode)
            echo "https://github.com/anomalyco/opencode/archive/refs/tags/v$pv.tar.gz" ;;
        dev-util/qwen-code)
            echo "https://github.com/QwenLM/qwen-code/archive/refs/tags/v$pv.tar.gz" ;;
        dev-util/pi)
            echo "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-$pv.tgz" ;;
        dev-util/codex)
            echo "https://github.com/openai/codex/archive/rust-v$pv.tar.gz" ;;
        app-editors/zed)
            echo "https://github.com/zed-industries/zed/archive/refs/tags/v$pv.tar.gz" ;;
        games-util/heroic)
            echo "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/archive/refs/tags/v$pv.tar.gz" ;;
    esac
}

# HTTP status for a URL via HEAD (follows redirects); "000" on network failure.
http_code() {
    local code
    code="$(curl -sIL -o /dev/null -w '%{http_code}' --max-time 30 "$1" 2>/dev/null)" || code=000
    printf '%s' "${code:-000}"
}

# --- bump implementations -------------------------------------------------
# Undo a partially-applied simple bump (rename + Manifest).
revert_bump() {
    local pkg="$1" oldf="$2" newf="$3"
    git checkout -q -- "$newf" 2>/dev/null
    git mv "$newf" "$oldf" 2>/dev/null
    git checkout -q -- "$pkg/Manifest" 2>/dev/null
    git reset -q -- "$pkg" 2>/dev/null
}

# Simple bump: rename + Manifest refresh. Returns 0 on success, 1 otherwise.
bump_simple() {
    local pkg="$1" old="$2" new="$3"
    local pn oldf newf
    pn="$(pn_of "$pkg")"; oldf="$(current_ebuild "$pkg")"; newf="$pkg/$pn-$new.ebuild"

    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would bump $pkg $old -> $new"
        return 0
    fi

    # These ebuilds derive PV from the filename; a literal old version is a red flag.
    if grep -qF "$old" "$oldf"; then
        info "warning: $oldf contains a literal '$old' — verify it is not hardcoded"
    fi

    git mv "$oldf" "$newf" || { echo "ERROR: git mv failed for $pkg" >&2; return 1; }
    if ! update_npm_pkgs "$pkg" "$new" "$newf"; then
        revert_bump "$pkg" "$oldf" "$newf"
        echo "ERROR: NPM_PKGS update failed for $pkg (reverted)" >&2
        return 1
    fi
    if ! update_crates "$pkg" "$new" "$newf"; then
        revert_bump "$pkg" "$oldf" "$newf"
        echo "ERROR: CRATES update failed for $pkg (reverted)" >&2
        return 1
    fi
    if ! ebuild "$newf" digest; then
        revert_bump "$pkg" "$oldf" "$newf"
        echo "ERROR: ebuild digest failed for $pkg (reverted)" >&2
        return 1
    fi
    if ! ebuild "$newf" manifest; then
        revert_bump "$pkg" "$oldf" "$newf"
        echo "ERROR: ebuild manifest failed for $pkg (reverted)" >&2
        return 1
    fi
    git add "$pkg"
    git commit -q -m "$pkg: Bump to $new" || { echo "ERROR: commit failed for $pkg" >&2; return 1; }
    info "bumped $pkg $old -> $new"
    return 0
}

# Complex bump: delegate to the LLM agent. Returns 0 on success, 1 otherwise.
bump_complex() {
    local pkg="$1" old="$2" new="$3"
    local pn url code
    pn="$(pn_of "$pkg")"
    url="$(readiness_url "$pkg" "$new")"
    code="$(http_code "$url")"
    if [[ "$code" != 2* ]]; then
        info "skip $pkg: upstream source for $new not available yet (HTTP $code)"
        return 1
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would ask agent to bump $pkg $old -> $new (source available)"
        return 0
    fi

    log "agent: $pkg $old -> $new"
    local prompt
    prompt="Bump $pkg from $old to $new. The upstream source for $new already exists at:
$url
Do the full bump: rename the ebuild to $pn-$new.ebuild, regenerate CRATES with
scripts/cargo-crates.py from the new version's Cargo.lock, then verify the GIT_CRATES commits (and RUSTY_V8_TAG / WEBRTC_COMMIT where applicable) against the new version's source, updating them only if they changed. Regenerate the Manifest (ebuild digest + ebuild manifest), validate, and commit with the message '$pkg: Bump to $new'. Do NOT push — the calling script handles pushing."

    if ! opencode run --agent ebuild-bumper "$prompt"; then
        echo "ERROR: agent bump failed for $pkg" >&2
        return 1
    fi
    info "agent bumped $pkg $old -> $new"
    return 0
}

# --- main -----------------------------------------------------------------
changed=0
for pkg in "${WORK[@]}"; do
    log "check: $pkg"
    old="$(current_pv "$pkg")" || { info "no ebuild found; skipping"; continue; }
    new="$(latest_pv "$pkg")"
    if [[ -z "$new" ]]; then
        info "could not determine upstream version; skipping"
        continue
    fi
    case "$(vercmp "$new" "$old")" in
        eq) info "up to date ($old)"; continue ;;
        lt) info "upstream $new is older than local $old; skipping"; continue ;;
    esac

    if is_complex "$pkg"; then
        bump_complex "$pkg" "$old" "$new" && changed=1
    else
        if [[ "$(http_code "$(readiness_url "$pkg" "$new")")" != 2* ]]; then
            info "skip $pkg: $new artifact not available yet"
            continue
        fi
        bump_simple "$pkg" "$old" "$new" && changed=1
    fi
done

if [[ "$changed" == 1 && "$PUSH" == 1 && "$DRY_RUN" == 0 ]]; then
    if git push origin "$BRANCH"; then
        info "pushed to origin/$BRANCH"
    else
        die "git push failed"
    fi
fi

log "done"
