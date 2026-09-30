#!/bin/bash
# Check upstream versions with scripts/upstream-version.py, bump known packages
# directly and ask the agent only about outdated, unknown or complex ones.

set -uo pipefail
cd "$(dirname "$0")"

# Packages that always go to the agent. Everything else with a single
# non-live ebuild is bumped mechanically (rename, digest, emerge) first and
# only reaches the agent if a step fails.
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
      --push       Push each bump right after its commit (rebasing if needed)
      --retry      Retry candidates the agent declined in an earlier run
  -h, --help       Show this help

With no package argument, all overlay packages are checked.
Chromium is always handled last, one slot at a time.
Live runs pull --rebase --autostash from origin/master before checking packages.
With --push each commit is pushed as soon as its emerge has succeeded.
Upstream version sources are listed in scripts/upstream-sources.
Logs are written to ~/bump-work/runs/<run>/, timings and declined candidates
to ~/bump-work/state/. Bumps that do not finish are left uncommitted here.
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
#
# Where things live:
#   $BUMP_WORK/state/    timings.tsv and declined.tsv, kept between runs
#   $BUMP_WORK/runs/     one directory per run (console log, step logs, agent
#                        transcripts); runs older than 30 days are removed
#   $SCRATCH/<package>/  scratch for downloads and checkouts; emptied at the
#                        start and end of a run
# Builds run in /var/tmp/portage with Portage's own temp/build.log. Ebuilds
# being worked on stay in this overlay, uncommitted, if a bump does not finish.
BUMP_WORK=/home/fireburn/bump-work
LOG_DIR="$BUMP_WORK/state"
SCRATCH="$BUMP_WORK/scratch"
RUN_ID="$(date +%Y%m%d-%H%M%S)$([[ "$DRY_RUN" == 1 ]] && echo -dry)"
RUN_DIR="$BUMP_WORK/runs/$RUN_ID"
TIMINGS="$LOG_DIR/timings.tsv"
RUN_LOG="$RUN_DIR/run.log"
mkdir -p "$RUN_DIR" "$SCRATCH" "$LOG_DIR"
if [[ "$DRY_RUN" == 0 ]]; then
    exec 9>"$LOG_DIR/lock"
    flock -n 9 || { echo "another bump-ebuilds run is active" >&2; exit 1; }
fi
[[ -s "$TIMINGS" ]] || printf 'run\ttime\tpackage\tstep\tseconds\tstatus\tdetail\n' >"$TIMINGS"
exec > >(tee -a "$RUN_LOG") 2>&1
RUN_START=$EPOCHREALTIME

log()  { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
ok()   { printf '   \033[32mok\033[0m    %s\n' "$1"; }
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

# Step output (digest, emerge, pkgcheck, ...) goes to a file per step; the
# console gets one status line, and the log tail if the step fails.
STEP_LOGS="$RUN_DIR/steps"
LAST_STEP_LOG=""
mkdir -p "$STEP_LOGS"

# Print a line every few minutes while a long step or agent is running.
# heartbeat_start LABEL [LOGFILE] sets HB_PID; heartbeat_stop ends it.
HB_PID=""
heartbeat_start() {
    local label="$1" alog="${2:-}" t0=$SECONDS parent=$$
    (
        while kill -0 "$parent" 2>/dev/null && sleep 300; do
            last=""
            [[ -n "$alog" ]] && last="$(sed 's/\x1b\[[0-9;]*m//g' "$alog" 2>/dev/null |
                grep -a '^\$ ' | tail -n1 | cut -c1-90)"
            printf '   ...   %s: %dm%s\n' "$label" $(( (SECONDS - t0) / 60 )) "${last:+, last: $last}"
        done
    ) 2>/dev/null &
    HB_PID=$!
}
heartbeat_stop() {
    [[ -n "$HB_PID" ]] || return 0
    pkill -P "$HB_PID" 2>/dev/null
    kill "$HB_PID" 2>/dev/null
    wait "$HB_PID" 2>/dev/null
    HB_PID=""
}

# run_step PACKAGE STEP COMMAND... -- timed, output kept in the step log.
run_step() {
    local pkg="$1" step="$2" start=$EPOCHREALTIME rc slog secs
    shift 2
    slog="$STEP_LOGS/${pkg//\//_}-$step.log"
    LAST_STEP_LOG="$slog"
    heartbeat_start "$pkg $step"
    "$@" </dev/null >"$slog" 2>&1; rc=$?
    heartbeat_stop
    record "$pkg" "$step" "$start" "$rc"
    secs="$(elapsed "$start")"
    if (( rc == 0 )); then
        printf '   \033[32mok\033[0m    %-14s %ss\n' "$step" "$secs"
    else
        printf '   \033[31mFAIL\033[0m  %-14s %ss  (%s)\n' "$step" "$secs" "$slog"
        tail -n 12 "$slog" | cut -c1-200 | sed 's/^/         | /'
    fi
    return "$rc"
}

