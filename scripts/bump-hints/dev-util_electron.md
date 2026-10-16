# dev-util/electron

Electron pins an exact Chromium in `DEPS` (`chromium_version`), but Google almost never publishes a source tarball for that version. Pointing `CHROMIUM_VER` at the pin makes the fetch 404. Use the newest published tarball instead.

1. If a newer Electron release than the one being bumped exists, bump to that and skip the older one.
2. Read `chromium_version` from `DEPS` at the new tag (`gh api repos/electron/electron/contents/DEPS?ref=v<ver>`). Call it the pin.
3. Find the newest published tarball whose version is at or below the pin, within the same `major.minor.build` line:
   `curl -sI https://commondatastorage.googleapis.com/chromium-browser-official/chromium-<v>-lite.tar.xz` returns 200 when it exists. Probe the patch number downwards from the pin. Set `CHROMIUM_VER` to that and not to the pin. If none exists in the line, stop and report it.
4. `git mv` the ebuild to the new version and set `CHROMIUM_VER`.
5. `sudo -n ebuild <ebuild> manifest`, then `sudo ebuild <ebuild> clean unpack prepare` first. A patch that fails to apply here is the usual problem and costs minutes. Fix it before the full build.
   Also read `node_version` in `DEPS` and set `ELECTRON_NODE_VER`; it moves between point releases.
   Patches against test files that no longer match are skipped by the ebuild. If a patch for a source file still fails, check whether it is for code newer than the tarball and Windows or macOS only. If so add it to `ELECTRON_SKIP_PATCHES` with the reason, otherwise report it.
6. `emerge -1 =dev-util/electron-<ver>` detached. It takes hours and needs a free ram disk, with nothing else heavy running.
7. Smoke test: `electron --version`.

If the build fails in electron/ sources against a Chromium API that the older tarball lacks, add a small compatibility patch under files/ named for the electron and Chromium versions, and drop it when a tarball at or above the pin is published.
