# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Generated from package-lock.json by scripts/npm-deps.py
NPM_PKGS="
	@anthropic-ai/sandbox-runtime@0.0.26
	@anthropic-ai/sdk@0.124.0
	@anthropic-ai/sdk@0.52.0
	@anthropic-ai/sdk@0.91.1
	@aws-sdk/client-bedrock-runtime@3.1127.0
	@aws-sdk/core@3.977.9
	@aws-sdk/credential-provider-env@3.972.70
	@aws-sdk/credential-provider-http@3.972.72
	@aws-sdk/credential-provider-ini@3.973.15
	@aws-sdk/credential-provider-login@3.972.77
	@aws-sdk/credential-provider-node@3.972.82
	@aws-sdk/credential-provider-process@3.972.70
	@aws-sdk/credential-provider-sso@3.973.14
	@aws-sdk/credential-provider-web-identity@3.972.76
	@aws-sdk/eventstream-handler-node@3.972.34
	@aws-sdk/middleware-eventstream@3.972.29
	@aws-sdk/middleware-websocket@3.972.52
	@aws-sdk/nested-clients@3.997.44
	@aws-sdk/signature-v4-multi-region@3.996.46
	@aws-sdk/token-providers@3.1116.0
	@aws-sdk/token-providers@3.1127.0
	@aws-sdk/types@3.974.5
	@aws-sdk/xml-builder@3.972.40
	@aws/lambda-invoke-store@0.3.0
	@babel/helper-string-parser@7.29.7
	@babel/helper-validator-identifier@7.29.7
	@babel/parser@7.29.8
	@babel/runtime@7.29.2
	@babel/types@7.29.8
	@bcoe/v8-coverage@1.0.2
	@biomejs/biome@2.3.5
	@biomejs/cli-linux-arm64@2.3.5|arm64
	@biomejs/cli-linux-arm64-musl@2.3.5|arm64
	@biomejs/cli-linux-x64@2.3.5|amd64
	@biomejs/cli-linux-x64-musl@2.3.5|amd64
	@cto.af/wtf8@0.0.5
	@earendil-works/gondolin@0.12.0
	@earendil-works/gondolin-krun-runner-linux-x64@0.12.0|amd64
	@esbuild/linux-arm64@0.28.2|arm64
	@esbuild/linux-x64@0.28.2|amd64
	@google/genai@2.21.0
	@jridgewell/resolve-uri@3.1.2
	@jridgewell/sourcemap-codec@1.5.5
	@jridgewell/trace-mapping@0.3.31
	@napi-rs/wasm-runtime@1.1.5
	@nodelib/fs.scandir@2.1.5
	@nodelib/fs.stat@2.0.5
	@nodelib/fs.walk@1.2.8
	@oxc-project/types@0.133.0
	@pondwader/socks5-server@1.0.10
	@protobufjs/aspromise@1.1.2
	@protobufjs/base64@1.1.2
	@protobufjs/codegen@2.0.5
	@protobufjs/eventemitter@1.1.1
	@protobufjs/fetch@1.1.1
	@protobufjs/float@1.0.2
	@protobufjs/path@1.1.2
	@protobufjs/pool@1.1.0
	@protobufjs/utf8@1.1.1
	@rolldown/binding-linux-arm64-gnu@1.0.3|arm64
	@rolldown/binding-linux-arm64-musl@1.0.3|arm64
	@rolldown/binding-linux-x64-gnu@1.0.3|amd64
	@rolldown/binding-linux-x64-musl@1.0.3|amd64
	@rolldown/pluginutils@1.0.1
	@silvia-odwyer/photon-node@0.3.4
	@smithy/core@3.33.3
	@smithy/credential-provider-imds@4.5.2
	@smithy/fetch-http-handler@5.8.0
	@smithy/node-http-handler@4.12.1
	@smithy/signature-v4@5.7.3
	@smithy/types@4.18.0
	@stablelib/base64@1.0.1
	@standard-schema/spec@1.1.0
	@tybys/wasm-util@0.10.2
	@types/chai@5.2.3
	@types/cross-spawn@6.0.6
	@types/deep-eql@4.0.2
	@types/estree@1.0.9
	@types/hosted-git-info@3.0.5
	@types/lodash@4.17.24
	@types/lodash-es@4.17.12
	@types/ms@2.1.0
	@types/node@22.19.19
	@types/proper-lockfile@4.1.4
	@types/retry@0.12.0
	@types/retry@0.12.5
	@types/semver@7.7.1
	@typescript/native-preview@7.0.0-dev.20260120.1
	@typescript/native-preview-linux-arm64@7.0.0-dev.20260120.1|arm64
	@typescript/native-preview-linux-x64@7.0.0-dev.20260120.1|amd64
	@vitest-evals/core@0.15.0
	@vitest-evals/report-ui@0.15.0
	@vitest/coverage-v8@4.1.9
	@vitest/expect@4.1.9
	@vitest/mocker@4.1.9
	@vitest/pretty-format@4.1.9
	@vitest/runner@4.1.9
	@vitest/snapshot@4.1.9
	@vitest/spy@4.1.9
	@vitest/utils@4.1.9
	@xterm/headless@5.5.0
	agent-base@7.1.4
	agent-base@9.0.0
	ajv@8.20.0
	argparse@2.0.1
	asn1@0.2.6
	assertion-error@2.0.1
	ast-v8-to-istanbul@1.0.5
	autoevals@0.3.0
	balanced-match@4.0.4
	base64-js@1.5.1
	bcrypt-pbkdf@1.0.2
	bignumber.js@9.3.1
	binary-search@1.3.6
	bl@4.1.0
	bowser@2.14.1
	brace-expansion@5.0.9
	braces@3.0.3
	buffer@5.7.1
	buffer-equal-constant-time@1.0.1
	buildcheck@0.0.7
	canvas@3.2.3
	cbor2@2.3.0
	chai@6.2.2
	chalk@6.0.0
	cheminfo-types@1.16.0
	chownr@1.1.4
	commander@12.1.0
	compute-cosine-similarity@1.1.0
	compute-dot@1.1.0
	compute-l2norm@1.1.0
	convert-source-map@2.0.0
	cpu-features@0.0.10
	cross-spawn@6.0.6
	cross-spawn@7.0.6
	data-uri-to-buffer@4.0.1
	debug@4.4.3
	decompress-response@6.0.0
	deep-extend@0.6.0
	detect-libc@2.1.2
	diff@8.0.4
	ecdsa-sig-formatter@1.0.11
	end-of-stream@1.4.5
	es-errors@1.3.0
	es-module-lexer@2.3.1
	esbuild@0.28.2
	estree-walker@3.0.3
	execa@1.0.0
	expand-template@2.0.3
	expect-type@1.3.0
	extend@3.0.2
	fast-deep-equal@3.1.3
	fast-glob@3.3.3
	fast-sha256@1.3.0
	fast-uri@3.1.8
	fastq@1.20.1
	fdir@6.5.0
	fetch-blob@3.2.0
	fft.js@4.0.4
	fill-range@7.1.1
	formdata-polyfill@4.0.10
	fs-constants@1.0.0
	function-bind@1.1.2
	gaxios@7.1.4
	gcp-metadata@8.1.2
	get-east-asian-width@1.6.0
	get-stream@4.1.0
	github-from-package@0.0.0
	glob-parent@5.1.2
	google-auth-library@10.6.2
	google-logging-utils@1.1.3
	graceful-fs@4.2.11
	grok-mermaid@0.2.3
	has-flag@4.0.0
	hasown@2.0.3
	highlight.js@10.7.3
	hosted-git-info@9.0.3
	html-escaper@2.0.2
	http-proxy-agent@9.1.0
	https-proxy-agent@7.0.6
	https-proxy-agent@9.1.0
	husky@9.1.7
	ieee754@1.2.1
	ignore@7.0.8
	inherits@2.0.4
	ini@1.3.8
	interpret@1.4.0
	is-any-array@3.0.0
	is-core-module@2.16.2
	is-extglob@2.1.1
	is-glob@4.0.3
	is-number@7.0.0
	is-stream@1.1.0
	isexe@2.0.0
	istanbul-lib-coverage@3.2.2
	istanbul-lib-report@3.0.1
	istanbul-reports@3.2.0
	jiti@2.7.0
	js-levenshtein@1.1.6
	js-tokens@10.0.0
	js-yaml@4.3.2
	json-bigint@1.0.0
	json-schema-to-ts@3.1.1
	json-schema-traverse@1.0.0
	jwa@2.0.1
	jws@4.0.1
	lightningcss@1.32.0
	lightningcss-linux-arm64-gnu@1.32.0|arm64
	lightningcss-linux-arm64-musl@1.32.0|arm64
	lightningcss-linux-x64-gnu@1.32.0|amd64
	lightningcss-linux-x64-musl@1.32.0|amd64
	linear-sum-assignment@1.0.9
	lodash-es@4.18.1
	long@5.3.2
	lru-cache@11.4.0
	magic-string@0.30.21
	magicast@0.5.4
	make-dir@4.0.0
	marked@18.0.11
	merge2@1.4.1
	micromatch@4.0.8
	mimic-response@3.1.0
	minimatch@10.2.6
	minimist@1.2.8
	mkdirp-classic@0.5.3
	ml-array-max@2.0.0
	ml-array-min@2.0.0
	ml-array-rescale@2.0.0
	ml-matrix@6.15.0
	ml-spectra-processing@14.35.1
	ml-xsadd@3.0.1
	ms@2.1.3
	mustache@4.2.0
	nan@2.27.0
	nanoid@3.3.18
	napi-build-utils@2.0.0
	nice-try@1.0.5
	node-abi@3.92.0
	node-addon-api@7.1.1
	node-domexception@1.0.0
	node-fetch@3.3.2
	node-forge@1.4.0
	npm-run-path@2.0.2
	obug@2.1.3
	once@1.4.0
	openai@6.40.0
	p-finally@1.0.0
	p-retry@4.6.2
	partial-json@0.1.7
	path-key@2.0.1
	path-key@3.1.1
	path-parse@1.0.7
	pathe@2.0.3
	picocolors@1.1.1
	picomatch@2.3.2
	picomatch@4.0.4
	picomatch@4.0.5
	postcss@8.5.24
	prebuild-install@7.1.3
	proper-lockfile@4.1.2
	protobufjs@7.6.6
	proxy-agent-negotiate@1.1.0
	pump@3.0.4
	queue-microtask@1.2.3
	rc@1.2.8
	readable-stream@3.6.2
	rechoir@0.6.2
	require-from-string@2.0.2
	resolve@1.22.12
	retry@0.12.0
	retry@0.13.1
	reusify@1.1.0
	rolldown@1.0.3
	run-parallel@1.2.0
	safe-buffer@5.2.1
	safer-buffer@2.1.2
	semver@5.7.2
	semver@7.8.5
	shebang-command@1.2.0
	shebang-command@2.0.0
	shebang-regex@1.0.0
	shebang-regex@3.0.0
	shell-quote@1.10.0
	shelljs@0.9.2
	shx@0.4.0
	siginfo@2.0.0
	signal-exit@3.0.7
	simple-concat@1.0.1
	simple-get@4.0.1
	source-map-js@1.2.1
	ssh2@1.17.0
	stackback@0.0.2
	standardwebhooks@1.1.1
	std-env@4.2.0
	string_decoder@1.3.0
	strip-eof@1.0.0
	strip-json-comments@2.0.1
	supports-color@7.2.0
	supports-preserve-symlinks-flag@1.0.0
	tar-fs@2.1.4
	tar-stream@2.2.0
	tinybench@2.9.0
	tinyexec@1.2.4
	tinyglobby@0.2.17
	tinyrainbow@3.1.0
	to-regex-range@5.0.1
	ts-algebra@2.0.0
	tslib@2.8.1
	tsx@4.22.1
	tunnel-agent@0.6.0
	tweetnacl@0.14.5
	typebox@1.1.38
	typebox@1.3.27
	typescript@5.9.3
	undici@6.28.0
	undici@8.10.2
	undici-types@6.21.0
	util-deprecate@1.0.2
	validate.io-array@1.0.6
	validate.io-function@1.0.2
	vite@8.0.16
	vitest@4.1.9
	vitest-evals@0.15.0
	web-streams-polyfill@3.3.3
	which@1.3.1
	which@2.0.2
	why-is-node-running@2.3.0
	wrappy@1.0.2
	ws@8.21.0
	yaml@2.9.0
	zod@3.25.76
	zod-to-json-schema@3.25.0