# Rebasing with --autostash and pkgcheck --commits both drop staged renames,
# so keep the caller's staged changes and put them back when we are done.
STAGED="$RUN_DIR/staged.diff"
git diff --cached --binary >"$STAGED"
RESTORED=0
restore_index() {
    (( RESTORED )) && return
    local -a skip=()
    local f
    cmp -s "$STAGED" <(git diff --cached --binary) && return
    # Paths committed by this run are no longer staged changes.
    if [[ -n "${START_HEAD:-}" ]]; then
        while read -r f; do skip+=(--exclude="$f"); done \
            < <(git diff --name-only --no-renames "$START_HEAD" HEAD)
    fi
    if git reset -q && git apply --cached "${skip[@]}" "$STAGED"; then
        info "restored previously staged changes"
        RESTORED=1
    else
        echo "ERROR: could not restore staged changes; they are saved in $STAGED" >&2
    fi
}

# Rebase onto origin/master if it moved, then push. Called after every commit
# when --push is given, so a later failure cannot hold back finished bumps.
push_commits() {
    [[ "$PUSH" == 1 && "$DRY_RUN" == 0 ]] || return 0
    if run_step - git-fetch git fetch -q origin master &&
       ! git merge-base --is-ancestor FETCH_HEAD HEAD; then
        run_step - git-rebase git pull --rebase --autostash origin master || return 1
        restore_index
    fi
    run_step - git-push git push -q origin master
}

# pkgcheck --commits stashes the work tree and fails on a dirty one (staged
# renames, ignored paths), so scan the committed HEAD in a separate worktree.
PKGCHECK_WT="${XDG_CACHE_HOME:-$HOME/.cache}/bump-ebuilds/pkgcheck-wt"
pkgcheck_head() {
    [[ -e "$PKGCHECK_WT/.git" ]] || {
        mkdir -p "${PKGCHECK_WT%/*}"
        git worktree prune
        git worktree add -q --detach "$PKGCHECK_WT" HEAD || return 1
    }
    git -C "$PKGCHECK_WT" checkout -q --detach "$(git rev-parse HEAD)" &&
        (cd "$PKGCHECK_WT" && pkgcheck scan --commits)
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
    WORK=("${ALL_PKGS[@]}")
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
    bump_agent "$pkg" "$old" "$new" "automatic attempt: $reason${LAST_STEP_LOG:+; output of the failed step is in $LAST_STEP_LOG}"
    result=$?
    [[ "$result" == 1 ]] && return 2
    return "$result"
}

# Simple bump: rename + Manifest refresh. Returns 0 on success, 2 on failure.
bump_simple() {
    local pkg="$1" old="$2" new="$3"
    local pn oldf newf
    pn="$(pn_of "$pkg")"; oldf="$(current_ebuild "$pkg")"; newf="$pkg/$pn-$new.ebuild"

    # A pinned old version needs package-specific review. Dependency entries
    # such as name@1.2.3 in NPM_PKGS or CRATES may share it by coincidence.
    if grep -qP "(?<![@\\w.-])\Q$old\E(?![\\w.])" "$oldf"; then
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
    # Regeneration is skipped for packages without a lockfile, so only the
    # ones that need it show up as steps.
    if [[ -n "$(npm_lockfiles "$pkg")" ]] &&
       ! run_step "$pkg" npm-deps update_npm_pkgs "$pkg" "$new" "$newf"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "dependency regeneration failed"
        return $?
    fi
    if [[ -n "$(cargo_lockfiles "$pkg")" ]] &&
       ! run_step "$pkg" cargo-crates update_crates "$pkg" "$new" "$newf"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "Rust dependency regeneration failed"
        return $?
    fi
    # One step: digest fetches the distfiles, manifest writes the file.
    if ! run_step "$pkg" manifest ebuild "$newf" manifest; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "ebuild manifest failed"
        return $?
    fi
    local -a emerge_cmd=( env PORTAGE_TMPDIR=/var/tmp emerge )
    (( EUID == 0 )) || emerge_cmd=( sudo -n env PORTAGE_TMPDIR=/var/tmp emerge )
    if ! run_step "$pkg" emerge "${emerge_cmd[@]}" -1 "=$pkg-$new"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "emerge failed"
        return $?
    fi
    if ! run_step "$pkg" smoke-test smoke_test "$pkg"; then
        retry_with_agent "$pkg" "$old" "$new" "$oldf" "$newf" "smoke test failed after emerge"
        return $?
    fi
    if ! run_step "$pkg" pkgcheck pkgcheck scan --repo FireBurn "$pkg"; then
        echo "ERROR: pkgcheck failed for $pkg $new" >&2
        leave_package "$pkg"
        return 2
    fi
    git add "$pkg"
    git diff --cached --check -- "$pkg" || { leave_package "$pkg"; return 2; }
    git commit -q --only -m "$pkg: bump to $new" -- "$pkg" || { echo "ERROR: commit failed for $pkg" >&2; return 2; }
    if ! run_step "$pkg" pkgcheck-commits pkgcheck_head; then
        git reset -q --soft HEAD~1
        echo "ERROR: pkgcheck --commits failed for $pkg $new" >&2
        leave_package "$pkg"
        return 2
    fi
    info "bumped $pkg $old -> $new"
    return 0
}

