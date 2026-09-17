# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: npm.eclass
# @MAINTAINER:
# Mike Lothian <fireburn@gentoo.org>
# @SUPPORTED_EAPIS: 8
# @BLURB: Offline npm registry for building Node.js packages from source
# @DESCRIPTION:
# Builds JavaScript packages from source without network access and without
# a separate dependency bundle.  Every registry package from the upstream
# lockfile is listed in NPM_PKGS, and this eclass turns the list into
# SRC_URI entries, so the Manifest fetches and verifies each tarball.
#
# During the build, a small registry on 127.0.0.1 serves those tarballs
# straight from DISTDIR.  Portage keeps loopback up inside network-sandbox,
# so npm, pnpm, bun and yarn install from their lockfiles unchanged, and
# install scripts and node-gyp run as usual with the user's toolchain flags.
#
# Generate NPM_PKGS with scripts/npm-deps.py from the overlay root.
#
# @EXAMPLE:
# @CODE
# NPM_PKGS="
# 	@types/node@22.19.19
# 	@esbuild/linux-x64@0.25.12|amd64
# 	@esbuild/linux-arm64@0.25.12|arm64
# 	typescript@5.9.3
# "
#
# inherit npm
#
# SRC_URI="https://example.org/${P}.tar.gz
# 	${NPM_PKG_URIS}"
#
# src_configure() {
# 	npm_with_registry npm ci
# }
# @CODE

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

if [[ -z ${_NPM_ECLASS} ]]; then
_NPM_ECLASS=1

inherit edo multiprocessing toolchain-funcs

# @ECLASS_VARIABLE: NPM_PKGS
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# Whitespace-separated registry packages as "name@version".  Scoped names
# keep their scope ("@scope/name@version").  A "|cond[,cond...]" suffix
# limits the package to the given USE conditions, which nest in order, e.g.
# "@rollup/rollup-linux-x64-gnu@4.52.5|amd64,elibc_glibc".  A condition may
# be negated with a leading "!".

# @ECLASS_VARIABLE: NPM_REGISTRY_URI
# @PRE_INHERIT
# @DESCRIPTION:
# Upstream registry the tarballs are fetched from.
: "${NPM_REGISTRY_URI:=https://registry.npmjs.org}"

# @ECLASS_VARIABLE: NPM_PNPM_VERSION
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# pnpm version to fetch as a distfile (pnpm ships as plain JavaScript).
# npm_setup_env then puts a "pnpm" command for it on PATH.

# @ECLASS_VARIABLE: NPM_PKG_URIS
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# SRC_URI fragment for NPM_PKGS.  Add it to SRC_URI.

# @ECLASS_VARIABLE: NPM_NODE_DEPEND
# @OUTPUT_VARIABLE
# @DESCRIPTION:
# Node.js build dependency.  Added to BDEPEND unless NPM_OPTIONAL is set.
NPM_NODE_DEPEND="net-libs/nodejs[npm]"

# @ECLASS_VARIABLE: NPM_OPTIONAL
# @PRE_INHERIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set, the eclass neither adds BDEPEND nor exports src_unpack.

