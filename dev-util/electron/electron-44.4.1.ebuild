# Copyright 2009-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Electron is Chromium plus Node.js plus Electron's own shell and patches.
# This ebuild follows www-client/chromium for the system toolchain and
# unbundling, then layers Electron on top the way its DEPS file would:
#   src/                         Chromium ${CHROMIUM_VER}
#   src/electron                 Electron ${PV}
#   src/third_party/electron_node Node.js ${ELECTRON_NODE_VER}
#   src/third_party/nan          nan ${ELECTRON_NAN_COMMIT}
# Versions come from electron's DEPS file. NPM_PKGS comes from its yarn.lock:
#   scripts/npm-deps.py electron/yarn.lock --ebuild <this ebuild>

CHROMIUM_VER="152.0.7977.78"
ELECTRON_NODE_VER="24.21.0"
ELECTRON_NAN_COMMIT="675cefebca42410733da8a454c8d9391fcebfbc2"

GN_MIN_VER=0.2374
ESBUILD_VER="0.25.1"
ROLLUP_VER="4.57.1"
COPIUM_COMMIT="b00f26bb5e0781020da5f830981472a142c6baf1"

CHROMIUM_LANGS="af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk ur vi zh-CN zh-TW"

NPM_PKGS="
	@actions/cache@4.1.0
	@actions/core@1.11.1
	@actions/exec@1.1.1
	@actions/glob@0.1.2
	@actions/http-client@2.2.3
	@actions/io@1.1.3
	@azure/abort-controller@1.0.4
	@azure/abort-controller@1.1.0
	@azure/abort-controller@2.1.2
	@azure/core-auth@1.10.0
	@azure/core-auth@1.10.1
	@azure/core-client@1.10.0
	@azure/core-http-compat@2.3.0
	@azure/core-lro@2.2.4
	@azure/core-paging@1.6.2
	@azure/core-rest-pipeline@1.22.0
	@azure/core-tracing@1.0.0-preview.13
	@azure/core-tracing@1.3.0
	@azure/core-util@1.13.0
	@azure/core-util@1.13.1
	@azure/core-xml@1.5.0
	@azure/logger@1.3.0
	@azure/ms-rest-js@2.7.0
	@azure/storage-blob@12.28.0
	@azure/storage-blob@12.29.1
	@azure/storage-common@12.0.0
	@azure/storage-common@12.1.1
	@datadog/datadog-ci@5.17.0
	@discoveryjs/json-ext@0.6.3
	@dsanders11/vscode-markdown-languageservice@0.3.0
	@electron/asar@3.2.13
	@electron/asar@3.4.1
	@electron/asar@4.0.1
	@electron/docs-parser@3.0.1
	@electron/fiddle-core@1.3.4
	@electron/fiddle-core@2.0.1
	@electron/fuses@2.1.2
	@electron/get@2.0.2
	@electron/get@3.1.0
	@electron/get@4.0.2
	@electron/github-app-auth@3.2.0
	@electron/lint-roller@3.2.0
	@electron/notarize@2.5.0
	@electron/osx-sign@1.3.3
	@electron/packager@18.4.4
	@electron/typescript-definitions@9.2.0
	@electron/universal@2.0.3
	@electron/windows-sign@1.2.2
	@eslint-community/eslint-utils@4.4.0
	@eslint-community/regexpp@4.11.1
	@eslint/eslintrc@2.1.4
	@eslint/js@8.57.1
	@fastify/busboy@2.1.1
	@humanwhocodes/config-array@0.13.0
	@humanwhocodes/module-importer@1.0.1
	@humanwhocodes/object-schema@2.0.3
	@hurdlegroup/robotjs@0.12.3
	@isaacs/cliui@8.0.2
	@isaacs/fs-minipass@4.0.1
	@jridgewell/gen-mapping@0.3.5
	@jridgewell/resolve-uri@3.1.2
	@jridgewell/set-array@1.2.1
	@jridgewell/source-map@0.3.6
	@jridgewell/sourcemap-codec@1.4.14
	@jridgewell/sourcemap-codec@1.5.0
	@jridgewell/trace-mapping@0.3.25
	@keyv/serialize@1.1.1
	@kwsites/file-exists@1.1.1
	@kwsites/promise-deferred@1.1.1
	@malept/cross-spawn-promise@2.0.0
	@mapbox/node-pre-gyp@1.0.11
	@nodable/entities@2.1.0
	@nodelib/fs.scandir@2.1.5
	@nodelib/fs.stat@2.0.3
	@nodelib/fs.stat@2.0.5
	@nodelib/fs.walk@1.2.8
	@nornagon/put@0.0.8
	@octokit/auth-app@8.1.2
	@octokit/auth-oauth-app@9.0.3
	@octokit/auth-oauth-device@8.0.3
	@octokit/auth-oauth-user@6.0.2
	@octokit/auth-token@6.0.0
	@octokit/core@7.0.6
	@octokit/endpoint@11.0.2
	@octokit/graphql@9.0.3
	@octokit/oauth-authorization-url@8.0.0
	@octokit/oauth-methods@6.0.2
	@octokit/openapi-types@27.0.0
	@octokit/plugin-paginate-rest@14.0.0
	@octokit/plugin-request-log@6.0.0
	@octokit/plugin-rest-endpoint-methods@17.0.0
	@octokit/request@10.0.7
	@octokit/request-error@7.1.0
	@octokit/rest@22.0.1
	@octokit/types@16.0.0
	@opentelemetry/api@1.0.4
	@oxfmt/binding-linux-arm64-gnu@0.42.0|arm64,elibc_glibc
	@oxfmt/binding-linux-arm64-musl@0.42.0|arm64,elibc_musl
	@oxfmt/binding-linux-x64-gnu@0.42.0|amd64,elibc_glibc
	@oxfmt/binding-linux-x64-musl@0.42.0|amd64,elibc_musl
	@oxlint/binding-linux-arm64-gnu@1.57.0|arm64,elibc_glibc
	@oxlint/binding-linux-arm64-musl@1.57.0|arm64,elibc_musl
	@oxlint/binding-linux-x64-gnu@1.57.0|amd64,elibc_glibc
	@oxlint/binding-linux-x64-musl@1.57.0|amd64,elibc_musl
	@pkgjs/parseargs@0.11.0
	@primer/octicons@10.0.0
	@protobuf-ts/runtime@2.11.1
	@protobuf-ts/runtime-rpc@2.11.1
	@sec-ant/readable-stream@0.4.1
	@sentry/cli@1.72.0
	@simple-git/args-pathspec@1.0.3
	@simple-git/argv-parser@1.1.1
	@sindresorhus/is@4.6.0
	@sindresorhus/is@7.1.1
	@sindresorhus/merge-streams@2.3.0
	@sinonjs/commons@1.8.6
	@sinonjs/fake-timers@6.0.1
	@sinonjs/samsam@5.3.1
	@sinonjs/text-encoding@0.7.3
	@szmarczak/http-timer@4.0.6
	@types/basic-auth@1.1.8
	@types/body-parser@1.19.6
	@types/busboy@1.5.4
	@types/cacheable-request@6.0.2
	@types/chai@4.3.20
	@types/chai@5.2.3
	@types/chai-as-promised@7.1.8
	@types/color-name@1.1.1
	@types/connect@3.4.38
	@types/debug@4.1.7
	@types/deep-eql@4.0.2
	@types/dirty-chai@2.0.5
	@types/eslint@9.6.1
	@types/eslint-scope@3.7.7
	@types/estree@1.0.8
	@types/express@4.17.23
	@types/express-serve-static-core@4.19.7
	@types/glob@7.2.0
	@types/hast@3.0.4
	@types/http-cache-semantics@4.0.1
	@types/http-cache-semantics@4.0.4
	@types/http-errors@2.0.5
	@types/json-buffer@3.0.0
	@types/json-schema@7.0.11
	@types/json-schema@7.0.15
	@types/json5@0.0.29
	@types/katex@0.16.7
	@types/keyv@3.1.4
	@types/linkify-it@5.0.0
	@types/markdown-it@14.1.2
	@types/mdast@4.0.4
	@types/mdurl@2.0.0
	@types/mime@1.3.5
	@types/minimatch@3.0.3
	@types/minimist@1.2.5
	@types/mocha@7.0.2
	@types/ms@0.7.31
	@types/node@20.16.12
	@types/node@22.7.7
	@types/node@24.9.1
	@types/qs@6.14.0
	@types/range-parser@1.2.7
	@types/responselike@1.0.0
	@types/semver@7.5.8
	@types/send@0.14.7
	@types/send@0.17.5
	@types/send@1.2.0
	@types/serve-static@1.15.9
	@types/sinon@9.0.11
	@types/sinonjs__fake-timers@15.0.0
	@types/stream-chain@2.0.0
	@types/stream-json@1.7.8
	@types/temp@0.9.4
	@types/unist@2.0.6
	@types/unist@3.0.2
	@types/uuid@3.4.13
	@types/w3c-web-serial@1.0.8
	@types/ws@8.18.1
	@types/yauzl@2.10.0
	@typespec/ts-http-runtime@0.3.0
	@ungap/structured-clone@1.2.0
	@vscode/l10n@0.0.10
	@webassemblyjs/ast@1.14.1
	@webassemblyjs/floating-point-hex-parser@1.13.2
	@webassemblyjs/helper-api-error@1.13.2
	@webassemblyjs/helper-buffer@1.14.1
	@webassemblyjs/helper-numbers@1.13.2
	@webassemblyjs/helper-wasm-bytecode@1.13.2
	@webassemblyjs/helper-wasm-section@1.14.1
	@webassemblyjs/ieee754@1.13.2
	@webassemblyjs/leb128@1.13.2
	@webassemblyjs/utf8@1.13.2
	@webassemblyjs/wasm-edit@1.14.1
	@webassemblyjs/wasm-gen@1.14.1
	@webassemblyjs/wasm-opt@1.14.1
	@webassemblyjs/wasm-parser@1.14.1
	@webassemblyjs/wast-printer@1.14.1
	@webpack-cli/configtest@3.0.1
	@webpack-cli/info@3.0.1
	@webpack-cli/serve@3.0.1
	@xmldom/xmldom@0.8.11
	@xmldom/xmldom@0.9.10
	@xtuc/ieee754@1.2.0
	@xtuc/long@4.2.2
	abbrev@1.1.1
	abbrev@4.0.0
	abort-controller@3.0.0
	abstract-socket@2.0.0
	accepts@2.0.0
	acorn@8.12.1
	acorn@8.15.0
	acorn-import-phases@1.0.4
	acorn-jsx@5.3.2
	agent-base@6.0.2
	agent-base@7.1.1
	ajv@6.12.6
	ajv@8.17.1
	ajv-formats@2.1.1
	ajv-keywords@3.5.2
	ajv-keywords@5.1.0
	ansi-colors@4.1.3
	ansi-escapes@7.0.0
	ansi-regex@2.1.1
	ansi-regex@3.0.1
	ansi-regex@5.0.1
	ansi-regex@6.0.1
	ansi-regex@6.2.2
	ansi-styles@3.2.1
	ansi-styles@4.2.1
	ansi-styles@6.2.1
	ansi-styles@6.2.3
	anymatch@3.0.3
	anymatch@3.1.2
	aproba@1.2.0
	aproba@2.1.0
	are-we-there-yet@1.1.7
	are-we-there-yet@2.0.0
	argparse@1.0.10
	argparse@2.0.1
	array-buffer-byte-length@1.0.0
	array-includes@3.1.6
	array-unique@0.3.2
	array.prototype.flat@1.3.1
	array.prototype.flatmap@1.3.1
	array.prototype.tosorted@1.1.1
	arrify@1.0.1
	assertion-error@1.1.0
	assertion-error@2.0.1
	async@3.2.4
	asynckit@0.4.0
	at-least-node@1.0.0
	author-regex@1.0.0
	available-typed-arrays@1.0.5
	balanced-match@1.0.2
	balanced-match@3.0.1
	balanced-match@4.0.4
	base64-js@1.5.1
	baseline-browser-mapping@2.9.19
	basic-auth@2.0.1
	before-after-hook@4.0.0
	big.js@5.2.2
	binary-extensions@2.1.0
	bindings@1.5.0
	bluebird@3.7.2
	body-parser@2.3.0
	boolbase@1.0.0
	boolean@3.2.0
	brace-expansion@1.1.16
	brace-expansion@2.0.2
	brace-expansion@5.0.4
	braces@3.0.3
	browser-stdout@1.3.1
	browserslist@4.28.1
	buffer@6.0.3
	buffer-crc32@0.2.13
	buffer-from@1.1.1
	buffer-from@1.1.2
	builtins@5.0.1
	busboy@1.6.0
	byte-counter@0.1.0
	bytes@3.1.2
	cacheable-lookup@5.0.4
	cacheable-lookup@7.0.0
	cacheable-request@13.0.15
	cacheable-request@7.0.2
	call-bind@1.0.2
	call-bind-apply-helpers@1.0.2
	call-bound@1.0.4
	callsites@3.1.0
	camelcase@6.3.0
	caniuse-lite@1.0.30001768
	canvas@2.11.2
	chai@4.5.0
	chai@5.1.1
	chai-as-promised@7.1.2
	chalk@2.4.2
	chalk@4.1.0
	chalk@4.1.2
	chalk@5.3.0
	character-entities@2.0.0
	character-entities-legacy@3.0.0
	character-reference-invalid@2.0.0
	charenc@0.0.2
	check-error@1.0.3
	check-error@2.1.1
	check-for-leaks@1.2.1
	chokidar@3.6.0
	chownr@2.0.0
	chownr@3.0.0
	chrome-trace-event@1.0.2
	cli-cursor@5.0.0
	cli-spinners@2.9.2
	cli-truncate@5.2.0
	cliui@7.0.4
	clone-deep@4.0.1
	clone-response@1.0.2
	code-point-at@1.1.0
	coffeescript@2.7.0
	color-convert@1.9.3
	color-convert@2.0.1
	color-name@1.1.3
	color-name@1.1.4
	color-support@1.1.3
	colorette@2.0.20
	combined-stream@1.0.8
	comma-separated-tokens@2.0.3
	commander@12.1.0
	commander@13.1.0
	commander@2.20.3
	commander@5.1.0
	commander@8.3.0
	commander@9.5.0
	compare-version@0.1.2
	compress-brotli@1.3.8
	concat-map@0.0.1
	console-control-strings@1.1.0
	content-disposition@1.1.0
	content-type@1.0.5
	content-type@2.0.0
	cookie@0.7.2
	cookie-signature@1.2.2
	core-util-is@1.0.2
	cross-dirname@0.1.0
	cross-spawn@7.0.6
	crypt@0.0.2
	css-selector-parser@3.2.0
	dbus-native@0.4.0
	debug@2.6.9
	debug@3.2.7
	debug@4.4.0
	debug@4.4.1
	debug@4.4.3
	decamelize@4.0.0
	decode-named-character-reference@1.0.2
	decompress-response@10.0.0
	decompress-response@4.2.1
	decompress-response@6.0.0
	deep-eql@4.1.4
	deep-eql@5.0.2
	deep-is@0.1.3
	defer-to-connect@2.0.1
	define-properties@1.2.0
	delayed-stream@1.0.0
	delegates@1.0.0
	depd@2.0.0
	dequal@2.0.3
	destroy@1.2.0
	detect-libc@2.1.2
	detect-node@2.1.0
	devlop@1.1.0
	diff@3.5.1
	diff@4.0.4
	diff@5.2.2
	dir-compare@4.2.0
	dirty-chai@2.0.1
	doctrine@2.1.0
	doctrine@3.0.0
	dunder-proto@1.0.1
	duplexer@0.1.1
	duplexer@0.1.2
	eastasianwidth@0.2.0
	ee-first@1.1.1
	electron-to-chromium@1.5.286
	emoji-regex@10.4.0
	emoji-regex@8.0.0
	emoji-regex@9.2.2
	emojis-list@3.0.0
	encodeurl@2.0.0
	end-of-stream@1.4.4
	enhanced-resolve@4.1.0
	enhanced-resolve@5.19.0
	ensure-posix-path@1.1.1
	entities@4.5.0
	env-paths@2.2.1
	env-paths@3.0.0
	envinfo@7.19.0
	environment@1.1.0
	err-code@2.0.3
	errno@0.1.7
	error-ex@1.3.2
	error-ex@1.3.4
	es-abstract@1.21.2
	es-define-property@1.0.1
	es-errors@1.3.0
	es-module-lexer@2.0.0
	es-object-atoms@1.0.0
	es-object-atoms@1.1.1
	es-set-tostringtag@2.0.1
	es-set-tostringtag@2.1.0
	es-shim-unscopables@1.0.0
	es-to-primitive@1.2.1
	es6-error@4.1.1
	escalade@3.2.0
	escape-html@1.0.3
	escape-string-regexp@1.0.5
	escape-string-regexp@4.0.0
	eslint@8.57.1
	eslint-config-standard@17.0.0
	eslint-config-standard-jsx@11.0.0
	eslint-import-resolver-node@0.3.7
	eslint-module-utils@2.8.0
	eslint-plugin-es@4.1.0
	eslint-plugin-import@2.27.5
	eslint-plugin-n@15.7.0
	eslint-plugin-promise@6.1.1
	eslint-plugin-react@7.32.2
	eslint-scope@5.1.1
	eslint-scope@7.2.2
	eslint-utils@2.1.0
	eslint-utils@3.0.0
	eslint-visitor-keys@1.1.0
	eslint-visitor-keys@2.0.0
	eslint-visitor-keys@3.4.3
	espree@9.6.1
	esprima@4.0.1
	esquery@1.5.0
	esrecurse@4.3.0
	estraverse@4.3.0
	estraverse@5.1.0
	estraverse@5.3.0
	esutils@2.0.3
	etag@1.8.1
	event-stream@4.0.1
	event-target-shim@5.0.1
	eventemitter3@5.0.4
	events@3.3.0
	events-to-array@1.1.2
	exponential-backoff@3.1.3
	express@5.2.1
	extract-zip@2.0.1
	fast-content-type-parse@3.0.0
	fast-deep-equal@3.1.3
	fast-glob@3.3.3
	fast-json-stable-stringify@2.1.0
	fast-levenshtein@2.0.6
	fast-uri@3.1.4
	fast-xml-builder@1.3.0
	fast-xml-parser@5.7.1
	fastest-levenshtein@1.0.14
	fastq@1.8.0
	fd-slicer@1.1.0
	fdir@6.5.0
	file-entry-cache@6.0.1
	file-uri-to-path@1.0.0
	filename-reserved-regex@2.0.0
	filenamify@4.3.0
	fill-range@7.1.1
	finalhandler@2.1.1
	find-up@2.1.0
	find-up@3.0.0
	find-up@4.1.0
	find-up@5.0.0
	flat@5.0.2
	flat-cache@3.0.4
	flatted@3.4.2
	flora-colossus@2.0.0
	folder-hash@4.1.2
	for-each@0.3.3
	foreground-child@3.1.1
	foreground-child@3.3.1
	form-data@2.5.6
	form-data-encoder@4.1.0
	forwarded@0.2.0
	fresh@0.5.2
	fresh@2.0.0
	from@0.1.7
	fs-extra@10.1.0
	fs-extra@11.3.2
	fs-extra@8.1.0
	fs-extra@9.1.0
	fs-minipass@2.1.0
	fs.realpath@1.0.0
	fsevents@2.3.2
	function-bind@1.1.1
	function-bind@1.1.2
	function.prototype.name@1.1.5
	functions-have-names@1.2.3
	galactus@1.0.0
	gauge@2.7.4
	gauge@3.0.2
	get-caller-file@2.0.5
	get-east-asian-width@1.2.0
	get-east-asian-width@1.6.0
	get-func-name@2.0.2
	get-intrinsic@1.3.0
	get-package-info@1.0.0
	get-proto@1.0.1
	get-stdin@8.0.0
	get-stream@5.2.0
	get-stream@9.0.1
	get-symbol-description@1.0.0
	getos@3.2.1
	glob@10.5.0
	glob@11.1.0
	glob@7.2.3
	glob@8.1.0
	glob@9.3.5
	glob-parent@5.1.2
	glob-parent@6.0.2
	glob-to-regexp@0.4.1
	global-agent@3.0.0
	globals@13.20.0
	globalthis@1.0.3
	globby@14.1.0
	gopd@1.0.1
	gopd@1.2.0
	got@11.8.5
	got@14.6.4
	graceful-fs@4.2.11
	graphemer@1.4.0
	has@1.0.3
	has-bigints@1.0.2
	has-flag@3.0.0
	has-flag@4.0.0
	has-property-descriptors@1.0.0
	has-proto@1.0.1
	has-symbols@1.0.3
	has-symbols@1.1.0
	has-tostringtag@1.0.0
	has-tostringtag@1.0.2
	has-unicode@2.0.1
	hasown@2.0.2
	hasown@2.0.4
	hast-util-from-html@2.0.1
	hast-util-from-parse5@8.0.1
	hast-util-parse-selector@4.0.0
	hastscript@8.0.0
	he@1.2.0
	hexy@0.2.11
	hosted-git-info@2.8.9
	http-cache-semantics@4.1.1
	http-cache-semantics@4.2.0
	http-errors@2.0.0
	http-errors@2.0.1
	http-proxy-agent@7.0.2
	http2-wrapper@1.0.3
	http2-wrapper@2.2.1
	https-proxy-agent@5.0.1
	https-proxy-agent@7.0.5
	husky@9.1.7
	iconv-lite@0.7.2
	ieee754@1.2.1
	ignore@5.3.1
	ignore@7.0.4
	import-fresh@3.3.0
	import-local@3.1.0
	imurmurhash@0.1.4
	inflight@1.0.6
	inherits@2.0.4
	internal-slot@1.0.5
	interpret@3.1.1
	ipaddr.js@1.9.1
	is-alphabetical@2.0.0
	is-alphanumerical@2.0.0
	is-array-buffer@3.0.2
	is-arrayish@0.2.1
	is-bigint@1.0.4
	is-binary-path@2.1.0
	is-boolean-object@1.1.2
	is-buffer@1.1.6
	is-callable@1.2.7
	is-core-module@2.12.1
	is-core-module@2.15.1
	is-core-module@2.16.1
	is-core-module@2.9.0
	is-date-object@1.0.5
	is-decimal@2.0.0
	is-extglob@2.1.1
	is-fullwidth-code-point@1.0.0
	is-fullwidth-code-point@3.0.0
	is-fullwidth-code-point@5.0.0
	is-fullwidth-code-point@5.1.0
	is-glob@3.1.0
	is-glob@4.0.3
	is-hexadecimal@2.0.0
	is-interactive@2.0.0
	is-negative-zero@2.0.2
	is-number@7.0.0
	is-number-object@1.0.7
	is-path-inside@3.0.3
	is-plain-obj@2.1.0
	is-plain-object@2.0.4
	is-promise@4.0.0
	is-regex@1.1.4
	is-shared-array-buffer@1.0.2
	is-stream@4.0.1
	is-string@1.0.7
	is-symbol@1.0.4
	is-typed-array@1.1.10
	is-unicode-supported@0.1.0
	is-unicode-supported@1.3.0
	is-unicode-supported@2.1.0
	is-weakref@1.0.2
	isarray@0.0.1
	isarray@1.0.0
	isbinaryfile@4.0.10
	isexe@2.0.0
	isexe@4.0.0
	isobject@3.0.1
	jackspeak@3.4.3
	jackspeak@4.1.1
	jest-worker@27.5.1
	js-tokens@4.0.0
	js-yaml@3.15.0
	js-yaml@4.1.0
	js-yaml@4.1.1
	json-buffer@3.0.1
	json-parse-better-errors@1.0.2
	json-parse-even-better-errors@2.3.1
	json-schema-traverse@0.4.1
	json-schema-traverse@1.0.0
	json-stable-stringify-without-jsonify@1.0.1
	json-stringify-safe@5.0.1
	json5@1.0.2
	json5@2.2.3
	jsonc-parser@3.3.1
	jsonfile@4.0.0
	jsonfile@6.0.1
	jsx-ast-utils@3.3.3
	junk@3.1.0
	just-extend@4.2.1
	katex@0.16.22
	keyv@4.3.1
	keyv@5.5.4
	kind-of@6.0.3
	levn@0.4.1
	linkify-it@5.0.2
	lint-staged@17.0.8
	listr2@10.2.1
	load-json-file@2.0.0
	load-json-file@5.3.0
	loader-runner@4.3.1
	loader-utils@1.4.2
	loader-utils@2.0.4
	locate-path@2.0.0
	locate-path@3.0.0
	locate-path@5.0.0
	locate-path@6.0.0
	lodash@4.18.1
	lodash.camelcase@4.3.0
	lodash.get@4.4.2
	lodash.merge@4.6.2
	log-symbols@4.1.0
	log-symbols@6.0.0
	log-update@6.1.0
	long@4.0.0
	loose-envify@1.4.0
	loupe@2.3.7
	loupe@3.1.1
	lowercase-keys@2.0.0
	lowercase-keys@3.0.0
	lru-cache@10.2.2
	lru-cache@11.2.2
	lru-cache@6.0.0
	lru-cache@9.1.1
	make-dir@3.1.0
	make-error@1.3.5
	map-stream@0.0.7
	markdown-it@14.1.0
	markdownlint@0.38.0
	markdownlint-cli2@0.18.0
	markdownlint-cli2-formatter-default@0.0.5
	matcher@3.0.0
	matcher-collection@1.1.2
	math-intrinsics@1.1.0
	md5@2.3.0
	mdast-util-from-markdown@2.0.2
	mdast-util-to-string@4.0.0
	mdurl@2.0.0
	media-typer@1.1.0
	memory-fs@0.4.1
	merge-descriptors@2.0.0
	merge-stream@2.0.0
	merge2@1.4.1
	micromark@4.0.0
	micromark@4.0.2
	micromark-core-commonmark@2.0.3
	micromark-extension-directive@4.0.0
	micromark-extension-gfm-autolink-literal@2.1.0
	micromark-extension-gfm-footnote@2.1.0
	micromark-extension-gfm-table@2.1.1
	micromark-extension-math@3.1.0
	micromark-factory-destination@2.0.0
	micromark-factory-label@2.0.0
	micromark-factory-space@2.0.0
	micromark-factory-title@2.0.0
	micromark-factory-whitespace@2.0.0
	micromark-util-character@2.1.0
	micromark-util-chunked@2.0.0
	micromark-util-classify-character@2.0.0
	micromark-util-combine-extensions@2.0.0
	micromark-util-decode-numeric-character-reference@2.0.1
	micromark-util-decode-string@2.0.0
	micromark-util-encode@2.0.0
	micromark-util-html-tag-name@2.0.0
	micromark-util-normalize-identifier@2.0.0
	micromark-util-resolve-all@2.0.0
	micromark-util-sanitize-uri@2.0.0
	micromark-util-subtokenize@2.0.1
	micromark-util-symbol@2.0.0
	micromark-util-types@2.0.0
	micromark-util-types@2.0.2
	micromatch@4.0.8
	mime@1.6.0
	mime-db@1.52.0
	mime-db@1.54.0
	mime-types@2.1.35
	mime-types@3.0.2
	mimic-function@5.0.1
	mimic-response@1.0.1
	mimic-response@2.1.0
	mimic-response@3.1.0
	mimic-response@4.0.0
	minimatch@10.2.4
	minimatch@3.1.5
	minimatch@5.1.9
	minimatch@7.4.9
	minimatch@8.0.7
	minimatch@9.0.9
	minimist@0.2.4
	minimist@1.2.8
	minipass@3.3.6
	minipass@4.2.8
	minipass@5.0.0
	minipass@6.0.2
	minipass@7.1.0
	minipass@7.1.2
	minizlib@2.1.2
	minizlib@3.1.0
	mkdirp@0.5.5
	mkdirp@0.5.6
	mkdirp@1.0.4
	mocha@10.8.2
	mocha-junit-reporter@1.23.3
	mocha-multi-reporters@1.5.1
	ms@2.0.0
	ms@2.1.3
	nan@2.23.0
	nan@2.26.2
	natural-compare@1.4.0
	negotiator@1.0.0
	neo-async@2.6.2
	nise@4.1.0
	node-addon-api@8.0.0
	node-addon-api@8.5.0
	node-addon-api@8.7.0
	node-fetch@2.6.7
	node-fetch@2.6.8
	node-fetch@2.7.0
	node-gyp@12.3.0
	node-gyp-build@4.8.4
	node-releases@2.0.27
	nopt@5.0.0
	nopt@9.0.0
	normalize-package-data@2.5.0
	normalize-path@3.0.0
	normalize-url@6.1.0
	normalize-url@8.1.0
	npmlog@4.1.2
	npmlog@5.0.1
	nth-check@2.1.1
	null-loader@4.0.1
	number-is-nan@1.0.1
	object-assign@4.1.1
	object-inspect@1.12.3
	object-inspect@1.13.4
	object-keys@1.1.1
	object.assign@4.1.4
	object.entries@1.1.6
	object.fromentries@2.0.6
	object.hasown@1.1.2
	object.values@1.1.6
	on-finished@2.4.1
	once@1.4.0
	onetime@7.0.0
	optimist@0.6.1
	optionator@0.9.4
	ora@8.1.0
	oxfmt@0.42.0
	oxlint@1.57.0
	p-cancelable@2.1.1
	p-cancelable@4.0.1
	p-limit@1.3.0
	p-limit@2.2.0
	p-limit@2.3.0
	p-limit@3.1.0
	p-locate@2.0.0
	p-locate@3.0.0
	p-locate@4.1.0
	p-locate@5.0.0
	p-try@1.0.0
	p-try@2.2.0
	package-json-from-dist@1.0.1
	parent-module@1.0.1
	parse-author@2.0.0
	parse-entities@4.0.2
	parse-gitignore@0.4.0
	parse-json@2.2.0
	parse-json@4.0.0
	parse-ms@4.0.0
	parse5@7.1.2
	parseurl@1.3.3
	path-exists@3.0.0
	path-exists@4.0.0
	path-expression-matcher@1.5.0
	path-expression-matcher@1.6.2
	path-is-absolute@1.0.1
	path-key@3.1.1
	path-parse@1.0.7
	path-scurry@1.11.1
	path-scurry@1.9.2
	path-scurry@2.0.0
	path-to-regexp@1.9.0
	path-to-regexp@8.4.2
	path-type@2.0.0
	path-type@6.0.0
	path2d@0.2.2
	pathval@1.1.1
	pathval@2.0.0
	pause-stream@0.0.11
	pdfjs-dist@4.2.67
	pe-library@1.0.1
	pend@1.2.0
	picocolors@1.1.1
	picomatch@2.3.2
	picomatch@4.0.4
	pify@2.3.0
	pify@4.0.1
	pkg-conf@3.1.0
	pkg-dir@4.2.0
	plist@3.1.0
	postject@1.0.0-alpha.6
	pre-flight@2.0.0
	prelude-ls@1.2.1
	prettier@3.6.2
	pretty-ms@9.1.0
	proc-log@6.1.0
	process@0.11.10
	process-nextick-args@2.0.1
	progress@2.0.3
	promise-retry@2.0.1
	prop-types@15.8.1
	property-information@6.5.0
	proxy-addr@2.0.7
	proxy-from-env@1.1.0
	prr@1.0.1
	ps-list@7.2.0
	pump@3.0.0
	punycode@1.4.1
	punycode@2.1.1
	punycode.js@2.3.1
	q@1.5.1
	qs@6.15.3
	quick-lru@5.1.1
	randombytes@2.1.0
	range-parser@1.2.1
	raw-body@3.0.2
	react-is@16.13.1
	read-pkg@2.0.0
	read-pkg-up@2.0.0
	readable-stream@2.3.6
	readable-stream@2.3.8
	readable-stream@3.6.2
	readdirp@3.6.0
	rechoir@0.8.0
	regexp.prototype.flags@1.5.0
	regexpp@3.0.0
	require-directory@2.1.1
	require-from-string@2.0.2
	resedit@2.0.3
	resolve@1.22.11
	resolve@1.22.2
	resolve@1.22.8
	resolve@2.0.0-next.4
	resolve-alpn@1.2.1
	resolve-cwd@3.0.0
	resolve-from@4.0.0
	resolve-from@5.0.0
	responselike@2.0.0
	responselike@4.0.2
	restore-cursor@5.1.0
	retry@0.12.0
	reusify@1.0.4
	rfdc@1.4.1
	rimraf@2.6.3
	rimraf@3.0.2
	rimraf@4.4.1
	roarr@2.15.4
	router@2.2.0
	run-parallel@1.1.9
	safe-buffer@5.1.2
	safe-buffer@5.2.1
	safe-regex-test@1.0.0
	safer-buffer@2.1.2
	sax@1.4.1
	schema-utils@3.3.0
	schema-utils@4.3.3
	semver@5.7.2
	semver@6.3.1
	semver@7.5.2
	semver@7.6.3
	semver@7.7.3
	semver-compare@1.0.0
	send@0.19.1
	send@1.2.1
	serialize-error@7.0.1
	serialize-javascript@6.0.2
	serve-static@2.2.1
	set-blocking@2.0.0
	setprototypeof@1.2.0
	shallow-clone@3.0.1
	shebang-command@2.0.0
	shebang-regex@3.0.0
	side-channel@1.0.4
	side-channel@1.1.1
	side-channel-list@1.0.1
	side-channel-map@1.0.1
	side-channel-weakmap@1.0.2
	signal-exit@3.0.7
	signal-exit@4.1.0
	simple-concat@1.0.1
	simple-get@3.1.1
	simple-git@3.36.0
	sinon@9.2.4
	slash@5.1.0
	slice-ansi@7.1.0
	slice-ansi@8.0.0
	source-map@0.6.1
	source-map-support@0.5.19
	source-map-support@0.5.21
	space-separated-tokens@2.0.2
	spdx-correct@3.2.0
	spdx-exceptions@2.3.0
	spdx-expression-parse@3.0.1
	spdx-license-ids@3.0.13
	split@1.0.1
	sprintf-js@1.0.3
	sprintf-js@1.1.2
	standard@17.0.0
	standard-engine@15.0.0
	statuses@2.0.1
	statuses@2.0.2
	stdin-discarder@0.2.2
	stream-chain@2.2.5
	stream-combiner@0.2.2
	stream-json@1.9.1
	streamsearch@1.1.0
	string-argv@0.3.2
	string-width@1.0.2
	string-width@4.2.0
	string-width@4.2.3
	string-width@5.1.2
	string-width@7.2.0
	string-width@8.2.1
	string.prototype.matchall@4.0.8
	string.prototype.trim@1.2.7
	string.prototype.trimend@1.0.6
	string.prototype.trimstart@1.0.6
	string_decoder@1.1.1
	string_decoder@1.3.0
	strip-ansi@3.0.1
	strip-ansi@4.0.0
	strip-ansi@6.0.1
	strip-ansi@7.1.0
	strip-ansi@7.2.0
	strip-bom@3.0.0
	strip-json-comments@3.1.1
	strip-outer@1.0.1
	strnum@2.2.3
	sumchecker@3.0.1
	supports-color@5.5.0
	supports-color@7.1.0
	supports-color@8.1.1
	supports-preserve-symlinks-flag@1.0.0
	tap-parser@1.2.2
	tap-xunit@2.4.1
	tapable@1.1.3
	tapable@2.3.0
	tar@6.2.1
	tar@7.5.13
	temp@0.9.4
	terser@5.46.0
	terser-webpack-plugin@5.4.0
	text-table@0.2.0
	through@2.3.8
	through2@2.0.5
	tinyexec@1.2.4
	tinyglobby@0.2.15
	tinypool@2.1.0
	to-regex-range@5.0.1
	toad-cache@3.7.0
	toidentifier@1.0.1
	tr46@0.0.3
	trim-repeated@1.0.0
	ts-loader@8.0.2
	ts-node@6.2.0
	tsconfig-paths@3.14.2
	tslib@1.10.0
	tslib@1.14.1
	tslib@2.8.1
	tunnel@0.0.6
	type-check@0.4.0
	type-detect@4.0.8
	type-detect@4.1.0
	type-fest@0.13.1
	type-fest@0.20.2
	type-fest@0.3.1
	type-fest@4.41.0
	type-is@2.1.0
	typed-array-length@1.0.4
	typescript@5.8.3
	uc.micro@2.1.0
	unbox-primitive@1.0.2
	undici@5.29.0
	undici@6.25.0
	undici-types@6.19.8
	undici-types@7.16.0
	unicorn-magic@0.3.0
	unist-util-is@6.0.0
	unist-util-select@5.1.0
	unist-util-stringify-position@4.0.0
	unist-util-visit@5.0.0
	unist-util-visit-parents@6.0.1
	universal-github-app-jwt@2.2.2
	universal-user-agent@7.0.3
	universalify@0.1.2
	universalify@1.0.0
	universalify@2.0.0
	unpipe@1.0.0
	update-browserslist-db@1.2.3
	uri-js@4.4.1
	url@0.11.4
	util-deprecate@1.0.2
	uuid@14.0.1
	uuid@8.3.2
	validate-npm-package-license@3.0.4
	vary@1.1.2
	vfile@6.0.2
	vfile-location@5.0.3
	vfile-message@4.0.2
	vscode-jsonrpc@8.1.0
	vscode-languageserver@8.1.0
	vscode-languageserver-protocol@3.17.3
	vscode-languageserver-textdocument@1.0.8
	vscode-languageserver-types@3.17.2
	vscode-languageserver-types@3.17.3
	vscode-uri@3.1.0
	walk-sync@0.3.4
	watchpack@2.5.1
	web-namespaces@2.0.1
	webidl-conversions@3.0.1
	webpack@5.105.0
	webpack-cli@6.0.1
	webpack-merge@6.0.1
	webpack-sources@3.3.3
	whatwg-url@5.0.0
	which@2.0.2
	which@6.0.1
	which-boxed-primitive@1.0.2
	which-typed-array@1.1.9
	wide-align@1.1.5
	wildcard@2.0.1
	winreg@1.2.4
	word-wrap@1.2.5
	wordwrap@0.0.3
	workerpool@6.5.1
	wrap-ansi@10.0.0
	wrap-ansi@7.0.0
	wrap-ansi@8.1.0
	wrap-ansi@9.0.0
	wrapper-webpack-plugin@2.2.2
	wrappy@1.0.2
	ws@8.21.0
	xdg-basedir@4.0.0
	xml@1.0.1
	xml-naming@0.3.0
	xml2js@0.5.0
	xmlbuilder@11.0.1
	xmlbuilder@15.1.1
	xmlbuilder@4.2.1
	xtend@4.0.2
	y18n@5.0.8
	yallist@4.0.0
	yallist@5.0.0
	yaml@2.8.3
	yaml@2.9.0
	yargs@16.2.0
	yargs-parser@20.2.9
	yargs-parser@21.1.1
	yargs-unparser@2.0.0
	yauzl@2.10.0
	yn@2.0.0
	yocto-queue@0.1.0
	zwitch@2.0.2