AGENT_RULES="Work only on the ebuilds in this overlay and leave them there, uncommitted, if you cannot finish. Builds run in Portage's default /var/tmp/portage; never set PORTAGE_TMPDIR. Read build failures in Portage's own /var/tmp/portage/<category>/<package>-<version>/temp/build.log and do not copy build logs elsewhere. Put downloads, unpacked sources and checkouts in $SCRATCH/<package name>/ and nowhere else outside the overlay (not /tmp); the caller empties it. Start long builds detached with their console output sent to /dev/null and block on the process until it ends. After fixing a failed build, resume with ebuild <ebuild> compile, and when the phases pass finish with sudo ebuild <ebuild> install qmerge, which installs the finished work directory without another full build; use a clean emerge only when the fix requires a fresh build. Keep one ebuild per package: rename the old ebuild to the new version (git mv) instead of adding one beside it, unless the package is slotted and the versions are in different slots. Live 9999 ebuilds stay. Record how to find upstream versions: if a package's entry in scripts/upstream-sources is missing, wrong or could not be checked, add or fix it using the methods documented at the top of that file, and add an @group when other ebuilds in this overlay share the same pattern. Leave scripts/upstream-sources uncommitted; the caller reports it for review. Run a normal emerge -1 of each new package and a relevant smoke test, then pkgcheck scan --repo FireBurn --commits. Commit only if emerge installed successfully and checks pass, one commit per package, using git commit --only -- <package paths> so changes already staged by someone else stay out of the commit. Leave a package unchanged and report why if there is no safe bump. Do not push."

# Token counts of opencode sessions in this directory since START_MS, for the log.
agent_usage() {
    command -v sqlite3 >/dev/null || return 0
    sqlite3 -readonly "$HOME/.local/share/opencode/opencode.db" \
        "select 'in=' || cast(total(tokens_input) as int) || ' out=' || cast(total(tokens_output) as int)
                || ' reasoning=' || cast(total(tokens_reasoning) as int)
         from session_v2 where directory = '$PWD' and time_created >= $1" 2>/dev/null
}

# Unfinished work stays in the overlay for the user; it is listed at the end.
UNFINISHED=()
leave_package() {
    package_clean "$1" && return 0
    in_list "$1" "${UNFINISHED[@]}" || UNFINISHED+=("$1")
    info "left $1 uncommitted in the overlay"
}

# Scratch files and Portage work directories are removed at the start and end
# of a run. Portage directories are left alone while any build is running, and
# Chromium's are kept while a rotation is waiting to be resumed.
CURRENT_PKG=""
cleanup() {
    trap - EXIT
    heartbeat_stop
    [[ "$DRY_RUN" == 1 ]] && return
    restore_index
    sudo -n find "$SCRATCH" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null
    if [[ -z "$(portage_jobs)" ]]; then
        local keep="^$"
        package_clean "$CHROMIUM" || keep="/var/tmp/portage/${CHROMIUM%/*}/${CHROMIUM#*/}-|portage-tmp/portage/${CHROMIUM%/*}/${CHROMIUM#*/}-"
        sudo -n rm -rf /var/tmp/portage/portage
        find /var/tmp/portage "$HOME/portage-tmp/portage" -mindepth 2 -maxdepth 2 -type d -name '*-[0-9]*' 2>/dev/null |
            grep -Ev "$keep" | xargs -r sudo -n rm -rf
    fi
    find "$BUMP_WORK/runs" -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} + 2>/dev/null
}
trap cleanup EXIT
trap 'exit 130' INT TERM HUP

# A declined candidate stays skipped; newer candidates wait a week, so a busy
# upstream (e.g. commit snapshots) does not trigger an agent run every day.
DECLINED="$LOG_DIR/declined.tsv"
declined() {
    [[ "$RETRY" == 0 && -f "$DECLINED" ]] || return 1
    awk -F'\t' -v p="$1" -v v="$2" -v since="$(date -I -d '7 days ago')" \
        '$1 == p && ($2 == v || $3 >= since) { found = 1 } END { exit !found }' "$DECLINED"
}

