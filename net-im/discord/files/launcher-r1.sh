#!/usr/bin/env bash
# coding: UTF-8


declare -a discord_parameters

# Discord has no --version mode that exits; it prints the version at
# startup and keeps running. Answer it from the installed build info.
if [[ "${1:-}" == "--version" ]]; then
	echo "Discord $(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "@@DESTDIR@@/resources/build_info.json" | head -n 1)"
	exit 0
fi

# Variables set during ebuild configuration
EBUILD_SECCOMP=false
EBUILD_WAYLAND=false

"${EBUILD_SECCOMP}" || discord_parameters+=( --disable-seccomp-filter-sandbox )

"${EBUILD_WAYLAND}" && \
[[ -n "${WAYLAND_DISPLAY}" ]] && discord_parameters+=(
	--enable-features=UseOzonePlatform
	--ozone-platform=wayland
	--enable-wayland-ime
)


# Read by the app.asar shipped with the system Electron, in place of
# process.resourcesPath, which points at Electron's own installation
export DISCORD_R=@@DESTDIR@@/resources

# The system Electron binary is named "electron", which makes Electron print
# its development security warnings even for a production app
export ELECTRON_DISABLE_SECURITY_WARNINGS=1

# https://bugs.gentoo.org/905289
@@DESTDIR@@/disable-breaking-updates.py

@@EXEC@@ "${discord_parameters[@]}" "$@"