"

LLVM_COMPAT=( 21 22 23 )
PYTHON_COMPAT=( python3_{11..14} )
PYTHON_REQ_USE="xml(+)"
RUST_MIN_VER=1.91.0
RUST_NEEDS_LLVM="yes please"
RUST_REQ_USE="rustfmt"
NPM_OPTIONAL=1

inherit check-reqs chromium-2 edo flag-o-matic llvm-r2 ninja-utils npm pax-utils
inherit python-any-r1 rust toolchain-funcs

DESCRIPTION="Build cross-platform desktop apps with JavaScript, HTML, and CSS"
HOMEPAGE="https://www.electronjs.org/ https://github.com/electron/electron"
SRC_URI="
	https://commondatastorage.googleapis.com/chromium-browser-official/chromium-${CHROMIUM_VER}-lite.tar.xz
	https://github.com/electron/electron/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz
	https://github.com/nodejs/node/archive/refs/tags/v${ELECTRON_NODE_VER}.tar.gz
		-> electron-node-${ELECTRON_NODE_VER}.gh.tar.gz
	https://github.com/nodejs/nan/archive/${ELECTRON_NAN_COMMIT}.tar.gz
		-> electron-nan-${ELECTRON_NAN_COMMIT}.gh.tar.gz
	https://deps.gentoo.zip/www-client/chromium/rollup-wasm-node-${ROLLUP_VER}.tgz
	https://codeberg.org/selfisekai/copium/archive/${COPIUM_COMMIT}.tar.gz
		-> chromium-patches-copium-${COPIUM_COMMIT:0:10}.tar.gz
	${NPM_PKG_URIS}