# Whether the agent's model server answers; checked once per run.
AGENT_UP=""
agent_available() {
    local url
    if [[ -z "$AGENT_UP" ]]; then
        url="$(python3 -c 'import json, os, sys
c = json.load(open(os.path.expanduser("~/.config/opencode/opencode.json")))
prov = c["model"].split("/")[0]
print(c["provider"][prov]["options"]["baseURL"].removesuffix("/v1"))' 2>/dev/null)"
        if [[ -z "$url" ]] || curl -sf -m 10 "$url/health" >/dev/null; then
            AGENT_UP=1
        else
            AGENT_UP=0
            echo "ERROR: the agent's model server at $url is not answering; agent steps are skipped" >&2
        fi
    fi
    [[ "$AGENT_UP" == 1 ]]
}

# PIDs of Portage builds that are running now.
portage_jobs() { pgrep -f 'python-exec/[^/]+/(emerge|ebuild) ' | sort; }

# run_agent LABEL PROMPT -- returns opencode's status; output goes to its own log too.
# The model sometimes ends its turn to wait for a build it started in the
# background, which ends the run and leaves the build unattended. When that
# happens, wait for the build here and hand the result back to the same session.
run_agent() {
    local label="$1" prompt="$2" alog start start_ms rc round=0 session before
    agent_available || return 2
    alog="$RUN_DIR/agent-${label//\//_}.log"
    session="ses_bump${RUN_ID//[^0-9]/}${label//[^A-Za-z0-9]/}"
    before="$(portage_jobs)"
    start=$EPOCHREALTIME
    start_ms=$(date +%s%3N)
    info "agent started; transcript: $alog"
    heartbeat_start "agent $label" "$alog"
    opencode run --agent ebuild-bumper --session "$session" "$prompt" </dev/null >"$alog" 2>&1
    rc=$?
    while (( round < 4 )) && [[ -n "$(comm -13 <(echo "$before") <(portage_jobs))" ]]; do
        round=$((round + 1))
        info "agent ended its turn with a build still running; waiting for it (round $round)"
        while [[ -n "$(comm -13 <(echo "$before") <(portage_jobs))" ]]; do sleep 30; done
        opencode run --agent ebuild-bumper --session "$session" "The build you started has finished. Read the end of its log and Portage's build.log, then carry on with the task: fix any failure and resume, run the smoke test and pkgcheck, and commit as instructed. Do not end your turn while a job is running." </dev/null >>"$alog" 2>&1
        rc=$?
    done
    heartbeat_stop
    record "$label" agent "$start" "$rc" "$(agent_usage "$start_ms")"
    printf '   %s  agent          %ss  %s\n' "$( ((rc)) && echo FAIL || echo ok )" \
        "$(elapsed "$start")" "$(agent_usage "$start_ms")"
    return "$rc"
}

# Returns 0 on a commit, 1 when no bump was needed, 2 on failure.
bump_agent() {
    local pkg="$1" old="$2" new="${3:-}" reason="${4:-}" source="${5:-}" head prompt
    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would ask agent to assess $pkg (local $old${new:+, upstream $new}${reason:+; $reason})"
        return 1
    fi

    head="$(git rev-parse HEAD)"
    if [[ -n "$new" ]]; then
        prompt="Bump $pkg in this overlay from $old to $new. scripts/upstream-version.py found $new${source:+ using '$source'}; do not research the latest version again unless it looks wrong.${reason:+ Note: $reason. If an automatic attempt failed, inspect its output and build log, then fix the cause.} Decide whether this is a simple rename or needs package-specific work, preserve the source build and update fetched dependencies and the Manifest as needed. $AGENT_RULES"
    else
        prompt="Assess $pkg in this overlay (current version $old).${reason:+ Note: $reason.} Find and verify the latest appropriate upstream release. Determine whether a bump is appropriate and whether it is a simple rename or needs package-specific work. For Chromium, follow the three-channel instructions and build exactly one Chromium version at a time with no other package builds running. Preserve the source build and update fetched dependencies and the Manifest as needed. $AGENT_RULES"
    fi

    if ! run_agent "$pkg" "$prompt"; then
        echo "ERROR: agent bump failed for $pkg" >&2
        leave_package "$pkg"
        return 2
    fi
    if ! package_clean "$pkg"; then
        echo "ERROR: agent left uncommitted changes in $pkg" >&2
        leave_package "$pkg"
        return 2
    fi
    if [[ "$(git rev-parse HEAD)" != "$head" ]]; then
        info "agent committed $pkg"
        return 0
    fi
    info "agent made no commit for $pkg"
    [[ -n "$new" ]] && printf '%s\t%s\t%s\t%s\n' "$pkg" "$new" "$(date -I)" \
        "$RUN_DIR/agent-${pkg//\//_}.log" >>"$DECLINED"
    return 1
}

