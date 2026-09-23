#!/bin/bash
# Check upstream versions with scripts/upstream-version.py, bump known packages
# directly and ask the agent only about outdated, unknown or complex ones.

set -uo pipefail
cd "$(dirname "$0")"

# Packages with known bump procedures (rename + dependency regeneration).
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
RETRY=0
PKG=""
usage() {
    cat <<'EOF'
Usage: bump-ebuilds.sh [options] [package]

Check overlay ebuilds for newer upstream versions and bump them.

Options:
  -n, --dry-run    Report what would change without touching anything
      --push       Push successful bumps after a final rebase
      --retry      Retry candidates the agent declined in an earlier run
  -h, --help       Show this help

With no package argument, all overlay packages are checked.
Chromium requires a separate invocation: bump-ebuilds.sh www-client/chromium
Live runs pull --rebase --autostash from origin/master before checking packages.
Upstream version sources are listed in scripts/upstream-sources.
Logs and timings are written to ${XDG_STATE_HOME:-~/.local/state}/bump-ebuilds.
Candidates the agent declines are recorded in declined.tsv there. That candidate
is skipped until --retry, and newer ones for a week.
EOF
}
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        --push)       PUSH=1 ;;
        --no-push)    PUSH=0 ;;
        --retry)      RETRY=1 ;;
        -h|--help)    usage; exit 0 ;;
        -*)           echo "unknown option: $arg" >&2; usage >&2; exit 2 ;;
        *)            PKG="$arg" ;;
    esac
done

# --- logging --------------------------------------------------------------
# Every run writes a full console log, and appends one line per timed step to
# timings.tsv: run, time, package, step, seconds, exit status, detail.
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/bump-ebuilds"
RUN_ID="$(date +%Y%m%d-%H%M%S)$([[ "$DRY_RUN" == 1 ]] && echo -dry)"
TIMINGS="$LOG_DIR/timings.tsv"
RUN_LOG="$LOG_DIR/$RUN_ID.log"
mkdir -p "$LOG_DIR"
[[ -s "$TIMINGS" ]] || printf 'run\ttime\tpackage\tstep\tseconds\tstatus\tdetail\n' >"$TIMINGS"
exec > >(tee -a "$RUN_LOG") 2>&1
RUN_START=$EPOCHREALTIME