"
S="${WORKDIR}/chromium-${CHROMIUM_VER}"

# Chromium, Node.js and Electron
LICENSE="Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 Base64 Boost-1.0 CC-BY-3.0 CC-BY-4.0 Clear-BSD FFT2D FTL"
LICENSE+=" IJG ISC LGPL-2 LGPL-2.1 MIT MPL-1.1 MPL-2.0 Ms-PL PSF-2 SGI-B-2.0 SSLeay SunSoft Unicode-3.0"
LICENSE+=" Unicode-DFS-2015 Unlicense UoI-NCSA ZLIB libtiff openssl"
SLOT="$(ver_cut 1)"
KEYWORDS="~amd64 ~arm64"
IUSE="+X cups custom-cflags debug kerberos +official pax-kernel +proprietary-codecs pulseaudio"
IUSE+=" +screencast selinux system-harfbuzz +system-zstd +vaapi +wayland cpu_flags_x86_avx512f"
RESTRICT="mirror test"
REQUIRED_USE="
	|| ( X wayland )
	screencast? ( wayland )
"

COMMON_X_DEPEND="
	x11-libs/libXcomposite:=
	x11-libs/libXcursor:=
	x11-libs/libXdamage:=
	x11-libs/libXfixes:=
	>=x11-libs/libXi-1.6.0:=
	x11-libs/libXrandr:=
	x11-libs/libXrender:=
	x11-libs/libXtst:=
	x11-libs/libxshmfence:=