# Chromium rotates ebuilds between its stable, beta and unstable slots. The
# script applies the plan from scripts/chromium-channels.py and runs the builds
# itself; the agent is only asked to fix a specific failure. The first slot to
# build is emerged in /var/tmp/portage while the others are unpacked and
# configured in the roomier PREP_TMPDIR to catch patch and configure failures
# early. A rotation left uncommitted by an interrupted run is resumed, and a
# slot whose version is already installed is not rebuilt.
CHROMIUM=www-client/chromium
CHROMIUM_LOGS="$RUN_DIR/chromium"
PREP_TMPDIR=/home/fireburn/portage-tmp
CHROMIUM_FIX_ATTEMPTS=2

chromium_ebuild() { grep -l "^SLOT=\"$1\"" "$CHROMIUM"/chromium-*.ebuild 2>/dev/null | head -n1; }
chromium_version() { basename "$1" .ebuild | sed 's/^chromium-//'; }
chromium_built() {
    [[ "$(portageq best_version / "$CHROMIUM:$1")" == "$CHROMIUM-$2" ]]
}
chromium_bin() {
    case "$1" in stable) echo /usr/bin/chromium ;; *) echo "/usr/bin/chromium-$1" ;; esac
}

apply_chromium_plan() {
    local op a b c d
    while read -r op a b c d _; do
        case "$op" in
            copy|move)
                # op SLOT SRC -> DST
                if [[ "$op" == copy ]]; then
                    cp "$CHROMIUM/$b" "$CHROMIUM/$d" && git add "$CHROMIUM/$d"
                else
                    git mv "$CHROMIUM/$b" "$CHROMIUM/$d"
                fi || return 1
                sed -i "s/^SLOT=\".*\"/SLOT=\"$a\"/" "$CHROMIUM/$d" || return 1 ;;
            remove) git rm -q "$CHROMIUM/$a" || return 1 ;;
        esac
    done <<<"$1"
}

# kill_tree PID... -- stop processes and all their descendants.
kill_tree() {
    local p
    for p in "$@"; do
        # shellcheck disable=SC2046
        kill_tree $(pgrep -P "$p")
        sudo -n kill -9 "$p" 2>/dev/null
    done
}

# chromium_fix SLOT PHASE LOG TMPDIR -- ask the agent to fix one failure.
chromium_fix() {
    local slot="$1" phase="$2" flog="$3" tmp="$4" e v rc
    e="$(chromium_ebuild "$slot")"; v="$(chromium_version "$e")"
    [[ "$DRY_RUN" == 1 ]] && return 1
    info "asking the agent to fix $CHROMIUM $v ($slot): $phase failed"
    run_agent "$CHROMIUM-$slot" "Chromium $v ($slot slot, $e) failed in $phase with PORTAGE_TMPDIR=$tmp. The end of the log is in $flog; the full build log is $tmp/portage/$CHROMIUM-$v/temp/build.log. Fix the cause in $e or its patches in $CHROMIUM/files; do not change the other slots' ebuilds. If the fix needs dev-build/gn or dev-build/gnrt updated, do that, emerge it and commit it on its own. Verify by resuming with 'sudo env PORTAGE_TMPDIR=$tmp ebuild $e <phase>' from the failed phase; clean first only if the fix changes patches, compilers or configure options. Stop when that phase passes, or report why it cannot be fixed. Do not run emerge for Chromium and do not commit Chromium; the caller rebuilds and commits it. Never end your turn while a job you started is running."
    rc=$?
    # A build the agent left running, e.g. when the model server dropped, can
    # block on its dead terminal. Stop it; the next build resumes its work.
    # shellcheck disable=SC2046
    kill_tree $(pgrep -f -- "[/ ]chromium-$v([].[:space:]]|$)" | grep -vx "$$")
    return "$rc"
}

# chromium_prepare SLOT -- unpack, patch and configure in PREP_TMPDIR, with fixes.
chromium_prepare() {
    local slot="$1" e attempt=0 plog
    e="$(chromium_ebuild "$slot")"
    plog="$CHROMIUM_LOGS/prepare-$slot.log"
    while true; do
        info "preparing $slot ($(chromium_version "$e")) in $PREP_TMPDIR"
        if timed "$CHROMIUM-$slot" prepare \
            sudo -n env PORTAGE_TMPDIR="$PREP_TMPDIR" ebuild "$e" clean configure >"$plog" 2>&1; then
            sudo -n env PORTAGE_TMPDIR="$PREP_TMPDIR" ebuild "$e" clean >/dev/null 2>&1
            return 0
        fi
        (( attempt++ < CHROMIUM_FIX_ATTEMPTS )) || return 1
        chromium_fix "$slot" configure "$plog" "$PREP_TMPDIR" || return 1
    done
}