log()  { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
info() { printf '   %s\n' "$1"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

elapsed() { awk -v a="$1" -v b="$EPOCHREALTIME" 'BEGIN { printf "%.1f", b - a }'; }

# record PACKAGE STEP START STATUS [DETAIL]
record() {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$RUN_ID" "$(date -Is)" "$1" "$2" \
        "$(elapsed "$3")" "$4" "${5:-}" >>"$TIMINGS"
}

# timed PACKAGE STEP COMMAND... -- run COMMAND and record how long it took.
timed() {
    local pkg="$1" step="$2" start=$EPOCHREALTIME rc
    shift 2
    "$@"; rc=$?
    record "$pkg" "$step" "$start" "$rc"
    return "$rc"
}

# Rebasing with --autostash and pkgcheck --commits both drop staged renames,
# so keep the caller's staged changes and put them back when we are done.
STAGED="$LOG_DIR/$RUN_ID.staged.diff"
git diff --cached --binary >"$STAGED"
restore_index() {
    cmp -s "$STAGED" <(git diff --cached --binary) && return
    if git reset -q && git apply --cached "$STAGED"; then
        info "restored previously staged changes"
    else
        echo "ERROR: could not restore staged changes; they are saved in $STAGED" >&2
    fi
}

if [[ "$DRY_RUN" == 0 ]]; then
    timed - git-fetch git fetch -q origin master || die "git fetch failed"
    if ! git merge-base --is-ancestor FETCH_HEAD HEAD; then
        timed - git-pull git pull --rebase --autostash origin master || {
            echo 'ERROR: initial git pull --rebase --autostash failed' >&2
            exit 1
        }
        restore_index
    fi
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

pn_of()      { echo "${1##*/}"; }
in_list() { local item="$1" p; shift; for p; do [[ "$p" == "$item" ]] && return 0; done; return 1; }

package_clean() {
    [[ -z "$(git status --porcelain -- "$1")" ]]
}

# Current non-9999 ebuild file (highest version if there are several).
current_ebuild() {
    local pkg="$1" pn
    pn="$(pn_of "$pkg")"
    ls "$pkg/$pn"-*.ebuild 2>/dev/null | grep -v -- '-9999' | sort -V | tail -n1
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

# Run --version on the package's installed commands; one must succeed.
smoke_test() {
    local bin found=0
    case "$1" in
        games-util/heroic) info "smoke test: heroic is GUI only; skipped"; return 0 ;;
    esac
    while read -r bin; do
        found=1
        if timeout 60 "$bin" --version </dev/null >/dev/null 2>&1; then
            info "smoke test: $bin --version ok"
            return 0
        fi
    done < <(qlist -e "$1" | grep -E '^/(usr/s?bin|opt/bin)/[^/]+$')
    (( found )) || { info "smoke test: $1 installs no commands; skipped"; return 0; }
    echo "ERROR: no command from $1 ran with --version" >&2
    return 1
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
    bump_agent "$pkg" "$old" "$new" "automatic attempt: $reason"
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
        bump_agent "$pkg" "$old" "$new" "the ebuild contains the literal old version"
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
    if ! timed "$pkg" npm-deps update_npm_pkgs "$pkg" "$new" "$newf"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "dependency regeneration failed"
        return $?
    fi
    if ! timed "$pkg" cargo-crates update_crates "$pkg" "$new" "$newf"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "Rust dependency regeneration failed"
        return $?
    fi
    if ! timed "$pkg" digest ebuild "$newf" digest; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "ebuild digest failed"
        return $?
    fi
    if ! timed "$pkg" manifest ebuild "$newf" manifest; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "ebuild manifest failed"
        return $?
    fi
    local -a emerge_cmd=( emerge )
    (( EUID == 0 )) || emerge_cmd=( sudo -n emerge )
    if ! timed "$pkg" emerge "${emerge_cmd[@]}" -1 "=$pkg-$new"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "emerge failed"
        return $?
    fi
    if ! timed "$pkg" smoke-test smoke_test "$pkg"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "smoke test failed after emerge"
        return $?
    fi
    if ! timed "$pkg" pkgcheck pkgcheck scan --repo FireBurn "$pkg" ||
       ! timed "$pkg" pkgcheck-commits pkgcheck scan --repo FireBurn --commits; then
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

AGENT_RULES="Keep one ebuild per package: rename the old ebuild to the new version (git mv) instead of adding one beside it, unless the package is slotted and the versions are in different slots. Live 9999 ebuilds stay. Record how to find upstream versions: if a package's entry in scripts/upstream-sources is missing, wrong or could not be checked, add or fix it using the methods documented at the top of that file, and add an @group when other ebuilds in this overlay share the same pattern. Leave scripts/upstream-sources uncommitted; the caller reports it for review. Run a normal emerge -1 of each new package and a relevant smoke test, then pkgcheck scan --repo FireBurn --commits. Commit only if emerge installed successfully and checks pass, one commit per package, using git commit --only -- <package paths> so changes already staged by someone else stay out of the commit. Leave a package unchanged and report why if there is no safe bump. Do not push."

# Token counts of opencode sessions in this directory since START_MS, for the log.
agent_usage() {
    command -v sqlite3 >/dev/null || return 0
    sqlite3 -readonly "$HOME/.local/share/opencode/opencode.db" \
        "select 'in=' || cast(total(tokens_input) as int) || ' out=' || cast(total(tokens_output) as int)
                || ' reasoning=' || cast(total(tokens_reasoning) as int)
         from session_v2 where directory = '$PWD' and time_created >= $1" 2>/dev/null
}

# Save an agent's unfinished changes to the log and restore the committed package.
restore_package() {
    local pkg="$1" saved="$LOG_DIR/$RUN_ID-${1//\//_}.diff"
    git add -N -- "$pkg"
    git diff HEAD --binary -- "$pkg" >"$saved"
    git reset -q -- "$pkg"
    git checkout -q HEAD -- "$pkg"
    git clean -fdq -- "$pkg"
    info "restored $pkg; the agent's changes are in $saved"
}

# A declined candidate stays skipped; newer candidates wait a week, so a busy
# upstream (e.g. commit snapshots) does not trigger an agent run every day.
DECLINED="$LOG_DIR/declined.tsv"
declined() {
    [[ "$RETRY" == 0 && -f "$DECLINED" ]] || return 1
    awk -F'\t' -v p="$1" -v v="$2" -v since="$(date -I -d '7 days ago')" \
        '$1 == p && ($2 == v || $3 >= since) { found = 1 } END { exit !found }' "$DECLINED"
}

# run_agent LABEL PROMPT -- returns opencode's status; output goes to its own log too.
run_agent() {
    local label="$1" prompt="$2" alog start start_ms rc
    alog="$LOG_DIR/$RUN_ID-agent-${label//\//_}.log"
    start=$EPOCHREALTIME
    start_ms=$(date +%s%3N)
    opencode run --agent ebuild-bumper "$prompt" 2>&1 | tee "$alog"
    rc=${PIPESTATUS[0]}
    record "$label" agent "$start" "$rc" "$(agent_usage "$start_ms")"
    return "$rc"
}

# Returns 0 on a commit, 1 when no bump was needed, 2 on failure.
bump_agent() {
    local pkg="$1" old="$2" new="${3:-}" reason="${4:-}" source="${5:-}" head prompt
    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would ask agent to assess $pkg (local $old${new:+, upstream $new}${reason:+; $reason})"
        return 1
    fi

    log "agent: $pkg"
    head="$(git rev-parse HEAD)"
    if [[ -n "$new" ]]; then
        prompt="Bump $pkg in this overlay from $old to $new. scripts/upstream-version.py found $new${source:+ using '$source'}; do not research the latest version again unless it looks wrong.${reason:+ Note: $reason. If an automatic attempt failed, inspect its output and build log, then fix the cause.} Decide whether this is a simple rename or needs package-specific work, preserve the source build and update fetched dependencies and the Manifest as needed. $AGENT_RULES"
    else
        prompt="Assess $pkg in this overlay (current version $old).${reason:+ Note: $reason.} Find and verify the latest appropriate upstream release. Determine whether a bump is appropriate and whether it is a simple rename or needs package-specific work. For Chromium, follow the three-channel instructions and build exactly one Chromium version at a time with no other package builds running. Preserve the source build and update fetched dependencies and the Manifest as needed. $AGENT_RULES"
    fi

    if ! run_agent "$pkg" "$prompt"; then
        echo "ERROR: agent bump failed for $pkg" >&2
        package_clean "$pkg" || restore_package "$pkg"
        return 2
    fi
    if ! package_clean "$pkg"; then
        echo "ERROR: agent left uncommitted changes in $pkg" >&2
        restore_package "$pkg"
        return 2
    fi
    if [[ "$(git rev-parse HEAD)" != "$head" ]]; then
        info "agent committed $pkg"
        return 0
    fi
    info "agent made no commit for $pkg"
    [[ -n "$new" ]] && printf '%s\t%s\t%s\t%s\n' "$pkg" "$new" "$(date -I)" \
        "$LOG_DIR/$RUN_ID-agent-${pkg//\//_}.log" >>"$DECLINED"
    return 1
}

# Chromium rotates ebuilds between its stable, beta and unstable slots; the
# plan comes from scripts/chromium-channels.py and one agent run applies it.
bump_chromium() {
    local pkg=www-client/chromium plan rc head prompt
    plan="$(timed "$pkg" channel-check scripts/chromium-channels.py)"; rc=$?
    if (( rc )); then
        info "skip $pkg: ${plan:-channel check failed}"
        return 1
    fi
    if [[ -z "$plan" ]]; then
        info "$pkg: all slots up to date"
        return 1
    fi
    printf '%s\n' "$plan" | sed 's/^/   /'
    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would ask the agent to apply this plan"
        return 1
    fi
    log "agent: $pkg"
    head="$(git rev-parse HEAD)"
    prompt="Rotate www-client/chromium to the current Linux channels. scripts/chromium-channels.py produced this plan, to be applied in order (move = git mv plus changing SLOT; copy = new file for a new major; remove = git rm):
$plan
Do not research channel versions again. Follow the Chromium build procedure in your instructions: stable is built first, beta and unstable are prepared and configured in PORTAGE_TMPDIR=/home/fireburn/portage-tmp while stable compiles, and each slot is then emerged in /var/tmp/portage one at a time. Update dev-build/gnrt and dev-build/gn if the unstable milestone needs it, each in its own commit. $AGENT_RULES"
    if ! run_agent "$pkg" "$prompt"; then
        echo "ERROR: agent bump failed for $pkg" >&2
        package_clean "$pkg" || restore_package "$pkg"
        return 2
    fi
    if ! package_clean "$pkg"; then
        echo "ERROR: agent left uncommitted changes in $pkg" >&2
        restore_package "$pkg"
        return 2
    fi
    [[ "$(git rev-parse HEAD)" != "$head" ]] && { info "agent committed $pkg"; return 0; }
    info "agent made no commit for $pkg"
    return 1
}

# One agent run for all outdated members of a batch group, e.g. ROCm, which
# share a release and must be built together in dependency order.
# Adds committed packages to BUMPED and the rest to failed.
bump_group() {
    local group="$1" new="$2" pkg head prompt; shift 2
    local -a pkgs=("$@")
    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would ask one agent to bump $group to $new: ${pkgs[*]}"
        return
    fi
    log "agent: $group -> $new (${#pkgs[@]} packages)"
    head="$(git rev-parse HEAD)"
    prompt="Bump the $group group in this overlay to $new: ${pkgs[*]}. scripts/upstream-version.py found $new from the group's entry in scripts/upstream-sources; do not research the latest version again unless it looks wrong. These packages share one upstream release. Review upstream changes once for the whole group and update every ebuild. If the group has a -meta package, add any new member package to it and build the group through it with emerge --update --deep on the meta package, which is in @world; otherwise use a single emerge -1 of all the new versions so Portage orders them. If one fails, fix it and resume rather than restarting the group. Commit each package separately. $AGENT_RULES"
    run_agent "$group" "$prompt" || echo "ERROR: agent run for $group failed" >&2
    for pkg in "${pkgs[@]}"; do
        if ! package_clean "$pkg"; then
            echo "ERROR: agent left uncommitted changes in $pkg" >&2
            restore_package "$pkg"
            failed+=("$pkg")
        elif [[ -n "$(git log --format=%h "$head..HEAD" -- "$pkg")" ]]; then
            changed=1
        else
            failed+=("$pkg")
        fi
    done
}

# Print ebuilds that share a slot with another non-live ebuild of the package.
extra_ebuilds() {
    local pkg="$1" e cpv slot
    local -A seen=()
    for e in "$pkg"/*.ebuild; do
        cpv="${pkg%/*}/$(basename "$e" .ebuild)"
        [[ "$cpv" == *9999* ]] && continue
        slot="$(portageq metadata / ebuild "$cpv" SLOT 2>/dev/null)"
        slot="${slot%%/*}"
        [[ -n "${seen[$slot]:-}" ]] && echo "$cpv shares SLOT $slot with ${seen[$slot]}"
        seen[$slot]="$cpv"
    done
}

# --- main -----------------------------------------------------------------
START_HEAD="$(git rev-parse HEAD)"
changed=0
failed=()
inferred=()
declare -A GROUP_PKGS=() GROUP_VER=()

log "checking upstream versions"
VERSIONS="$LOG_DIR/$RUN_ID.versions.tsv"
timed - version-check scripts/upstream-version.py "${WORK[@]}" >"$VERSIONS" ||
    die "scripts/upstream-version.py failed"

# A tab IFS would merge empty columns, so read with a non-whitespace separator.
while IFS=$'\037' read -r pkg status old new group batch source note <&3; do
    [[ "$note" == inferred* ]] && inferred+=("${note#*record as: }")
    case "$status" in
        live|skip)
            continue ;;
        current)
            info "$pkg: up to date ($old)"; continue ;;
        older)
            info "$pkg: upstream $new is older than local $old; skipping"; continue ;;
    esac
    if ! package_clean "$pkg"; then
        info "skip $pkg: package has uncommitted changes ($status${new:+ $old -> $new})"
        continue
    fi
    if [[ "$status" == newer ]] && declined "$pkg" "$new"; then
        info "skip $pkg: the agent declined it recently (see $DECLINED; --retry to recheck)"
        continue
    fi
    if [[ "$status" == newer && -n "$batch" ]]; then
        info "$pkg: $old -> $new, queued with $group"
        GROUP_PKGS[$group]+="$pkg "
        GROUP_VER[$group]="$new"
        continue
    fi
    log "$pkg: $status${new:+ $old -> $new}"
    start=$EPOCHREALTIME
    case "$status" in
        agent)
            if [[ "$pkg" == www-client/chromium ]]; then
                bump_chromium
            else
                bump_agent "$pkg" "$old" "" "$note"
            fi ;;
        error)
            bump_agent "$pkg" "$old" "" "the upstream version lookup '$source' failed ($note); fix its scripts/upstream-sources entry" ;;
        newer)
            if in_list "$pkg" "${KNOWN_PKGS[@]}" && ! in_list "$pkg" "${AI_PKGS[@]}"; then
                if [[ "$(http_code "$(readiness_url "$pkg" "$new")")" != 2* ]]; then
                    info "skip $pkg: $new artifact not available yet"
                    continue
                fi
                bump_simple "$pkg" "$old" "$new"
            else
                bump_agent "$pkg" "$old" "$new" "" "$source"
            fi ;;
        *)
            info "unexpected status '$status' for $pkg"; continue ;;
    esac
    rc=$?
    record "$pkg" total "$start" "$rc" "$status $old${new:+ -> $new}"
    case "$rc" in
        0) changed=1 ;;
        2) failed+=("$pkg") ;;
    esac
done 3< <(tr '\t' '\037' <"$VERSIONS")

for group in "${!GROUP_PKGS[@]}"; do
    start=$EPOCHREALTIME
    read -r -a members <<<"${GROUP_PKGS[$group]}"
    bump_group "$group" "${GROUP_VER[$group]}" "${members[@]}"
    record "$group" total "$start" 0 "${#members[@]} packages -> ${GROUP_VER[$group]}"
done

if [[ "$changed" == 1 && "$PUSH" == 1 && "$DRY_RUN" == 0 ]]; then
    timed - git-pull git pull --rebase --autostash origin master || die "git pull --rebase --autostash failed; not pushing"
    if timed - git-push git push origin master; then
        info "pushed to origin/master"
    else
        die "git push failed"
    fi
fi

record - run "$RUN_START" 0
[[ "$DRY_RUN" == 0 ]] && restore_index

mapfile -t extras < <(
    for pkg in "${WORK[@]}"; do
        [[ -n "$(git log --format=%h "$START_HEAD..HEAD" -- "$pkg")" ]] && extra_ebuilds "$pkg"
    done
)
if (( ${#extras[@]} )); then
    log "bumped packages with more than one ebuild per slot"
    for line in "${extras[@]}"; do info "$line"; done
fi

if (( ${#inferred[@]} )); then
    log "inferred sources; add these to scripts/upstream-sources"
    for line in "${inferred[@]}"; do info "$line"; done
fi
if ! git diff --quiet -- scripts/upstream-sources; then
    log "scripts/upstream-sources was updated; review and commit it"
    git --no-pager diff -- scripts/upstream-sources
fi

log "slowest steps"
awk -F'\t' -v run="$RUN_ID" '$1 == run && $4 != "run" && $4 != "total"' "$TIMINGS" |
    sort -t$'\t' -k5,5gr | head -n 10 |
    awk -F'\t' '{ printf "   %8.1fs  %-10s %s %s\n", $5, $4, $3, $7 }'
info "run took $(elapsed "$RUN_START")s; log: $RUN_LOG"

if [[ "${#failed[@]}" -gt 0 ]]; then
    log "failed"
    for pkg in "${failed[@]}"; do
        info "$pkg"
    done
    exit 1
fi

log "done"