"

COMMON_SNAPSHOT_DEPEND="
	>=dev-libs/libxml2-2.12.4:=[icu]
	dev-libs/nspr:=
	>=dev-libs/nss-3.26:=
	dev-libs/libxslt:=
	media-libs/fontconfig:=
	>=media-libs/freetype-2.11.0-r1:=
	system-harfbuzz? ( >=media-libs/harfbuzz-3:0=[icu(-)] )
	media-libs/libjpeg-turbo:=
	system-zstd? ( >=app-arch/zstd-1.5.5:= )
	>=media-libs/libwebp-0.4.0:=
	media-libs/mesa:=[gbm(+)]
	>=media-libs/openh264-2.6.0:=
	sys-libs/zlib:=
	dev-libs/glib:2
	>=media-libs/alsa-lib-1.0.19:=
	media-video/pipewire:=
	pulseaudio? ( media-libs/libpulse:= )
	sys-apps/pciutils:=
	kerberos? ( virtual/krb5 )
	vaapi? ( >=media-libs/libva-2.7:=[X?,wayland?] )
	X? (
		x11-base/xorg-proto:=
		x11-libs/libX11:=
		x11-libs/libxcb:=
		x11-libs/libXext:=
	)
	x11-libs/libxkbcommon:=
	wayland? (
		dev-libs/libffi:=
		dev-libs/wayland:=
	)