# @FUNCTION: _npm_distfile
# @USAGE: <name> <version>
# @INTERNAL
# @DESCRIPTION:
# Distfile name for a package.  The ".npm.tgz" suffix keeps it apart from
# other tarballs in DISTDIR, and "+" stands in for the scope separator.
_npm_distfile() {
	local name=${1//\//+}
	echo "${name}-${2}.npm.tgz"
}

# @FUNCTION: _npm_split
# @USAGE: <entry>
# @INTERNAL
# @DESCRIPTION:
# Sets name, version and conds from an NPM_PKGS entry.
_npm_split() {
	local spec=${1%%|*}
	conds=
	[[ ${1} == *\|* ]] && conds=${1#*|}
	name=${spec%@*}
	version=${spec##*@}
	if [[ -z ${name} || -z ${version} || ${name} == "${spec}" ]]; then
		die "${ECLASS}: cannot parse NPM_PKGS entry: ${1}"
	fi
}

# @FUNCTION: _npm_set_pkg_uris
# @INTERNAL
# @DESCRIPTION:
# Generates NPM_PKG_URIS from NPM_PKGS.
_npm_set_pkg_uris() {
	local entry name version conds base cond open close file
	local -a cond_list
	NPM_PKG_URIS=
	for entry in ${NPM_PKGS}; do
		_npm_split "${entry}"
		base=${name##*/}
		file=${name//\//+}-${version}.npm.tgz
		open= close=
		if [[ -n ${conds} ]]; then
			local IFS=,
			cond_list=( ${conds} )
			unset IFS
			for cond in "${cond_list[@]}"; do
				open+="${cond}? ( "
				close+=" )"
			done
		fi
		NPM_PKG_URIS+="${open}${NPM_REGISTRY_URI}/${name}/-/${base}-${version}.tgz -> ${file}${close}
"
	done
	if [[ -n ${NPM_PNPM_VERSION} ]]; then
		NPM_PKG_URIS+="${NPM_REGISTRY_URI}/pnpm/-/pnpm-${NPM_PNPM_VERSION}.tgz -> pnpm-${NPM_PNPM_VERSION}.npm-tool.tgz
"
	fi
}
_npm_set_pkg_uris

if [[ -z ${NPM_OPTIONAL} ]]; then
	BDEPEND="${NPM_NODE_DEPEND}"
fi

# @FUNCTION: npm_setup_env
# @DESCRIPTION:
# Exports the environment for an offline, from-source build: a private
# HOME and caches, system Node headers for node-gyp, no downloads of
# prebuilt addons, browsers or Electron, no telemetry, and the toolchain
# from make.conf.  Safe to call more than once.
npm_setup_env() {
	debug-print-function ${FUNCNAME} "$@"

	export HOME="${T}/npm-home"
	mkdir -p "${HOME}" || die

	tc-export CC CXX AR RANLIB
	export CC_host=$(tc-getBUILD_CC) CXX_host=$(tc-getBUILD_CXX)

	# npm and node-gyp
	export npm_config_cache="${T}/npm-cache"
	export npm_config_nodedir="${BROOT}/usr"
	export npm_config_build_from_source=true
	export npm_config_audit=false
	export npm_config_fund=false
	export npm_config_update_notifier=false
	export npm_config_foreground_scripts=true
	export npm_config_progress=false
	export JOBS=$(makeopts_jobs)

	# pnpm, yarn and bun keep their own stores
	export XDG_CONFIG_HOME="${HOME}/.config"
	mkdir -p "${XDG_CONFIG_HOME}/pnpm" || die
	echo "store-dir=${T}/pnpm-store" > "${XDG_CONFIG_HOME}/pnpm/rc" || die
	export PNPM_HOME="${T}/pnpm-home"
	export YARN_CACHE_FOLDER="${T}/yarn-cache"
	export YARN_ENABLE_GLOBAL_CACHE=false
	export YARN_ENABLE_TELEMETRY=0
	export BUN_INSTALL_CACHE_DIR="${T}/bun-cache"
	export BUN_RUNTIME_TRANSPILER_CACHE_PATH=0
	export COREPACK_ENABLE_NETWORK=0
	export COREPACK_ENABLE_STRICT=0

	if [[ -n ${NPM_PNPM_VERSION} ]]; then
		local tooldir="${T}/npm-tools"
		if [[ ! -x ${tooldir}/bin/pnpm ]]; then
			mkdir -p "${tooldir}/pnpm" "${tooldir}/bin" || die
			tar -C "${tooldir}/pnpm" --strip-components=1 -xzf \
				"${DISTDIR}/pnpm-${NPM_PNPM_VERSION}.npm-tool.tgz" || die
			printf '#!/bin/sh\nexec node "%s" "$@"\n' "${tooldir}/pnpm/bin/pnpm.cjs" \
				> "${tooldir}/bin/pnpm" || die
			chmod +x "${tooldir}/bin/pnpm" || die
		fi
		[[ :${PATH}: == *:${tooldir}/bin:* ]] || export PATH="${tooldir}/bin:${PATH}"
		# The version pinned in packageManager is the one we provide
		export npm_config_manage_package_manager_versions=false
	fi

	# Things that would otherwise try the network or fetch binaries
	export CI=true
	export HUSKY=0
	export DO_NOT_TRACK=1
	export DISABLE_TELEMETRY=1
	export NEXT_TELEMETRY_DISABLED=1
	export ELECTRON_SKIP_BINARY_DOWNLOAD=1
	export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
	export PUPPETEER_SKIP_DOWNLOAD=1
	export CYPRESS_INSTALL_BINARY=0
	export SHARP_IGNORE_GLOBAL_LIBVIPS=1
	export SENTRYCLI_SKIP_DOWNLOAD=1
}

# @FUNCTION: npm_registry_start
# @DESCRIPTION:
# Starts the offline registry and points every package manager at it.
# Only packages whose distfiles are part of ${A} are served.  Pair with
# npm_registry_stop in the same phase.
npm_registry_start() {
	debug-print-function ${FUNCNAME} "$@"

	[[ -n ${_NPM_REGISTRY_PID} ]] && return
	npm_setup_env

	local dir="${T}/npm-registry"
	mkdir -p "${dir}" || die
	rm -f "${dir}"/{port,missing.log} || die

	local entry name version conds file
	local distdir=${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}
	: > "${dir}/index" || die
	for entry in ${NPM_PKGS}; do
		_npm_split "${entry}"
		file=$(_npm_distfile "${name}" "${version}")
		has "${file}" ${A} || continue
		printf '%s\t%s\t%s\n' "${name}" "${version}" "${distdir}/${file}" \
			>> "${dir}/index" || die
	done
	for file in "${_NPM_LOCAL_TARBALLS[@]}"; do
		printf '\t\t%s\n' "${file}" >> "${dir}/index" || die
	done

	_npm_write_registry "${dir}/registry.mjs"

	node "${dir}/registry.mjs" "${dir}" > "${dir}/registry.log" 2>&1 &
	_NPM_REGISTRY_PID=$!

	local i
	for (( i = 0; i < 300; i++ )); do
		[[ -s ${dir}/port ]] && break
		kill -0 "${_NPM_REGISTRY_PID}" 2>/dev/null || break
		sleep 0.1
	done
	if [[ ! -s ${dir}/port ]]; then
		cat "${dir}/registry.log" >&2
		die "${ECLASS}: offline registry failed to start"
	fi

	local url="http://127.0.0.1:$(<"${dir}/port")/"
	export NPM_REGISTRY_LOCAL=${url}
	export npm_config_registry=${url}
	export NPM_CONFIG_REGISTRY=${url}
	export BUN_CONFIG_REGISTRY=${url}
	export YARN_REGISTRY=${url}
	export YARN_NPM_REGISTRY_SERVER=${url%/}
	export YARN_UNSAFE_HTTP_WHITELIST=127.0.0.1
	einfo "Offline npm registry serving $(wc -l < "${dir}/index") packages at ${url}"
}

# @FUNCTION: npm_registry_add
# @USAGE: <tarball>...
# @DESCRIPTION:
# Publishes locally built package tarballs (e.g. from "npm pack") to the
# offline registry, next to NPM_PKGS.  Useful for installing workspace
# packages the way upstream publishes them.  Call before
# npm_registry_start.
npm_registry_add() {
	debug-print-function ${FUNCNAME} "$@"

	local file
	for file; do
		[[ -f ${file} ]] || die "${ECLASS}: ${file} not found"
		_NPM_LOCAL_TARBALLS+=( "$(realpath "${file}")" )
	done
}

# @FUNCTION: npm_registry_stop
# @DESCRIPTION:
# Stops the offline registry and lists any packages that were requested
# but are missing from NPM_PKGS.
npm_registry_stop() {
	debug-print-function ${FUNCNAME} "$@"

	[[ -n ${_NPM_REGISTRY_PID} ]] || return
	kill "${_NPM_REGISTRY_PID}" 2>/dev/null
	wait "${_NPM_REGISTRY_PID}" 2>/dev/null
	unset _NPM_REGISTRY_PID NPM_REGISTRY_LOCAL

	# Tarball misses break installs; packument misses are usually optional
	# or platform-specific packages that were never needed.
	local log="${T}/npm-registry/missing.log"
	if [[ -s ${log} ]]; then
		local kind what
		while IFS=$'\t' read -r kind what; do
			case ${kind} in
				tarball) ewarn "Offline registry: tarball not in NPM_PKGS: ${what}" ;;
				*) debug-print "${ECLASS}: packument not in NPM_PKGS: ${what}" ;;
			esac
		done < <(sort -u "${log}")
		einfo "Unresolved registry requests are listed in ${log}"
	fi
}

# @FUNCTION: npm_with_registry
# @USAGE: <command> [args...]
# @DESCRIPTION:
# Runs a command with the offline registry up, and dies if it fails.
npm_with_registry() {
	debug-print-function ${FUNCNAME} "$@"

	npm_registry_start
	edo "$@"
	local ret=$?
	npm_registry_stop
	[[ ${ret} -eq 0 ]] || die "${ECLASS}: ${1} failed"
}

# @FUNCTION: npm_remove_prebuilds
# @USAGE: [dir]
# @DESCRIPTION:
# Deletes prebuilt native addons (prebuildify "prebuilds" directories and
# node-gyp build output shipped in tarballs) below the given directory,
# node_modules by default, so they are rebuilt from source.
npm_remove_prebuilds() {
	debug-print-function ${FUNCNAME} "$@"

	local dir=${1:-node_modules}
	find -L "${dir}" -type d -name prebuilds -prune -exec rm -rf {} + || die
	local gyp
	while IFS= read -r -d '' gyp; do
		rm -rf "${gyp%/binding.gyp}/build" || die
	done < <(find -L "${dir}" -name binding.gyp -print0)
}

# @FUNCTION: npm_rebuild_native
# @USAGE: [dir]
# @DESCRIPTION:
# Rebuilds every node-gyp addon below the given directory (node_modules by
# default) with the system Node headers and the user's toolchain flags.
npm_rebuild_native() {
	debug-print-function ${FUNCNAME} "$@"

	npm_setup_env
	local dir=${1:-node_modules} gyp pkg
	local node_gyp="${BROOT}/usr/$(get_libdir)/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js"
	[[ -f ${node_gyp} ]] || node_gyp="${BROOT}/usr/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js"
	[[ -f ${node_gyp} ]] || die "${ECLASS}: node-gyp not found"

	while IFS= read -r -d '' gyp; do
		pkg=${gyp%/binding.gyp}
		einfo "Building native addon ${pkg}"
		pushd "${pkg}" >/dev/null || die
		node "${node_gyp}" rebuild --jobs="$(makeopts_jobs)" ||
			die "${ECLASS}: node-gyp failed for ${pkg}"
		popd >/dev/null || die
	done < <(find -L "${dir}" -name binding.gyp -not -path '*/test/*' -print0)
}

# @FUNCTION: npm_src_unpack
# @DESCRIPTION:
# Unpacks everything except npm tarballs, which the registry serves from
# DISTDIR.
npm_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"

	local archive
	for archive in ${A}; do
		[[ ${archive} == *.npm.tgz || ${archive} == *.npm-tool.tgz ]] || unpack "${archive}"
	done
	npm_setup_env
}

# @FUNCTION: _npm_write_registry
# @USAGE: <path>
# @INTERNAL
# @DESCRIPTION:
# Writes the registry server.  It reads "name<TAB>version<TAB>path" lines
# from <dir>/index and answers packument and tarball requests, reading
# package.json from each tarball on first use.
_npm_write_registry() {
	cat > "${1}" <<-'EOF' || die
	import { createServer } from "node:http";
	import { createHash } from "node:crypto";
	import { appendFileSync, readFileSync, writeFileSync } from "node:fs";
	import { gunzipSync } from "node:zlib";

	const dir = process.argv[2];
	const pkgs = new Map();
	for (const line of readFileSync(`${dir}/index`, "utf8").split("\n")) {
		if (!line) continue;
		let [name, version, path] = line.split("\t");
		const entry = { path };
		if (!name) {
			// Local tarball: name and version come from its package.json
			({ name, version } = load(entry).manifest);
		}
		if (!pkgs.has(name)) pkgs.set(name, new Map());
		pkgs.get(name).set(version, entry);
	}

	function manifest(tgz) {
		const tar = gunzipSync(tgz);
		let paxPath;
		for (let off = 0; off + 512 <= tar.length; ) {
			const hdr = tar.subarray(off, off + 512);
			if (hdr.every(b => b === 0)) break;
			const str = (a, b) => hdr.subarray(a, b).toString("utf8").replace(/\0.*$/s, "");
			const size = parseInt(str(124, 136).trim() || "0", 8);
			const type = str(156, 157);
			const data = tar.subarray(off + 512, off + 512 + size);
			let path = paxPath ?? (str(345, 500) ? `${str(345, 500)}/${str(0, 100)}` : str(0, 100));
			paxPath = undefined;
			if (type === "x") {
				const m = /\d+ path=([^\n]*)\n/.exec(data.toString("utf8"));
				if (m) paxPath = m[1];
			} else if (/^[^/]+\/package\.json$/.test(path)) {
				return JSON.parse(data.toString("utf8"));
			}
			off += 512 + Math.ceil(size / 512) * 512;
		}
		throw new Error("no package.json");
	}

	function load(entry) {
		if (!entry.data) {
			const data = readFileSync(entry.path);
			entry.data = data;
			entry.integrity = "sha512-" + createHash("sha512").update(data).digest("base64");
			entry.shasum = createHash("sha1").update(data).digest("hex");
			try { entry.manifest = manifest(data); } catch { entry.manifest = {}; }
		}
		return entry;
	}

	function semverGt(a, b) {
		const pa = a.split(/[.+]/).map(Number), pb = b.split(/[.+]/).map(Number);
		for (let i = 0; i < 3; i++) if (pa[i] !== pb[i]) return pa[i] > pb[i];
		return false;
	}

	function missing(what) {
		appendFileSync(`${dir}/missing.log`, what + "\n");
	}

	const server = createServer((req, res) => {
		const base = `http://${req.headers.host}/`;
		const path = decodeURIComponent(new URL(req.url, base).pathname).replace(/^\/+/, "");
		const tgz = path.indexOf("/-/");
		const send = (code, body, type) => {
			res.writeHead(code, { "content-type": type });
			res.end(body);
		};
		if (tgz !== -1) {
			const name = path.slice(0, tgz);
			const file = path.slice(tgz + 3);
			const prefix = `${name.split("/").pop()}-`;
			const version = file.startsWith(prefix) ? file.slice(prefix.length).replace(/\.tgz$/, "") : "";
			const entry = pkgs.get(name)?.get(version);
			if (!entry) { missing(`tarball\t${name}@${version || file}`); return send(404, "{}", "application/json"); }
			return send(200, load(entry).data, "application/octet-stream");
		}
		const versions = pkgs.get(path);
		if (!versions) { missing(`packument\t${path}`); return send(404, "{}", "application/json"); }
		// Fixed old publish times keep min-release-age style policies happy
		const epoch = "2000-01-01T00:00:00.000Z";
		const out = { name: path, versions: {}, "dist-tags": {}, time: { created: epoch, modified: epoch } };
		let latest;
		for (const [version, entry] of versions) {
			load(entry);
			out.time[version] = epoch;
			out.versions[version] = {
				...entry.manifest, name: path, version,
				dist: {
					tarball: `${base}${path}/-/${path.split("/").pop()}-${version}.tgz`,
					integrity: entry.integrity, shasum: entry.shasum,
				},
			};
			if (!/-/.test(version) && (!latest || semverGt(version, latest))) latest = version;
		}
		out["dist-tags"].latest = latest ?? [...versions.keys()].pop();
		send(200, JSON.stringify(out), "application/json");
	});

	server.listen(0, "127.0.0.1", () => {
		writeFileSync(`${dir}/port`, String(server.address().port));
	});
	EOF
}

fi

if [[ -z ${NPM_OPTIONAL} ]]; then
	EXPORT_FUNCTIONS src_unpack
fi