# chromium_emerge SLOT [ATTEMPTS] -- the real emerge in /var/tmp/portage. On a
# failure the agent fixes it and the emerge is repeated, up to ATTEMPTS times.
# With ATTEMPTS=0 it runs once, as the background build does, so that only one
# agent works on Chromium at a time. "resume" fixes the last failure first.
chromium_emerge() {
    local slot="$1" attempts="${2:-$CHROMIUM_FIX_ATTEMPTS}" e v attempt=0 elog features=""
    e="$(chromium_ebuild "$slot")"; v="$(chromium_version "$e")"
    elog="$CHROMIUM_LOGS/emerge-$slot.log"
    if [[ "$attempts" == resume ]]; then
        attempts=$CHROMIUM_FIX_ATTEMPTS
        (( attempt++ ))
        chromium_fix "$slot" "the emerge" "$elog.tail" /var/tmp || return 1
        features=keepwork
    elif [[ -e "/var/tmp/portage/$CHROMIUM-$v/.prepared" ]]; then
        # Left by an interrupted run or a fix that was not finished.
        features=keepwork
    fi
    while true; do
        # After a fix, keepwork resumes from the phases the agent completed;
        # the agent cleans the work directory when a fix needs a fresh build.
        info "emerging $slot ($v) in /var/tmp/portage${features:+, resuming its work directory}"
        # /var/tmp/portage is RAM; drop work directories of other versions left
        # by interrupted runs. Only one Chromium emerge uses it at a time.
        find /var/tmp/portage/"${CHROMIUM%/*}" -maxdepth 1 -name "${CHROMIUM#*/}-[0-9]*" \
            ! -name "${CHROMIUM#*/}-$v" -exec sudo -n rm -rf {} + 2>/dev/null
        # emerge replaces the saved environment in ${T}, so pkg_setup must run again.
        [[ -n "$features" ]] && sudo -n rm -f "/var/tmp/portage/$CHROMIUM-$v/.setuped"
        if timed "$CHROMIUM-$slot" emerge sudo -n env ${features:+FEATURES="$features"} \
            emerge -1 "=$CHROMIUM-$v" >"$elog" 2>&1; then
            # keepwork leaves the work directory, which fills the tmpfs.
            [[ -n "$features" ]] && sudo -n ebuild "$e" clean >/dev/null 2>&1
            timed "$CHROMIUM-$slot" smoke-test timeout 120 "$(chromium_bin "$slot")" --headless=new \
                --no-sandbox --disable-gpu --dump-dom 'data:text/html,<p>smoke-ok</p>' 2>/dev/null |
                grep -q smoke-ok && return 0
            echo "ERROR: $slot ($v) installed but failed its smoke test" >&2
            return 1
        fi
        tail -n 80 "$elog" >"$elog.tail"
        (( attempt++ < attempts )) || return 1
        chromium_fix "$slot" "the emerge" "$elog.tail" /var/tmp || return 1
        features=keepwork
    done
}

# Paths one slot's commit covers: its ebuild, the patches that ebuild names
# in FILESDIR, the Manifest and, for the first commit, ebuilds the rotation
# removed.
chromium_slot_paths() {
    local slot="$1" e f
    e="$(chromium_ebuild "$slot")"
    printf '%s\n' "$e" "$CHROMIUM/Manifest"
    grep -oE '\$\{FILESDIR\}/[^"[:space:])]+' "$e" | sed "s|^\${FILESDIR}/|$CHROMIUM/files/|" |
        while read -r f; do [[ -e "$f" ]] && echo "$f"; done
}

# chromium_commit SLOT -- commit what changed for a slot that has just built.
chromium_commit() {
    local slot="$1" e v line
    local -a paths=()
    e="$(chromium_ebuild "$slot")"; v="$(chromium_version "$e")"
    mapfile -t paths < <(chromium_slot_paths "$slot" | sort -u)
    # Removed ebuilds belong to the first commit made.
    while read -r line; do paths+=("$line"); done < <(git ls-files --deleted "$CHROMIUM" |
        grep 'chromium-[0-9].*\.ebuild$'; git diff --cached --no-renames --name-only --diff-filter=D -- "$CHROMIUM")
    git add -A -- "${paths[@]}" 2>/dev/null
    if git diff --cached --quiet -- "${paths[@]}"; then
        info "$slot ($v): nothing to commit"
        return 0
    fi
    run_step "$CHROMIUM-$slot" pkgcheck pkgcheck scan --repo FireBurn "$CHROMIUM" || return 1
    git commit -q --only -m "$CHROMIUM: bump $slot to $v" -- "${paths[@]}" || return 1
    if ! run_step "$CHROMIUM-$slot" pkgcheck-commits pkgcheck_head; then
        git reset -q --soft HEAD~1
        return 1
    fi
    info "committed $CHROMIUM $slot $v"
    push_commits
}