"

COMMON_DEPEND="
	${COMMON_SNAPSHOT_DEPEND}
	app-arch/bzip2:=
	dev-libs/expat:=
	net-misc/curl[ssl]
	sys-apps/dbus:=
	media-libs/flac:=
	sys-libs/zlib:=[minizip]
	>=app-accessibility/at-spi2-core-2.46.0:2
	media-libs/mesa:=[X?,wayland?]
	virtual/udev
	x11-libs/cairo:=
	x11-libs/gdk-pixbuf:2
	x11-libs/pango:=
	cups? ( >=net-print/cups-1.3.11:= )
	X? ( ${COMMON_X_DEPEND} )
"
RDEPEND="${COMMON_DEPEND}
	x11-libs/gtk+:3[X?,wayland?]
	virtual/ttf-fonts
	selinux? ( sec-policy/selinux-chromium )
"
DEPEND="${COMMON_DEPEND}
	media-video/pipewire
	x11-libs/gtk+:3[X?,wayland?]
"
BDEPEND="
	${COMMON_SNAPSHOT_DEPEND}
	${PYTHON_DEPS}
	${RUST_DEPEND}
	$(python_gen_any_dep '
		dev-python/setuptools[${PYTHON_USEDEP}]
	')
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}
		llvm-core/llvm:${LLVM_SLOT}
		llvm-runtimes/compiler-rt:${LLVM_SLOT}
	')
	|| (
		$(llvm_gen_dep 'llvm-core/lld:${LLVM_SLOT}')
		>=sys-devel/mold-2.41.0
	)
	>=app-arch/gzip-1.7
	app-alternatives/ninja
	dev-cpp/abseil-cpp
	dev-lang/perl
	dev-lang/typescript
	>=dev-build/gn-${GN_MIN_VER}
	>=dev-util/bindgen-0.72.1
	dev-util/esbuild:${ESBUILD_VER}
	>=dev-util/gperf-3.2
	dev-vcs/git
	>=net-libs/nodejs-24.12.0[inspector,npm]
	sys-apps/hwdata
	>=sys-devel/bison-2.4.3
	sys-devel/flex
	virtual/pkgconfig
"

python_check_deps() {
	python_has_version "dev-python/setuptools[${PYTHON_USEDEP}]"
}

pre_build_checks() {
	local CHECKREQS_MEMORY="8G"
	local CHECKREQS_DISK_BUILD="30G"
	if tc-is-lto; then
		CHECKREQS_MEMORY="17G"
		CHECKREQS_DISK_BUILD="35G"
	fi
	check-reqs_${EBUILD_PHASE_FUNC}
}

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && pre_build_checks
}

pkg_setup() {
	if [[ ${MERGE_TYPE} != binary ]]; then
		pre_build_checks

		local want_lto="false"
		tc-is-lto && want_lto="true"

		llvm-r2_pkg_setup
		rust_pkg_setup

		# Forcing clang; respect llvm_slot_x to enable selection of impl via LLVM_COMPAT
		AR=llvm-ar
		CPP="${CHOST}-clang++-${LLVM_SLOT} -E"
		NM=llvm-nm
		CC="${CHOST}-clang-${LLVM_SLOT}"
		CXX="${CHOST}-clang++-${LLVM_SLOT}"

		use_lto="false"
		if [[ "$want_lto" == "true" ]]; then
			if use arm64 && [[ "${LLVM_SLOT}" -lt 22 ]]; then
				einfo "LTO is broken with LLVM 21 on arm64, ignoring CFLAGS."
			else
				use_lto="true"
			fi
			filter-lto
		fi
		export use_lto

		# Required for split LTO units
		export RUSTC_BOOTSTRAP=1

		if ver_test $(gn --version || die) -lt ${GN_MIN_VER}; then
			die "dev-build/gn >= ${GN_MIN_VER} is required to build Electron"
		fi

		if tc-ld-is-lld; then
			local lld_ver=$(ld.lld --version | awk '{split($2,a,"."); print a[1]}' || die "Failed to check lld version")
			if [[ ${lld_ver} -lt ${LLVM_SLOT} ]]; then
				die "Your lld version (${lld_ver}) is too old for the selected LLVM slot (${LLVM_SLOT})."
			fi
		fi

		python-any-r1_pkg_setup
	fi

	chromium_suid_sandbox_check_kernel_config
}

src_unpack() {
	unpack chromium-${CHROMIUM_VER}-lite.tar.xz
	unpack chromium-patches-copium-${COPIUM_COMMIT:0:10}.tar.gz
	unpack rollup-wasm-node-${ROLLUP_VER}.tgz

	# Put Electron, Node.js and nan where gclient would check them out
	unpack ${P}.gh.tar.gz electron-node-${ELECTRON_NODE_VER}.gh.tar.gz \
		electron-nan-${ELECTRON_NAN_COMMIT}.gh.tar.gz
	mv "${WORKDIR}/electron-${PV}" "${S}/electron" || die
	mv "${WORKDIR}/node-${ELECTRON_NODE_VER}" "${S}/third_party/electron_node" || die
	mv "${WORKDIR}/nan-${ELECTRON_NAN_COMMIT}" "${S}/third_party/nan" || die

	npm_setup_env
}

