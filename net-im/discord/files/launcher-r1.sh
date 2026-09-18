#!/usr/bin/env bash
# coding: UTF-8


declare -a discord_parameters

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
