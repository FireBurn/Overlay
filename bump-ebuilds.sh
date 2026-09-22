#!/bin/bash
# Check known packages directly and ask the agent to assess new or complex ones.

set -uo pipefail
cd "$(dirname "$0")"

# Packages with known version sources and bump procedures.
KNOWN_PKGS=(
    dev-util/claude-code
    dev-util/antigravity-cli
    dev-util/opencode
    dev-util/qwen-code
    dev-util/pi
    dev-util/codex
    app-editors/zed
    games-util/heroic
)
AI_PKGS=( dev-util/codex app-editors/zed www-client/chromium )

# --- CLI ------------------------------------------------------------------
DRY_RUN=0
PUSH=0
PKG=""
usage() {
    cat <<'EOF'
Usage: bump-ebuilds.sh [options] [package]

Check overlay ebuilds for newer upstream versions and bump them.

Options:
  -n, --dry-run    Report what would change without touching anything
      --push       Push successful bumps after a final rebase
  -h, --help       Show this help

With no package argument, all overlay packages are checked.
Chromium requires a separate invocation: bump-ebuilds.sh www-client/chromium
Live runs pull --rebase --autostash from origin/master before checking packages.
EOF
}
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        --push)       PUSH=1 ;;
        --no-push)    PUSH=0 ;;
        -h|--help)    usage; exit 0 ;;
        -*)           echo "unknown option: $arg" >&2; usage >&2; exit 2 ;;
        *)            PKG="$arg" ;;
    esac
done

if [[ "$DRY_RUN" == 0 ]]; then
    git pull --rebase --autostash origin master || {
        echo 'ERROR: initial git pull --rebase --autostash failed' >&2
        exit 1
    }
fi

mapfile -t ALL_PKGS < <(
    find . -mindepth 3 -maxdepth 3 -name '*.ebuild' -printf '%h\n' |
        sed 's@^./@@' | sort -u
)