remove_compiler_builtins() {
	# We can't use the bundled compiler builtins with the system toolchain
	# We used to `grep` then `sed`, but it was indirect. Combining the two into a single
	# `awk` command is more efficient and lets us document the logic more clearly.

	local pattern='    configs += [ "//build/config/clang:compiler_builtins" ]'
	local target='build/config/compiler/BUILD.gn'

	local tmpfile
	tmpfile=$(mktemp) || die "Failed to create temporary file."

	if awk -v pat="${pattern}" '
	BEGIN {
		match_found = 0
	}

	# If the delete countdown is active, decrement it and skip to the next line.
	d > 0 { d--; next }

	# If the current line matches the pattern...
	$0 == pat {
		match_found = 1   # ...set our flag to true.
		d = 2             # Set delete counter for this line and the next two.
		prev = ""         # Clear the buffered previous line so it is not printed.
		next
	}

	# For any other line, print the buffered previous line.
	NR > 1 { print prev }

	# Buffer the current line to be printed on the next cycle.
	{ prev = $0 }

	END {
		# Print the last line if it was not part of a deleted block.
		if (d == 0) { print prev }

		# If the pattern was never found, exit with a failure code.
		if (match_found == 0) {
		exit 1
		}
	}
	' "${target}" > "${tmpfile}"; then
		# AWK SUCCEEDED (exit code 0): The pattern was found and edited.
		# This is to avoid gawk's `-i inplace` option which users complain about.
		mv "${tmpfile}" "${target}"
	else
		# AWK FAILED (exit code 1): The pattern was not found.
		rm -f "${tmpfile}"
		einfo "Pattern not found in ${target}, skipping remove_compiler_builtins."
	fi
}