bump_chromium() {
    local plan rc slot e v first pid ok=1
    local -a todo=()
    if [[ "$DRY_RUN" == 0 ]]; then
        exec {chromium_lock}>/tmp/fireburn-chromium-bump.lock
        flock -n "$chromium_lock" || { echo 'ERROR: another Chromium bump is running' >&2; return 2; }
        if pgrep -x emerge >/dev/null; then
            echo 'ERROR: another emerge is running; build Chromium on its own' >&2
            return 2
        fi
    fi
    plan="$(timed "$CHROMIUM" channel-check scripts/chromium-channels.py)"; rc=$?
    if (( rc )); then
        info "skip $CHROMIUM: ${plan:-channel check failed}"
        return 1
    fi
    if [[ -n "$plan" ]] && grep -qv '^keep' <<<"$plan"; then
        printf '%s\n' "$plan" | sed 's/^/   /'
        if [[ "$DRY_RUN" == 0 ]]; then
            apply_chromium_plan "$plan" || { echo "ERROR: could not apply the Chromium plan" >&2; return 2; }
            run_step "$CHROMIUM" manifest ebuild "$(chromium_ebuild stable)" manifest ||
                { echo "ERROR: Chromium manifest failed" >&2; return 2; }
        fi
    fi
    for slot in stable beta unstable; do
        e="$(chromium_ebuild "$slot")"; v="$(chromium_version "$e")"
        if chromium_built "$slot" "$v"; then
            info "$slot: $v already installed"
        else
            todo+=("$slot")
        fi
    done
    if (( ${#todo[@]} == 0 )) && package_clean "$CHROMIUM"; then
        info "$CHROMIUM: all slots up to date"
        return 1
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
        info "[dry-run] would build and commit, one slot at a time: ${todo[*]:-nothing}"
        return 1
    fi
    mkdir -p "$CHROMIUM_LOGS"
    changed_any=0
    # Slots that are installed but not yet committed (an interrupted run).
    for slot in stable beta unstable; do
        in_list "$slot" "${todo[@]}" && continue
        chromium_commit "$slot" && changed_any=1
    done
    if (( ${#todo[@]} )); then
        first="${todo[0]}"
        chromium_emerge "$first" 0 &
        pid=$!
        for slot in "${todo[@]:1}"; do
            chromium_prepare "$slot" || { echo "ERROR: $slot does not configure" >&2; ok=0; }
        done
        if ! wait "$pid"; then
            chromium_emerge "$first" resume || { echo "ERROR: $first did not build" >&2; ok=0; }
        fi
        if (( ok )); then
            chromium_commit "$first" && changed_any=1 || ok=0
        fi
        if (( ok )); then
            for slot in "${todo[@]:1}"; do
                chromium_emerge "$slot" || { echo "ERROR: $slot did not build" >&2; ok=0; break; }
                chromium_commit "$slot" && changed_any=1 || { ok=0; break; }
            done
        fi
    fi
    if (( ! ok )); then
        info "$CHROMIUM has uncommitted slots; the next run resumes from what is installed"
        return 2
    fi
    (( changed_any )) && return 0
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
    head="$(git rev-parse HEAD)"
    prompt="Bump the $group group in this overlay to $new: ${pkgs[*]}. scripts/upstream-version.py found $new from the group's entry in scripts/upstream-sources; do not research the latest version again unless it looks wrong. These packages share one upstream release. Review upstream changes once for the whole group and update every ebuild. If the group has a -meta package, add any new member package to it and build the group through it with emerge --update --deep on the meta package, which is in @world; otherwise use a single emerge -1 of all the new versions so Portage orders them. If one fails, fix it and resume rather than restarting the group. Commit each package separately. $AGENT_RULES"
    run_agent "$group" "$prompt" || echo "ERROR: agent run for $group failed" >&2
    for pkg in "${pkgs[@]}"; do
        if ! package_clean "$pkg"; then
            echo "ERROR: agent left uncommitted changes in $pkg" >&2
            leave_package "$pkg"
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
[[ "$DRY_RUN" == 0 ]] && sudo -n find "$SCRATCH" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null
failed=()
inferred=()
declare -A GROUP_PKGS=() GROUP_VER=()

log "checking upstream versions"
VERSIONS="$RUN_DIR/versions.tsv"
timed - version-check scripts/upstream-version.py "${WORK[@]}" >"$VERSIONS" ||
    die "scripts/upstream-version.py failed"

# One ebuild per package, none live: a plain rename can bump it.
mechanical() {
    local pkg="$1" n
    in_list "$pkg" "${AI_PKGS[@]}" && return 1
    n=$(ls "$pkg"/*.ebuild 2>/dev/null | grep -vc -- '-9999')
    (( n == 1 ))
}

# Sort candidates into queues: quick mechanical bumps first so their commits
# land early, then agent work, then groups, and Chromium last.
SEP=$'\037'
Q_SIMPLE=(); Q_AGENT=(); Q_CHROMIUM=(); skipped=()
n_current=0
# A tab IFS would merge empty columns, so read with a non-whitespace separator.
while IFS=$'\037' read -r pkg status old new group batch source note <&3; do
    [[ "$note" == inferred* ]] && inferred+=("${note#*record as: }")
    case "$status" in
        live|skip) continue ;;
        current)   n_current=$((n_current + 1)); continue ;;
        older)     skipped+=("$pkg: upstream $new is older than local $old"); continue ;;
    esac
    row="$pkg$SEP$status$SEP$old$SEP$new$SEP$group$SEP$batch$SEP$source$SEP$note"
    if [[ "$pkg" == www-client/chromium ]]; then
        Q_CHROMIUM+=("$row"); continue
    fi
    if ! package_clean "$pkg"; then
        skipped+=("$pkg: uncommitted changes ($status${new:+ $old -> $new})"); continue
    fi
    if [[ "$status" == newer ]] && declined "$pkg" "$new"; then
        skipped+=("$pkg: $new declined by the agent recently (--retry to recheck)"); continue
    fi
    if [[ "$status" == newer && -n "$batch" ]]; then
        GROUP_PKGS[$group]+="$pkg "
        GROUP_VER[$group]="$new"
        continue
    fi
    if [[ "$status" == newer ]] && mechanical "$pkg"; then
        Q_SIMPLE+=("$row")
    else
        Q_AGENT+=("$row")
    fi
done 3< <(tr '\t' '\037' <"$VERSIONS")

n_group=0
for group in "${!GROUP_PKGS[@]}"; do n_group=$((n_group + 1)); done
TOTAL=$(( ${#Q_SIMPLE[@]} + ${#Q_AGENT[@]} + n_group + ${#Q_CHROMIUM[@]} ))
info "$n_current up to date; $TOTAL to process: ${#Q_SIMPLE[@]} mechanical, ${#Q_AGENT[@]} agent, $n_group group(s), ${#Q_CHROMIUM[@]} chromium"
if (( ${#skipped[@]} )); then
    info "skipped:"
    for line in "${skipped[@]}"; do info "  $line"; done
fi

results=()
IDX=0

# process_row ROW -- bump one package. Sets rc: 0 committed, 1 nothing to do, 2 failed.
process_row() {
    local pkg status old new group batch source note start=$EPOCHREALTIME
    IFS=$'\037' read -r pkg status old new group batch source note <<<"$1"
    IDX=$((IDX + 1))
    log "[$IDX/$TOTAL] $pkg: $status${new:+ $old -> $new}"
    CURRENT_PKG="$pkg"
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
            if mechanical "$pkg"; then
                local url; url="$(readiness_url "$pkg" "$new")"
                if [[ -n "$url" && "$(http_code "$url")" != 2* ]]; then
                    info "skip $pkg: $new artifact not available yet"
                    return 1
                fi
                bump_simple "$pkg" "$old" "$new"
            else
                bump_agent "$pkg" "$old" "$new" "" "$source"
            fi ;;
        *)
            info "unexpected status '$status' for $pkg"; return 1 ;;
    esac
    rc=$?
    CURRENT_PKG=""
    record "$pkg" total "$start" "$rc" "$status $old${new:+ -> $new}"
    case "$rc" in
        0) changed=1; results+=("$([[ "$DRY_RUN" == 1 ]] && echo would-bump || echo bumped)  $pkg ${new:+$old -> $new}"); push_commits ;;
        2) failed+=("$pkg"); results+=("FAILED  $pkg ${new:+$old -> $new}") ;;
        *) results+=("no-op   $pkg") ;;
    esac
    return "$rc"
}

for row in "${Q_SIMPLE[@]}" "${Q_AGENT[@]}"; do
    process_row "$row"
done

for group in "${!GROUP_PKGS[@]}"; do
    start=$EPOCHREALTIME
    read -r -a members <<<"${GROUP_PKGS[$group]}"
    IDX=$((IDX + 1))
    log "[$IDX/$TOTAL] $group -> ${GROUP_VER[$group]} (${#members[@]} packages)"
    before=$(git rev-parse HEAD)
    bump_group "$group" "${GROUP_VER[$group]}" "${members[@]}"
    record "$group" total "$start" 0 "${#members[@]} packages -> ${GROUP_VER[$group]}"
    [[ "$(git rev-parse HEAD)" != "$before" ]] && { results+=("bumped  $group -> ${GROUP_VER[$group]}"); push_commits; }
done

for row in "${Q_CHROMIUM[@]}"; do
    process_row "$row"
done

[[ "$changed" == 1 ]] && push_commits
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

if (( ${#results[@]} )); then
    log "results"
    for line in "${results[@]}"; do info "$line"; done
fi

if (( ${#UNFINISHED[@]} )); then
    log "left uncommitted in $PWD"
    for pkg in "${UNFINISHED[@]}"; do info "$pkg"; done
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