"

inherit edo npm optfeature

DESCRIPTION="AI agent toolkit and interactive coding agent CLI"
HOMEPAGE="https://pi.dev https://github.com/earendil-works/pi"
SRC_URI="
	https://github.com/earendil-works/pi/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz
	https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${PV}.tgz -> ${P}-model-data.tgz
	${NPM_PKG_URIS}
"

LICENSE="MIT"
# Dependent npm package licenses
LICENSE+="
	0BSD Apache-2.0 BlueOak-1.0.0 BSD BSD-2 ISC MIT MPL-2.0 Unlicense
	|| ( MIT WTFPL-2 ) || ( BSD GPL-2 )
"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror"

# pi's bundled esbuild API refuses a binary of any other version
ESBUILD_SLOT="0.28.2"

RDEPEND="
	>=net-libs/nodejs-22.19.0
	dev-util/esbuild:${ESBUILD_SLOT}
	dev-vcs/git
	sys-apps/fd
	sys-apps/ripgrep
"
BDEPEND="
	${NPM_NODE_DEPEND}
	dev-util/esbuild:${ESBUILD_SLOT}
"

# Workspace packages published alongside the CLI
PI_WORKSPACES=( chord tui telemetry ai agent coding-agent )

src_prepare() {
	default

	# The model catalogue is generated from provider APIs before publishing
	# and is not in git. Take it from the published pi-ai package.
	mkdir -p packages/ai/src/providers || die
	cp -r "${WORKDIR}"/package/dist/providers/data packages/ai/src/providers/ || die
}