# @USAGE: <repo dir> <patch>
# The -lite Chromium tarball has no tests or test data; skip the parts of a
# patch that touch files it does not ship (but never files the patch adds).
electron_apply_patch() {
	local repo=${1} patch=${2} file
	local git=( git -C "${repo}" apply --whitespace=nowarn -p1 )
	if ! "${git[@]}" --check "${patch}" 2>/dev/null; then
		local -a excludes=() created=()
		while read -r file; do
			created+=( "${file}" )
		done < <("${git[@]}" --summary "${patch}" | awk '$1 == "create" { print $NF }')
		while IFS=$'\t' read -r _ _ file; do
			[[ -e ${repo}/${file} ]] || has "${file}" "${created[@]}" ||
				excludes+=( --exclude="${file}" )
		done < <("${git[@]}" --numstat "${patch}")
		[[ ${#excludes[@]} -gt 0 ]] &&
			einfo "  ${patch##*/}: skipping ${excludes[*]#--exclude=}"
		git+=( "${excludes[@]}" )
	fi
	"${git[@]}" "${patch}" || die "Electron patch failed: ${patch}"
}

electron_apply_patches() {
	# Electron keeps one patch series per repository, listed in apply order
	# in each directory's .patches file. See electron/patches/config.json.
	local entry dir repo patch
	while read -r entry; do
		dir=${entry%%$'\t'*}
		repo=${entry#*$'\t'}
		dir=${dir#src/}
		repo=${repo#src}
		repo=${repo#/}
		[[ -f ${dir}/.patches ]] || continue
		if [[ ! -d ${S}/${repo:-.} ]]; then
			einfo "Skipping Electron patches for ${repo} (not part of the Linux source)"
			continue
		fi
		einfo "Applying Electron patches to ${repo:-chromium}"
		while read -r patch; do
			[[ -n ${patch} ]] || continue
			electron_apply_patch "${S}/${repo:-.}" "${S}/${dir}/${patch}"
		done < "${dir}/.patches"
	done < <("${EPYTHON}" -c '
import json, sys
for e in json.load(open("electron/patches/config.json")):
	print(e["patch_dir"] + "\t" + e["repo"])
')
}

src_prepare() {
	python_setup

	# Electron's patches are made against pristine Chromium, apply them first
	electron_apply_patches

	local PATCHES=(
		"${FILESDIR}/cr109-system-zlib.patch"
		"${FILESDIR}/cr138-nodejs-version-check.patch"
		"${FILESDIR}/cr144-glibc-2.43.patch"
		"${FILESDIR}/cr145-revert-to-rollup-wasm.patch"
		"${FILESDIR}/cr148-v8-fix-cfi-sanitizer-set-death-callback.patch"
		"${FILESDIR}/cr152-cbor-crubit-enable-cpp-api-from-rust.patch"
		"${FILESDIR}/cr152-devtools-public-inputs.patch"
		"${FILESDIR}/cr152-rust-wrapper-inputs-system-rust.patch"
		"${FILESDIR}/cr152-dawn-disable-lifetime-safety-flags.patch"
		"${FILESDIR}/cr152-dawn-system-go.patch"
		"${FILESDIR}/cross-compile.patch"
		"${WORKDIR}/copium/cr143-libsync-__BEGIN_DECLS.patch"
		"${FILESDIR}/cr152-unbundle-minizip-undo-unicode.patch"
		"${FILESDIR}/cr153-bytemuck-stable-simd.patch"
	)

	if has_version "<=media-libs/fontconfig-2.17.1"; then
		PATCHES+=( "${FILESDIR}/chromium-142-work-with-old-fontconfig.patch" )
	fi

	if [[ ${LLVM_SLOT} -lt 23 ]]; then
		PATCHES+=(
			"${FILESDIR}/cr147-disable-fno-lifetime-dse.patch"
			"${FILESDIR}/cr149-fdiagnostics-show-inlining-chain.patch"
			"${FILESDIR}/cr149-ubsan-feature.patch"
		)
	fi

	remove_compiler_builtins

	# We can't rely on the eselect'd Rust to actually include rustfmt
	local suffix="-${RUST_SLOT}"
	[[ "${RUST_TYPE}" == "binary" ]] && suffix="-bin-${RUST_SLOT}"
	sed -i "s|/bin/rustfmt|/bin/rustfmt${suffix}|g" build/rust/rust_bindgen_generator.gni ||
		die "Failed to update rustfmt path"

	einfo "Moving rollup wasm-node package into place ..."
	mkdir -p third_party/devtools-frontend/src/node_modules/@rollup/wasm-node || die
	mv "${WORKDIR}"/package/* third_party/devtools-frontend/src/node_modules/@rollup/wasm-node || die

	default

	local esbuild_js="${S}/third_party/devtools-frontend/src/node_modules/esbuild/lib/main.js"
	local found
	found=$(awk -F'"' '/if \(binaryVersion !==/ {print $2}' "${esbuild_js}")
	if [[ "${found}" != "${ESBUILD_VER}" ]]; then
		die "esbuild version mismatch: expected ${ESBUILD_VER}, found ${found}"
	fi

	elog "Removing bundled binaries from source tree ..."
	${EPYTHON} "${FILESDIR}/bin-finder.py" --elf "${S}" | awk '{print $1}' | xargs rm -f ||
		die "Failed to remove bundled binaries"

	local esbuild_path="${S}/third_party/devtools-frontend/src/third_party/esbuild"
	local -A restore_list=(
		["/usr/bin/esbuild-${ESBUILD_VER}"]="${esbuild_path}/esbuild"
		["/usr/bin/gperf"]="${S}/third_party/gperf/cipd/bin/gperf"
		["/usr/bin/node"]="${S}/third_party/node/linux/node-linux-x64/bin/node"
	)
	local src dst
	for src in "${!restore_list[@]}"; do
		dst="${restore_list[${src}]}"
		mkdir -p "$(dirname "${dst}")" || die
		ln -s "${src}" "${dst}" || die "Failed to symlink ${dst} from ${src}"
	done

	sed -i -e "s|\(^script_executable = \).*|\1\"${EPYTHON}\"|g" .gn || die

	sed 's|//third_party/usb_ids/usb.ids|/usr/share/hwdata/usb.ids|g' \
		-i services/device/public/cpp/usb/BUILD.gn || die "Failed to set system usb.ids path"

	local keeplibs=(
		base/third_party/cityhash
		base/third_party/double_conversion
		base/third_party/icu
		base/third_party/nspr
		base/third_party/superfasthash
		base/third_party/symbolize
		base/third_party/xdg_user_dirs
		buildtools/third_party/libc++
		buildtools/third_party/libc++abi
		net/third_party/mozilla_security_manager
		net/third_party/quic
		net/third_party/uri_template
		third_party/abseil-cpp
		third_party/angle
		third_party/angle/src/common/third_party/xxhash
		third_party/angle/src/third_party/ceval
		third_party/angle/src/third_party/libXNVCtrl
		third_party/angle/src/third_party/volk
		third_party/anonymous_tokens
		third_party/apple_apsl
		third_party/axe-core
		third_party/bidimapper
		third_party/blink
		third_party/boringssl
		third_party/boringssl/src/third_party/fiat
		third_party/breakpad
		third_party/breakpad/breakpad/src/third_party/curl
		third_party/brotli
		third_party/catapult
		third_party/catapult/common/py_vulcanize/third_party/rcssmin
		third_party/catapult/common/py_vulcanize/third_party/rjsmin
		third_party/catapult/third_party/beautifulsoup4-4.9.3
		third_party/catapult/third_party/html5lib-1.1
		third_party/catapult/third_party/polymer
		third_party/catapult/third_party/six
		third_party/catapult/third_party/typ
		third_party/catapult/tracing/third_party/d3
		third_party/catapult/tracing/third_party/gl-matrix
		third_party/catapult/tracing/third_party/jpeg-js
		third_party/catapult/tracing/third_party/jszip
		third_party/catapult/tracing/third_party/mannwhitneyu
		third_party/catapult/tracing/third_party/oboe
		third_party/catapult/tracing/third_party/pako
		third_party/ced
		third_party/cld_3
		third_party/closure_compiler
		third_party/compiler-rt # Since M137 atomic is required; we could probably unbundle this as a target of opportunity.
		third_party/content_analysis_sdk
		third_party/cpuinfo
		third_party/crabbyavif
		third_party/crubit
		third_party/crashpad
		third_party/crashpad/crashpad/third_party/lss
		third_party/crashpad/crashpad/third_party/zlib
		third_party/crc32c
		third_party/cros_system_api
		third_party/d3
		third_party/dav1d
		third_party/dawn
		third_party/dawn/third_party/gn/webgpu-cts
		third_party/dawn/third_party/OpenGL-Registry
		third_party/dawn/third_party/renderdoc
		third_party/dawn/third_party/webgpu-headers
		third_party/depot_tools
		third_party/devscripts
		third_party/devtools-frontend
		third_party/devtools-frontend/src/front_end/third_party/acorn
		third_party/devtools-frontend/src/front_end/third_party/additional_readme_paths.json
		third_party/devtools-frontend/src/front_end/third_party/axe-core
		third_party/devtools-frontend/src/front_end/third_party/chromium
		third_party/devtools-frontend/src/front_end/third_party/codemirror
		third_party/devtools-frontend/src/front_end/third_party/csp_evaluator
		third_party/devtools-frontend/src/front_end/third_party/diff
		third_party/devtools-frontend/src/front_end/third_party/i18n
		third_party/devtools-frontend/src/front_end/third_party/intl-messageformat
		third_party/devtools-frontend/src/front_end/third_party/json5
		third_party/devtools-frontend/src/front_end/third_party/legacy-javascript
		third_party/devtools-frontend/src/front_end/third_party/lighthouse
		third_party/devtools-frontend/src/front_end/third_party/lit
		third_party/devtools-frontend/src/front_end/third_party/marked
		third_party/devtools-frontend/src/front_end/third_party/puppeteer
		third_party/devtools-frontend/src/front_end/third_party/puppeteer/package/lib/third_party/mitt
		third_party/devtools-frontend/src/front_end/third_party/puppeteer/package/lib/third_party/parsel-js
		third_party/devtools-frontend/src/front_end/third_party/puppeteer/package/lib/third_party/rxjs
		third_party/devtools-frontend/src/front_end/third_party/puppeteer/package/lib/third_party/urlpattern-polyfill
		third_party/devtools-frontend/src/front_end/third_party/source-map-scopes-codec
		third_party/devtools-frontend/src/front_end/third_party/third-party-web
		third_party/devtools-frontend/src/front_end/third_party/vscode.web-custom-data
		third_party/devtools-frontend/src/front_end/third_party/wasmparser
		third_party/devtools-frontend/src/front_end/third_party/web-vitals
		third_party/devtools-frontend/src/third_party
		third_party/dom_distiller_js
		third_party/dragonbox
		third_party/eigen3
		third_party/electron_node
		third_party/nan
		third_party/emoji-segmenter
		third_party/farmhash
		third_party/fast_float
		third_party/fdlibm
		third_party/federated_compute
		third_party/federated_compute/third_party/googleapis
		third_party/federated_compute/third_party/protodatastore-cpp
		third_party/federated_compute/third_party/tensorflow-federated
		third_party/ffmpeg
		third_party/fft2d
		third_party/flatbuffers
		third_party/fp16
		third_party/freetype
		third_party/fusejs
		third_party/fxdiv
		third_party/gemmlowp
		third_party/google_input_tools
		third_party/google_input_tools/third_party/closure_library
		third_party/google_input_tools/third_party/closure_library/third_party/closure
		third_party/googletest
		third_party/gperf # We symlink system gperf, but this will purge the symlink since we tidy up afterwards.
		third_party/highway
		third_party/hunspell
		third_party/ink/src/ink/brush
		third_party/ink/src/ink/color
		third_party/ink/src/ink/geometry
		third_party/ink/src/ink/rendering
		third_party/ink/src/ink/rendering/skia/common_internal
		third_party/ink/src/ink/rendering/skia/native
		third_party/ink/src/ink/rendering/skia/native/internal
		third_party/ink/src/ink/strokes
		third_party/ink/src/ink/types
		third_party/inspector_protocol
		third_party/ipcz
		third_party/jinja2
		third_party/jsoncpp
		third_party/khronos
		third_party/lens_server_proto
		third_party/leveldatabase
		third_party/libaddressinput
		third_party/libjingle
		third_party/libaom
		third_party/libaom/source/libaom/third_party/fastfeat
		third_party/libaom/source/libaom/third_party/vector
		third_party/libaom/source/libaom/third_party/x86inc
		third_party/libc++
		third_party/libdrm
		third_party/libgav1
		third_party/libpfm4
		third_party/libphonenumber
		third_party/libpng
		third_party/libsecret
		third_party/libsrtp
		third_party/libsync
		third_party/libtess2/libtess2
		third_party/libtess2/src/Include
		third_party/libtess2/src/Source
		third_party/liburlpattern
		third_party/libva_protected_content
		third_party/libvpx
		third_party/libvpx/source/libvpx/third_party/x86inc
		third_party/libwebm
		third_party/libx11
		third_party/libxcb-keysyms
		third_party/libxml/chromium
		third_party/libyuv
		third_party/libzip
		third_party/lit
		third_party/llvm-libc
		third_party/llvm-libc/src/shared/
		third_party/lottie
		third_party/lss
		third_party/lzma_sdk
		third_party/mako
		third_party/markupsafe
		third_party/material_color_utilities
		third_party/metrics_proto
		third_party/minigbm
		third_party/ml_dtypes
		third_party/modp_b64
		third_party/nasm
		third_party/nearby
		third_party/neon_2_sse
		third_party/node
		third_party/oak/chromium/proto
		third_party/oak/chromium/proto/attestation
		third_party/omnibox_proto
		third_party/one_euro_filter
		third_party/openscreen
		third_party/openscreen/src/third_party/
		third_party/openscreen/src/third_party/tinycbor/src/src
		third_party/opus
		third_party/ots
		third_party/pdfium
		third_party/pdfium/third_party/agg23
		third_party/pdfium/third_party/bigint
		third_party/pdfium/third_party/freetype
		third_party/pdfium/third_party/lcms
		third_party/pdfium/third_party/libopenjpeg
		third_party/pdfium/third_party/libtiff
		third_party/perfetto
		third_party/perfetto/protos/third_party/android
		third_party/perfetto/protos/third_party/chromium
		third_party/perfetto/protos/third_party/pprof
		third_party/perfetto/protos/third_party/primes
		third_party/perfetto/protos/third_party/simpleperf
		third_party/pffft
		third_party/ply
		third_party/polymer
		third_party/private_membership
		third_party/private-join-and-compute
		third_party/protobuf
		third_party/protobuf/third_party/utf8_range
		third_party/pthreadpool
		third_party/puffin
		third_party/pyjson5
		third_party/pyyaml
		third_party/rapidhash
		third_party/re2
		third_party/readability
		third_party/rnnoise
		third_party/rust
		third_party/ruy
		third_party/s2cellid
		third_party/search_engines_data
		third_party/securemessage
		third_party/selenium-atoms
		third_party/sentencepiece
		third_party/sentencepiece/src/third_party/darts_clone
		third_party/shell-encryption
		third_party/simdutf
		third_party/simplejson
		third_party/six
		third_party/skia
		third_party/skia/include/third_party/vulkan
		third_party/smhasher
		third_party/snappy
		third_party/spirv-headers
		third_party/spirv-tools
		third_party/sqlite
		third_party/swiftshader
		third_party/swiftshader/third_party/astc-encoder
		third_party/swiftshader/third_party/llvm-subzero
		third_party/swiftshader/third_party/marl
		third_party/swiftshader/third_party/SPIRV-Headers/include/spirv
		third_party/swiftshader/third_party/SPIRV-Tools
		third_party/swiftshader/third_party/subzero
		third_party/tensorflow_models
		third_party/tensorflow-text
		third_party/tflite
		third_party/tflite/src/third_party/fft2d
		third_party/tflite/src/third_party/xla/third_party/tsl
		third_party/tflite/src/third_party/xla/xla/tsl/framework
		third_party/tflite/src/third_party/xla/xla/tsl/lib/random
		third_party/tflite/src/third_party/xla/xla/tsl/platform
		third_party/tflite/src/third_party/xla/xla/tsl/protobuf
		third_party/tflite/src/third_party/xla/xla/tsl/util
		third_party/ukey2
		third_party/utf
		third_party/vulkan
		third_party/wayland
		third_party/webdriver
		third_party/webgpu-cts
		third_party/webrtc
		third_party/webrtc/common_audio/third_party/ooura
		third_party/webrtc/common_audio/third_party/spl_sqrt_floor
		third_party/webrtc/modules/third_party/fft
		third_party/webrtc/modules/third_party/g711
		third_party/webrtc/modules/third_party/g722
		third_party/widevine
		third_party/woff2
		third_party/wuffs
		third_party/x11proto
		third_party/xcbproto
		third_party/xnnpack
		third_party/zlib/google
		third_party/zxcvbn-cpp
		url/third_party/mozilla
		v8/third_party/inspector_protocol
		v8/third_party/rapidhash-v8
		v8/third_party/siphash
		v8/third_party/utf8-decoder
		v8/third_party/v8
		v8/third_party/valgrind

		# gyp -> gn leftovers
		third_party/speech-dispatcher
		third_party/usb_ids
	)

	if ! use system-harfbuzz; then
		keeplibs+=( third_party/harfbuzz )
	fi

	# Electron ships icudtl.dat and its components need the bundled ICU data
	keeplibs+=( third_party/icu )

	if ! use system-zstd; then
		keeplibs+=( third_party/zstd )
	fi

	# Arch-specific
	if use arm64; then
		keeplibs+=( third_party/swiftshader/third_party/llvm-10.0 )
	fi
	local not_found_libs=() lib
	for lib in "${keeplibs[@]}"; do
		# Some entries are prefixes, e.g. third_party/vulkan keeps vulkan-headers
		# and vulkan_memory_allocator
		[[ -e "${lib}" ]] || has "${lib}" net/third_party/quic third_party/libjingle third_party/vulkan ||
			not_found_libs+=( "${lib}" )
	done
	if [[ ${#not_found_libs[@]} -gt 0 ]]; then
		eerror "The following keeplibs directories were not found in the source tree:"
		for lib in "${not_found_libs[@]}"; do
			eerror "  ${lib}"
		done
		die "Please update the ebuild."
	fi

	einfo "Unbundling third-party libraries ..."
	build/linux/unbundle/remove_bundled_libraries.py "${keeplibs[@]}" --do-remove || die

	sed -i -e 's|${clang_base_path}/bin/llvm-strip|/bin/true|g' \
		-e 's|${clang_base_path}/bin/llvm-objcopy|/bin/true|g' \
		build/linux/strip_binary.gni || die

	# Electron's own JavaScript (typescript, webpack) comes from its yarn.lock
	pushd electron >/dev/null || die
	npm_with_registry node .yarn/releases/yarn-*.cjs install --immutable
	popd >/dev/null || die
}

src_configure() {
	python_setup
	python_export_utf8_locale || die "Electron builds require a UTF-8 locale."

	export TMPDIR="${WORKDIR}/temp"
	mkdir -p -m 755 "${TMPDIR}" || die

	addpredict /dev/dri/ #nowarn

	local gn_system_libraries=(
		flac
		fontconfig
		freetype
		libjpeg
		libwebp
		libxml
		libxslt
		openh264
		zlib
	)
	use system-zstd && gn_system_libraries+=( zstd )

	if use system-zstd && ! grep -q 'group("headers")' build/linux/unbundle/zstd.gn; then
		# Electron's Node depends on //third_party/zstd:headers
		cat >> build/linux/unbundle/zstd.gn <<-EOF || die
		group("headers") {
		  public_configs = [ ":system_zstd" ]
		  public_deps = [ ":zstd_headers" ]
		}
		EOF
	fi

	build/linux/unbundle/replace_gn_files.py --system-libraries "${gn_system_libraries[@]}" ||
		die "Failed to replace GN files for system libraries"

	local freetype_gni="build/config/freetype/freetype.gni"
	sed -i -e '$d' ${freetype_gni} || die
	echo "  enable_freetype = true" >> ${freetype_gni} || die
	echo "}" >> ${freetype_gni} || die

	if use !custom-cflags; then
		replace-flags "-Os" "-O2"
		strip-flags
		filter-flags "-g*"
		# Skia, ffmpeg and friends build SIMD paths with their own flags and
		# dispatch at runtime; user -march breaks them. USE=custom-cflags
		# keeps them, unsupported.
		filter-flags "-march*" "-mtune*" "-mcpu*"
	fi

	append-flags -Wno-unknown-warning-option

	tc-export AR CC CXX NM
	strip-unsupported-flags
	append-ldflags -Wl,--undefined-version

	# Electron's release args, minus the ones that pull in downloads (PGO
	# profiles) or are decided by USE flags below
	local myconf_gn=(
		'import("//electron/build/args/all.gn")'
		"override_electron_version=\"${PV}\""
		"is_component_build=false"
		"is_component_ffmpeg=true"

		"is_clang=true"
		"clang_use_chrome_plugins=false"
		'custom_toolchain="//build/toolchain/linux/unbundle:default"'
		'host_toolchain="//build/toolchain/linux/unbundle:default"'
		"bindgen_libclang_path=\"$(get_llvm_prefix)/$(get_libdir)\""
		"bindgen_clang_resource_dir=\"${EPREFIX}/usr/lib/clang/${LLVM_SLOT}/include\""
		"bindgen_extra_clang_args=[\"-I${EPREFIX}/usr/lib/clang/${LLVM_SLOT}/include\"]"
		"clang_base_path=\"${EPREFIX}/usr/lib/clang/${LLVM_SLOT}/\""
		"rust_bindgen_root=\"${EPREFIX}/usr/\""
		"rust_sysroot_absolute=\"$(get_rust_prefix)\""
		"rustc_version=\"${RUST_SLOT}\""

		"blink_enable_generated_code_formatting=false"
		"chrome_pgo_phase=0"
		"dcheck_always_on=$(usex debug true false)"
		"dcheck_is_configurable=$(usex debug true false)"
		"disable_fieldtrial_testing_config=true"
		"enable_freetype=true"
		"enable_nocompile_tests=false"
		"enable_widevine=false"
		# unRAR is non-free and not kept in the source tree
		"safe_browsing_use_unrar=false"
		"fatal_linker_warnings=false"
		"is_debug=false"
		"is_official_build=$(usex official true false)"
		"ozone_auto_platforms=false"
		"ozone_platform_headless=true"
		"thin_lto_enable_optimizations=${use_lto}"
		"treat_warnings_as_errors=false"
		"use_custom_libcxx=true"
		"use_ozone=true"
		"use_sysroot=false"
		"use_system_harfbuzz=$(usex system-harfbuzz true false)"
		"use_thin_lto=${use_lto}"
		"v8_use_libm_trig_functions=true"

		"gtk_version=3"
		"link_pulseaudio=$(usex pulseaudio true false)"
		"ozone_platform_wayland=$(usex wayland true false)"
		"ozone_platform_x11=$(usex X true false)"
		"ozone_platform=\"$(usex wayland wayland x11)\""
		"rtc_use_pipewire=$(usex screencast true false)"
		"rtc_link_pipewire=$(usex screencast true false)"
		"use_cups=$(usex cups true false)"
		"use_kerberos=$(usex kerberos true false)"
		"use_pulseaudio=$(usex pulseaudio true false)"
		"use_system_libffi=$(usex wayland true false)"
		"use_system_minigbm=true"
		"use_vaapi=$(usex vaapi true false)"
		"use_xkbcommon=true"
	)

	if tc-ld-is-mold; then
		myconf_gn+=( "use_mold=true" "use_lld=false" "linker_path=\"${EPREFIX}/usr/bin/mold\"" )
	else
		myconf_gn+=( "use_lld=true" )
	fi

	if [[ ${LLVM_SLOT} -lt 23 ]]; then
		myconf_gn+=( 'clang_has_ubsan_feature_ignore=false' )
	fi

	case $(tc-arch) in
		amd64)
			use !custom-cflags && filter-flags -mno-mmx -mno-sse2 -mno-ssse3 -mno-sse4.1 \
				-mno-avx -mno-avx2 -mno-fma -mno-fma4 -mno-xop -mno-sse4a
			myconf_gn+=(
				'target_cpu="x64"'
				"allow_avx512=$(usex cpu_flags_x86_avx512f true false)"
			)
			;;
		arm64)
			myconf_gn+=( 'target_cpu="arm64"' 'devtools_skip_typecheck=false' )
			;;
		*)
			die "Unsupported arch $(tc-arch)"
			;;
	esac

	# Electron always ships ffmpeg as a component; USE=proprietary-codecs
	# decides what it can decode
	if use proprietary-codecs; then
		myconf_gn+=( "proprietary_codecs=true" 'ffmpeg_branding="Chrome"' )
	else
		myconf_gn+=( "proprietary_codecs=false" 'ffmpeg_branding="Chromium"' )
	fi

	if use official; then
		sed -i 's/OFFICIAL_BUILD/GOOGLE_CHROME_BUILD/' \
			tools/generate_shim_headers/generate_shim_headers.py || die
		myconf_gn+=( "symbol_level=0" )
	fi

	einfo "Configuring Electron ..."
	set -- gn gen --args="${myconf_gn[*]}${EXTRA_GN:+ ${EXTRA_GN}}" out/Release
	echo "$@"
	"$@" || die "Failed to configure Electron"
}

src_compile() {
	ulimit -n 2048
	python_setup
	local -x PYTHONPATH=

	if use pax-kernel; then
		local x
		for x in mksnapshot v8_context_snapshot_generator; do
			eninja -C out/Release "${x}"
			pax-mark m "out/Release/${x}"
		done
	fi

	# The build runs Electron's npm scripts (webpack, typescript)
	npm_registry_start
	eninja -C out/Release electron electron:node_headers
	npm_registry_stop

	pax-mark m out/Release/electron
	rm -f out/Release/locales/*.pak.info || die
}

src_install() {
	local ELECTRON_HOME="/usr/$(get_libdir)/electron-${SLOT}"

	pushd out/Release/locales >/dev/null || die
	chromium_remove_language_paks
	popd >/dev/null || die

	exeinto "${ELECTRON_HOME}"
	doexe out/Release/electron
	doexe out/Release/chrome_crashpad_handler
	# Upstream ships the setuid sandbox under this name
	newexe out/Release/chrome_sandbox chrome-sandbox
	fperms 4755 "${ELECTRON_HOME}/chrome-sandbox"

	insinto "${ELECTRON_HOME}"
	doins out/Release/*.pak out/Release/*.bin out/Release/icudtl.dat
	doins -r out/Release/resources out/Release/locales
	(
		shopt -s nullglob
		local lib libs=()
		for lib in out/Release/*.so out/Release/*.so.[0-9] out/Release/vk_swiftshader_icd.json; do
			# ...allowlist_inputs.so is a build-time artifact
			[[ ${lib} == *resource_allowlist_inputs.so ]] || libs+=( "${lib}" )
		done
		[[ ${#libs[@]} -gt 0 ]] && doins "${libs[@]}"
	)

	echo -n "${PV}" > "${T}/version" || die
	doins "${T}/version"

	dosym -r "${ELECTRON_HOME}/electron" "/usr/bin/electron-${SLOT}"

	# Headers for building native addons against this Electron; see
	# electron.eclass
	insinto "${ELECTRON_HOME}/node_headers"
	doins -r out/Release/gen/node_headers/include

	dodoc electron/README.md
}
