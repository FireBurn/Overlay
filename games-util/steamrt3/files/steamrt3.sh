#!/bin/bash
# Installs and starts Valve's 64-bit SteamRT3 client. The first run fetches
# the client from Valve's update servers without the 32-bit bootstrapper,
# which the SteamRT3 client does not need and this system cannot run.

set -euo pipefail

CDN=https://client-update.steamstatic.com
BETA=${STEAMRT3_BETA:-publicbeta}
STEAMROOT=${STEAMRT3_ROOT:-${XDG_DATA_HOME:-${HOME}/.local/share}/Steam}
LIBDIR=@LIBDIR@

die() {
	echo "steamrt3: $*" >&2
	exit 1
}

# Prints "name file sha256" for each package in a client manifest.
manifest_packages() {
	awk '
		/^\t"[^"]+"$/ { gsub(/[\t"]/, ""); name = $0; file = sha = ""; next }
		/^\t\t"file"/ { gsub(/"/, "", $2); file = $2 }
		/^\t\t"sha2"/ { gsub(/"/, "", $2); sha = $2 }
		/^\t}$/ && name != "" { print name, file, sha; name = "" }
	' "$1"
}

# Valve's packages carry no Unix permissions, and some write their paths with
# backslashes. Programs and scripts are made executable by what they start
# with.
unpack() {
	@PYTHON@ - "$1" "${STEAMROOT}" <<'PY'
import os, sys, zipfile
archive, root = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(archive) as z:
    for info in z.infolist():
        path = os.path.join(root, info.filename.replace("\\", "/"))
        if info.filename.endswith(("/", "\\")):
            os.makedirs(path, exist_ok=True)
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        data = z.read(info)
        tmp = path + ".steamrt3-tmp"
        with open(tmp, "wb") as f:
            f.write(data)
        os.chmod(tmp, 0o755 if data[:4] == b"\x7fELF" or data[:2] == b"#!" else 0o644)
        os.replace(tmp, path)
PY
}

install_client() {
	local manifest=${STEAMROOT}/package/steam_client_${BETA}_ubuntu12.manifest
	local name file sha

	mkdir -p "${STEAMROOT}/package"
	curl -fsSL -o "${manifest}" "${CDN}/steam_client_${BETA}_ubuntu12" ||
		die "cannot fetch the ${BETA} client manifest"

	while read -r name file sha; do
		# The SteamRT3 client and what every platform shares, and nothing
		# for the 32-bit client.
		case ${name} in
			*_all|*_steamrt_ubuntu12) ;;
			*) continue ;;
		esac
		echo "steamrt3: fetching ${name}" >&2
		curl -fsSL -o "${STEAMROOT}/package/${file}" "${CDN}/${file}" ||
			die "cannot fetch ${file}"
		echo "${sha}  ${STEAMROOT}/package/${file}" | sha256sum -c --quiet - ||
			die "${file} does not match the manifest"
		unpack "${STEAMROOT}/package/${file}" || die "cannot unpack ${file}"
		rm -f "${STEAMROOT}/package/${file}"
	done < <(manifest_packages "${manifest}")

	[[ -x ${STEAMROOT}/steamrt64/steam ]] || die "the manifest had no SteamRT3 client"
}

[[ -x ${STEAMROOT}/steamrt64/steam ]] || install_client

# steam.sh only takes the SteamRT3 path for a beta with this marker.
echo "${BETA}" > "${STEAMROOT}/package/beta"
touch "${STEAMROOT}/.steam-enable-steamrt64-client"
install -m 755 "${LIBDIR}/steam.sh" "${STEAMROOT}/steam.sh"

# The client finds its installation through these, and would otherwise make
# them from the 32-bit path it no longer takes.
mkdir -p "${HOME}/.steam"
ln -sfn "${STEAMROOT}" "${HOME}/.steam/root"
ln -sfn "${STEAMROOT}" "${HOME}/.steam/steam"
ln -sfn "${STEAMROOT}/steamrt64" "${HOME}/.steam/sdk64"

# Valve's reaper, which starts games, is still 32-bit.
install -m 755 "${LIBDIR}/reaper" "${STEAMROOT}/steamrt64/reaper"

# The client may bring these back when it updates. Nothing here runs them.
rm -rf "${STEAMROOT}/steamrt32" "${STEAMROOT}/ubuntu12_32" "${STEAMROOT}/linux32"

# The container brings its own glibc but takes graphics drivers from the host,
# and this host's are built for a different libc. The glibc island has a Mesa
# the container can load instead.
if [[ -z ${PRESSURE_VESSEL_GRAPHICS_PROVIDER+set} && -d /opt/steamrt3-glibc ]]; then
	export PRESSURE_VESSEL_GRAPHICS_PROVIDER=/opt/steamrt3-glibc
fi

exec "${STEAMROOT}/steam.sh" "$@"