src_configure() {
	export ESBUILD_BINARY_PATH="${BROOT}/usr/bin/esbuild-${ESBUILD_SLOT}"
	npm_with_registry npm ci
}

src_compile() {
	# build:offline uses the model data in the source tree instead of
	# fetching it
	edo npm run build:offline
	edo node scripts/generate-coding-agent-shrinkwrap.mjs

	local ws
	mkdir -p "${T}/packs" || die
	for ws in "${PI_WORKSPACES[@]}"; do
		edo npm pack --ignore-scripts --pack-destination "${T}/packs" \
			--workspace "packages/${ws}"
	done
}

src_install() {
	# Install the way upstream publishes it, resolving dependencies from
	# the offline registry. Optional dependencies are prebuilt esbuild and
	# clipboard binaries: esbuild comes from dev-util/esbuild instead, and
	# clipboard access falls back to wl-paste or xclip.
	npm_registry_add "${T}"/packs/*.tgz
	npm_with_registry npm install --global --prefix "${ED}/usr" \
		--omit=dev --omit=optional --install-links \
		"@earendil-works/pi-coding-agent@${PV}"

	local moddir
	moddir=$(find "${ED}"/usr/lib* -maxdepth 1 -name node_modules -print -quit) || die
	[[ -n ${moddir} ]] || die "npm global install produced no node_modules"
	moddir=${moddir#"${ED}"}

	# The shrinkwrap pulls esbuild in regardless of --omit=optional
	rm -r "${ED}${moddir}"/@earendil-works/pi-coding-agent/node_modules/@esbuild || die
	rm -rf "${ED}${moddir}"/@earendil-works/pi-coding-agent/node_modules/@mariozechner/clipboard-*

	rm "${ED}/usr/bin/pi" || die
	newbin - pi <<-EOT
	#!/bin/sh
	export ESBUILD_BINARY_PATH="\${ESBUILD_BINARY_PATH:-${EPREFIX}/usr/bin/esbuild-${ESBUILD_SLOT}}"
	export PI_SKIP_VERSION_CHECK=1
	exec node "${EPREFIX}${moddir}/@earendil-works/pi-coding-agent/dist/bundle/cli.js" "\$@"
	EOT

	dodoc README.md
}

pkg_postinst() {
	optfeature_header "Optional clipboard image support:"
	optfeature "Wayland" gui-apps/wl-clipboard
	optfeature "X11" x11-misc/xclip
}