if [[ -n "$PKG" ]]; then
    if [[ "$PKG" != */* ]]; then            # accept a bare "claude-code"
        hit=""
        for p in "${ALL_PKGS[@]}"; do
            if [[ "${p##*/}" == "$PKG" ]]; then
                [[ -z "$hit" ]] || { echo "ambiguous package name: $PKG" >&2; exit 2; }
                hit="$p"
            fi
        done
        [[ -n "$hit" ]] || { echo "unknown package: $PKG" >&2; exit 2; }
        PKG="$hit"
    fi
    [[ " ${ALL_PKGS[*]} " == *" $PKG "* ]] || { echo "unknown package: $PKG" >&2; exit 2; }
    WORK=("$PKG")
else
    WORK=()
    for p in "${ALL_PKGS[@]}"; do
        [[ "$p" == www-client/chromium ]] || WORK+=("$p")
    done
    printf 'Chromium requires its own run: %s www-client/chromium\n' "$0"
fi

if [[ "$PKG" == www-client/chromium && "$DRY_RUN" == 0 ]]; then
    exec {chromium_lock}>/tmp/fireburn-chromium-bump.lock
    flock -n "$chromium_lock" || { echo 'ERROR: another Chromium bump is running' >&2; exit 1; }
    if pgrep -x emerge >/dev/null; then
        echo 'ERROR: another emerge is running; build Chromium on its own' >&2
        exit 1
    fi
fi

log()  { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
info() { printf '   %s\n' "$1"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

pn_of()      { echo "${1##*/}"; }
in_list() { local item="$1" p; shift; for p; do [[ "$p" == "$item" ]] && return 0; done; return 1; }

package_clean() {
    [[ -z "$(git status --porcelain -- "$1")" ]]
}

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

# The tags to consider for a package, newest first.
#
# Most packages are tracked by their GitHub releases, which is what marks a
# version as one users are meant to have. opencode is tracked by its tags
# instead: it tags the line we follow without ever publishing a release for
# it, so going by releases would hold us on a version we do not want.
upstream_tags() {
    local pkg="$1" repo="$2"
    case "$pkg" in
        dev-util/opencode)
            gh api "repos/$repo/tags?per_page=100" --jq '.[].name' 2>/dev/null ;;
        *)
            gh release list --repo "$repo" --limit 30 \
                --json tagName,isPrerelease \
                --jq '.[] | select(.isPrerelease|not) | .tagName' 2>/dev/null ;;
    esac
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
    # Keep only versions whose tag carries this package's prefix, then take
    # the highest PV. The prefix is what separates e.g. codex's rust-v* tags
    # from its python-v* tags, or qwen-code's v* from sdk-typescript-v*, and
    # a PV still has to start with a digit: opencode also carries vscode-v*
    # tags, which share the v prefix but are a different thing entirely.
    while IFS= read -r t; do
        [[ -n "$t" ]] || continue
        if [[ -n "$prefix" ]]; then
            [[ "$t" == "$prefix"* ]] || continue
            pv="${t#"$prefix"}"
        else
            pv="$t"
        fi
        [[ "$pv" =~ ^[0-9] ]] || continue
        if [[ -z "$best" ]] || [[ "$(vercmp "$pv" "$best")" == gt ]]; then best="$pv"; fi
    done < <(upstream_tags "$pkg" "$repo")
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

# Registry packages required by the ebuild but not recorded in upstream's
# lockfile. Keep these here so dependency regeneration cannot silently drop them.
npm_extra_pkgs() {
    case "$1" in
        dev-util/qwen-code) echo "node-pty@1.1.0" ;;
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

# Regenerate CRATES for a new PV. Complex Rust packages are handled by the agent.
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
    local pkg="$1" pv="$2" ebuild="$3" spec repo prefix tmp f lock=() extras=() esb
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
    read -r -a extras <<<"$(npm_extra_pkgs "$pkg")"
    if (( ${#extras[@]} )); then
        mkdir -p "$tmp/extras"
        npm install --package-lock-only --ignore-scripts --prefix "$tmp/extras" \
            "${extras[@]}" >/dev/null || { rm -rf "$tmp"; return 1; }
        lock+=("$tmp/extras/package-lock.json")
    fi
    ./scripts/npm-deps.py "${lock[@]}" --strict --ebuild "$ebuild" || { rm -rf "$tmp"; return 1; }

    if grep -q '^ESBUILD_SLOT=' "$ebuild" && [[ "${lock[0]}" == *package-lock.json ]]; then
        esb="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["packages"]["node_modules/esbuild"]["version"])' "${lock[0]}")"
        sed -i "s/^ESBUILD_SLOT=.*/ESBUILD_SLOT=\"$esb\"/" "$ebuild"
        if ! ls dev-util/esbuild/esbuild-"$esb".ebuild >/dev/null 2>&1; then
            echo "ERROR: $pkg $pv needs dev-util/esbuild:$esb, which has no ebuild yet" >&2
            rm -rf "$tmp"
            return 1
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
    git mv -f "$newf" "$oldf" 2>/dev/null || true
    git restore --staged --worktree -- "$pkg" 2>/dev/null || true
}

retry_with_agent() {
    local pkg="$1" old="$2" new="$3" oldf="$4" newf="$5" reason="$6" result
    revert_bump "$pkg" "$oldf" "$newf"
    if ! package_clean "$pkg"; then
        echo "ERROR: could not restore $pkg after $reason" >&2
        return 2
    fi
    info "$reason; asking agent to inspect and fix it"
    bump_agent "$pkg" "$old" "$new" "$reason"
    result=$?
    [[ "$result" == 1 ]] && return 2
    return "$result"
}

# Simple bump: rename + Manifest refresh. Returns 0 on success, 2 on failure.
bump_simple() {
    local pkg="$1" old="$2" new="$3"
    local pn oldf newf
    pn="$(pn_of "$pkg")"; oldf="$(current_ebuild "$pkg")"; newf="$pkg/$pn-$new.ebuild"

    # A pinned old version needs package-specific review.
    if grep -qF "$old" "$oldf"; then
        info "$oldf contains a literal '$old'; asking agent"
        bump_agent "$pkg" "$old" "$new"
        return $?
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would bump and emerge $pkg $old -> $new"
        return 0
    fi

    git mv "$oldf" "$newf" || { echo "ERROR: git mv failed for $pkg" >&2; return 1; }
    python3 - "$newf" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

def testing_keywords(match):
    keywords = [flag if flag.startswith(("~", "-")) else "~" + flag
                for flag in match.group(1).split()]
    return 'KEYWORDS="' + ' '.join(keywords) + '"'

path.write_text(re.sub(r'^KEYWORDS="([^"]*)"', testing_keywords, text, flags=re.M))
PY
    if ! update_npm_pkgs "$pkg" "$new" "$newf"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "dependency regeneration failed"
        return $?
    fi
    if ! update_crates "$pkg" "$new" "$newf"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "Rust dependency regeneration failed"
        return $?
    fi
    if ! ebuild "$newf" digest; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "ebuild digest failed"
        return $?
    fi
    if ! ebuild "$newf" manifest; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "ebuild manifest failed"
        return $?
    fi
    local -a emerge_cmd=( emerge )
    (( EUID == 0 )) || emerge_cmd=( sudo -n emerge )
    if ! "${emerge_cmd[@]}" -1 "=$pkg-$new"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "emerge failed"
        return $?
    fi
    if ! pkgcheck scan --repo FireBurn "$pkg" ||
       ! pkgcheck scan --repo FireBurn --commits; then
        revert_bump "$pkg" "$oldf" "$newf"
        echo "ERROR: pkgcheck failed for $pkg $new (reverted)" >&2
        return 2
    fi
    git add "$pkg"
    git diff --cached --check -- "$pkg" || { revert_bump "$pkg" "$oldf" "$newf"; return 2; }
    git diff --cached -- "$pkg"
    git commit -q --only -m "$pkg: bump to $new" -- "$pkg" || { echo "ERROR: commit failed for $pkg" >&2; return 2; }
    info "bumped $pkg $old -> $new"
    return 0
}

# Returns 0 on a commit, 1 when no bump was needed, 2 on failure.
bump_agent() {
    local pkg="$1" old="$2" new="${3:-}" reason="${4:-}" head prompt
    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would ask agent to assess $pkg (local $old${new:+, upstream $new})"
        return 1
    fi

    log "agent: $pkg"
    head="$(git rev-parse HEAD)"
    prompt="Assess $pkg in this overlay (current version $old${new:+, candidate $new}${reason:+, automatic attempt: $reason}). Read AGENTS.md and .opencode/agent/ebuild-bumper.md and the existing ebuilds. If an automatic attempt failed, inspect its output and build log, then fix the cause. If no candidate is supplied, find and verify the latest appropriate upstream release. Determine whether a version bump is appropriate and whether it is a simple rename or requires package-specific work. For Chromium, follow the three-channel instructions and build exactly one Chromium version at a time with no other package builds running. Preserve the source build and update fetched dependencies and the Manifest as needed. Run a normal emerge -1 of the new package and a relevant smoke test, then pkgcheck scan --repo FireBurn --commits. Commit only if emerge installed successfully and checks pass, using one package per commit. Leave the package unchanged and report why if there is no safe bump. Do not push."

    if ! opencode run --agent ebuild-bumper "$prompt"; then
        echo "ERROR: agent bump failed for $pkg" >&2
        return 2
    fi
    if ! package_clean "$pkg"; then
        echo "ERROR: agent left uncommitted changes in $pkg" >&2
        return 2
    fi
    if [[ "$(git rev-parse HEAD)" != "$head" ]]; then
        info "agent committed $pkg"
        return 0
    fi
    info "agent made no commit for $pkg"
    return 1
}

# --- main -----------------------------------------------------------------
changed=0
failed=()
for pkg in "${WORK[@]}"; do
    log "check: $pkg"
    if ! package_clean "$pkg"; then
        info "skip $pkg: package has uncommitted changes"
        continue
    fi
    old="$(current_pv "$pkg")" || { info "no ebuild found; skipping"; continue; }
    if ! in_list "$pkg" "${KNOWN_PKGS[@]}"; then
        bump_agent "$pkg" "$old"
        case "$?" in 0) changed=1 ;; 2) failed+=("$pkg") ;; esac
        continue
    fi
    new="$(latest_pv "$pkg")"
    if [[ -z "$new" ]]; then
        info "could not determine upstream version; skipping"
        continue
    fi
    case "$(vercmp "$new" "$old")" in
        eq) info "up to date ($old)"; continue ;;
        lt) info "upstream $new is older than local $old; skipping"; continue ;;
    esac

    if in_list "$pkg" "${AI_PKGS[@]}"; then
        bump_agent "$pkg" "$old" "$new"
    else
        if [[ "$(http_code "$(readiness_url "$pkg" "$new")")" != 2* ]]; then
            info "skip $pkg: $new artifact not available yet"
            continue
        fi
        bump_simple "$pkg" "$old" "$new"
    fi
    case "$?" in
        0) changed=1 ;;
        2) failed+=("$pkg") ;;
    esac
done

if [[ "$changed" == 1 && "$PUSH" == 1 && "$DRY_RUN" == 0 ]]; then
    git pull --rebase --autostash origin master || die "git pull --rebase --autostash failed; not pushing"
    if git push origin master; then
        info "pushed to origin/master"
    else
        die "git push failed"
    fi
fi

if [[ "${#failed[@]}" -gt 0 ]]; then
    log "failed"
    for pkg in "${failed[@]}"; do
        info "$pkg"
    done
    exit 1
fi

log "done"
