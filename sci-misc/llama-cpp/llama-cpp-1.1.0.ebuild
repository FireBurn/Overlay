# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION="10.0"

if [[ ${PV} == 9999 ]]; then
	# The web UI's npm dependencies change with every commit, so the live
	# ebuild installs them from the checked-out lockfile in src_unpack
	NPM_PKGS=""
else
	# Generated from ui/apps/chat/package-lock.json by scripts/npm-deps.py
	NPM_PKGS="
		@adobe/css-tools@4.5.0
		@babel/code-frame@7.29.7
		@babel/helper-string-parser@7.29.13
		@babel/helper-validator-identifier@7.29.7
		@babel/parser@7.29.13
		@babel/runtime@7.29.13
		@babel/types@7.29.11
		@bcoe/v8-coverage@1.0.2
		@blazediff/core@1.9.1
		@cacheable/memory@2.2.0
		@cacheable/utils@2.5.0
		@canvas/image-data@1.1.0
		@chromatic-com/storybook@5.5.1
		@codemirror/autocomplete@6.20.4
		@codemirror/commands@6.11.1
		@codemirror/lang-css@6.3.1
		@codemirror/lang-html@6.4.12
		@codemirror/lang-javascript@6.2.5
		@codemirror/lang-markdown@6.5.2
		@codemirror/language@6.13.1
		@codemirror/lint@6.9.7
		@codemirror/state@6.7.6
		@codemirror/streamparser@6.0.0
		@codemirror/view@6.43.15
		@emnapi/core@1.11.0
		@emnapi/core@1.9.2
		@emnapi/runtime@1.11.0
		@emnapi/runtime@1.11.3
		@emnapi/runtime@1.9.2
		@emnapi/wasi-threads@1.2.1
		@emnapi/wasi-threads@1.2.2
		@esbuild/linux-arm64@0.28.2|arm64
		@esbuild/linux-x64@0.28.2|amd64
		@eslint-community/eslint-utils@4.10.1
		@eslint-community/regexpp@4.12.3
		@eslint/compat@2.1.1
		@eslint/config-array@0.23.5
		@eslint/config-helpers@0.7.0
		@eslint/core@1.2.1
		@eslint/js@10.0.1
		@eslint/object-schema@3.0.5
		@eslint/plugin-kit@0.7.3
		@exodus/bytes@1.16.0
		@floating-ui/core@1.8.0
		@floating-ui/dom@1.8.0
		@floating-ui/utils@0.2.12
		@ggml-org/llama-brand@0.1.0
		@hono/node-server@2.1.6
		@humanfs/core@0.19.2
		@humanfs/node@0.16.8
		@humanfs/types@0.15.0
		@humanwhocodes/module-importer@1.0.1
		@humanwhocodes/retry@0.4.3
		@img/colour@1.1.0
		@img/sharp-libvips-linux-arm64@1.3.4|arm64
		@img/sharp-libvips-linux-x64@1.3.4|amd64
		@img/sharp-libvips-linuxmusl-arm64@1.3.4|arm64,elibc_musl
		@img/sharp-libvips-linuxmusl-x64@1.3.4|amd64,elibc_musl
		@img/sharp-linux-arm64@0.35.5|arm64
		@img/sharp-linux-x64@0.35.5|amd64
		@img/sharp-linuxmusl-arm64@0.35.5|arm64,elibc_musl
		@img/sharp-linuxmusl-x64@0.35.5|amd64,elibc_musl
		@img/sharp-wasm32@0.35.5
		@internationalized/date@3.12.2
		@isaacs/nonrecursive-glob-match@1.1.0
		@jridgewell/gen-mapping@0.3.13
		@jridgewell/remapping@2.3.5
		@jridgewell/resolve-uri@3.1.2
		@jridgewell/sourcemap-codec@1.6.0
		@jridgewell/trace-mapping@0.3.31
		@keyv/bigmap@1.3.1
		@keyv/serialize@1.1.1
		@lezer/common@1.5.5
		@lezer/css@1.3.9
		@lezer/highlight@1.2.5
		@lezer/html@1.3.13
		@lezer/javascript@1.5.6
		@lezer/lr@1.4.12
		@lezer/markdown@1.8.1
		@lucide/svelte@1.46.0
		@marijn/find-cluster-break@1.0.4
		@mdx-js/react@3.1.1
		@modelcontextprotocol/sdk@1.32.1
		@napi-rs/canvas@0.1.100
		@napi-rs/canvas-linux-arm64-gnu@0.1.100|arm64
		@napi-rs/canvas-linux-arm64-musl@0.1.100|arm64,elibc_musl
		@napi-rs/canvas-linux-x64-gnu@0.1.100|amd64
		@napi-rs/canvas-linux-x64-musl@0.1.100|amd64,elibc_musl
		@napi-rs/wasm-runtime@1.2.7
		@neoconfetti/react@1.0.0
		@oxc-parser/binding-linux-arm64-gnu@0.127.0|arm64
		@oxc-parser/binding-linux-arm64-musl@0.127.0|arm64,elibc_musl
		@oxc-parser/binding-linux-x64-gnu@0.127.0|amd64
		@oxc-parser/binding-linux-x64-musl@0.127.0|amd64,elibc_musl
		@oxc-project/types@0.127.0
		@oxc-project/types@0.156.0
		@oxc-resolver/binding-linux-arm64-gnu@11.21.2|arm64
		@oxc-resolver/binding-linux-arm64-musl@11.21.2|arm64,elibc_musl
		@oxc-resolver/binding-linux-x64-gnu@11.21.2|amd64
		@oxc-resolver/binding-linux-x64-musl@11.21.2|amd64,elibc_musl
		@parcel/watcher@2.6.0
		@parcel/watcher-linux-arm64-glibc@2.6.0|arm64
		@parcel/watcher-linux-arm64-musl@2.6.0|arm64,elibc_musl
		@parcel/watcher-linux-x64-glibc@2.6.0|amd64
		@parcel/watcher-linux-x64-musl@2.6.0|amd64,elibc_musl
		@playwright/test@1.56.1
		@polka/url@1.0.0-next.29
		@quansync/fs@1.1.0
		@rolldown/binding-linux-arm64-gnu@1.2.18|arm64
		@rolldown/binding-linux-arm64-musl@1.2.18|arm64,elibc_musl
		@rolldown/binding-linux-x64-gnu@1.2.18|amd64
		@rolldown/binding-linux-x64-musl@1.2.18|amd64,elibc_musl
		@rolldown/pluginutils@1.1.0
		@standard-schema/spec@1.1.0
		@storybook/addon-a11y@10.6.6
		@storybook/addon-docs@10.6.6
		@storybook/addon-mcp@10.6.6
		@storybook/addon-svelte-csf@5.1.6
		@storybook/addon-vitest@10.6.6
		@storybook/builder-vite@10.6.6
		@storybook/csf@0.1.13
		@storybook/global@5.0.0
		@storybook/icons@2.2.0
		@storybook/react-dom-shim@10.6.6
		@storybook/svelte@10.6.6
		@storybook/svelte-vite@10.6.6
		@storybook/sveltekit@10.6.6
		@sveltejs/acorn-typescript@1.0.13
		@sveltejs/adapter-static@4.0.1
		@sveltejs/kit@3.2.0
		@sveltejs/load-config@0.2.3
		@sveltejs/vite-plugin-svelte@7.3.1
		@swc/helpers@0.5.24
		@tailwindcss/forms@0.5.10
		@tailwindcss/node@4.3.5
		@tailwindcss/oxide@4.3.5
		@tailwindcss/oxide-linux-arm64-gnu@4.3.5|arm64
		@tailwindcss/oxide-linux-arm64-musl@4.3.5|arm64,elibc_musl
		@tailwindcss/oxide-linux-x64-gnu@4.3.5|amd64
		@tailwindcss/oxide-linux-x64-musl@4.3.5|amd64,elibc_musl
		@tailwindcss/oxide-wasm32-wasi@4.3.5
		@tailwindcss/typography@0.5.20
		@tailwindcss/vite@4.3.5
		@testing-library/dom@10.4.2
		@testing-library/jest-dom@6.9.1
		@testing-library/svelte-core@1.1.3
		@testing-library/user-event@14.6.8
		@tmcp/adapter-valibot@0.1.7
		@tmcp/session-manager@0.2.2
		@tmcp/transport-http@0.8.6
		@tybys/wasm-util@0.10.4
		@types/aria-query@5.0.4
		@types/chai@5.2.3
		@types/debug@4.1.13
		@types/deep-eql@4.0.2
		@types/esrecurse@4.3.1
		@types/estree@1.0.10
		@types/hast@3.0.5
		@types/json-schema@7.0.15
		@types/katex@0.16.8
		@types/mdast@4.0.4
		@types/mdx@2.0.14
		@types/ms@2.1.0
		@types/node@24.13.0
		@types/react@19.3.0
		@types/trusted-types@2.0.7
		@types/unist@2.0.11
		@types/unist@3.0.3
		@typescript-eslint/eslint-plugin@8.72.1
		@typescript-eslint/parser@8.72.1
		@typescript-eslint/project-service@8.72.1
		@typescript-eslint/scope-manager@8.72.1
		@typescript-eslint/tsconfig-utils@8.72.1
		@typescript-eslint/type-utils@8.72.1
		@typescript-eslint/types@8.72.1
		@typescript-eslint/typescript-estree@8.72.1
		@typescript-eslint/utils@8.72.1
		@typescript-eslint/visitor-keys@8.72.1
		@ungap/structured-clone@1.4.0
		@valibot/to-json-schema@1.8.0
		@vite-pwa/assets-generator@1.0.4
		@vitest/browser@4.1.12
		@vitest/browser-playwright@4.1.12
		@vitest/coverage-v8@4.1.12
		@vitest/expect@3.2.4
		@vitest/expect@4.1.12
		@vitest/mocker@4.1.12
		@vitest/pretty-format@3.2.4
		@vitest/pretty-format@4.1.12
		@vitest/runner@4.1.12
		@vitest/snapshot@4.1.12
		@vitest/spy@3.2.4
		@vitest/spy@4.1.12
		@vitest/utils@3.2.4
		@vitest/utils@4.1.12
		@webcontainer/env@1.1.1
		accepts@2.0.0
		acorn@8.19.0
		acorn-jsx@5.3.2
		ajv@6.15.0
		ajv@8.20.0
		ajv-formats@3.0.1
		ansi-regex@5.0.1
		ansi-regex@6.6.0
		ansi-styles@4.3.0
		ansi-styles@5.2.0
		aria-query@5.3.0
		aria-query@5.3.1
		assertion-error@2.0.1
		ast-types@0.16.3
		ast-v8-to-istanbul@1.0.8
		async@3.2.6
		axe-core@4.14.0
		axobject-query@4.1.0
		bail@2.0.2
		balanced-match@4.0.4
		basic-auth@2.0.1
		bits-ui@2.18.1
		body-parser@2.4.0
		brace-expansion@5.0.12
		bundle-name@4.1.1
		bytes@3.1.2
		cac@6.7.14
		cacheable@2.5.0
		call-bind-apply-helpers@1.0.2
		call-bound@1.0.4
		ccount@2.0.1
		chai@5.3.3
		chai@6.3.0
		chalk@4.1.2
		character-entities@2.0.2
		character-entities-html4@2.1.0
		character-entities-legacy@3.0.0
		check-error@2.1.3
		chokidar@4.0.3
		chokidar@5.0.0
		chromatic@18.14.2
		clsx@2.1.1
		color-convert@2.0.1
		color-name@1.1.4
		colorette@2.0.20
		comma-separated-tokens@2.0.3
		commander@15.1.0
		consola@3.4.2
		content-disposition@2.0.1
		content-type@1.0.5
		content-type@2.1.0
		convert-source-map@2.0.0
		cookie@1.1.1
		cookie-signature@1.2.2
		cors@2.8.6
		corser@2.0.1
		crelt@1.0.7
		cross-spawn@7.0.6
		css.escape@1.5.1
		cssesc@3.0.0
		csstype@3.2.3
		debug@4.4.3
		decode-bmp@0.2.1
		decode-ico@0.4.1
		decode-named-character-reference@1.3.0
		dedent@1.7.2
		dedent-js@1.0.1
		deep-eql@5.0.2
		deep-is@0.1.4
		deepmerge@4.3.1
		default-browser@5.5.1
		default-browser-id@5.0.1
		define-lazy-prop@3.0.0
		defu@6.1.7
		depd@2.0.0
		dequal@2.0.3
		detect-libc@2.1.2
		devalue@5.9.4
		devlop@1.1.0
		dexie@4.4.3
		dom-accessibility-api@0.5.16
		dom-accessibility-api@0.6.3
		dompurify@3.4.17
		dunder-proto@1.0.1
		ee-first@1.1.1
		encodeurl@2.0.1
		enhanced-resolve@5.26.1
		entities@9.0.0
		es-define-property@1.0.1
		es-errors@1.3.0
		es-module-lexer@2.3.2
		es-object-atoms@1.1.2
		es-toolkit@1.53.2
		esbuild@0.28.2
		escape-html@1.0.3
		escape-string-regexp@4.0.0
		escape-string-regexp@5.0.0
		eslint@10.14.0
		eslint-config-prettier@10.1.8
		eslint-plugin-perfectionist@5.13.0
		eslint-plugin-simple-import-sort@14.0.0
		eslint-plugin-storybook@10.6.6
		eslint-plugin-svelte@3.24.1
		eslint-scope@8.4.0
		eslint-scope@9.1.2
		eslint-visitor-keys@3.4.3
		eslint-visitor-keys@4.2.1
		eslint-visitor-keys@5.0.1
		esm-env@1.2.2
		espree@10.4.0
		espree@11.2.0
		esprima@4.0.1
		esquery@1.7.0
		esrap@1.2.2
		esrap@1.4.9
		esrap@2.4.0
		esrecurse@4.3.0
		estraverse@5.3.0
		estree-walker@3.0.3
		esutils@2.0.3
		etag@1.8.1
		eventemitter3@4.0.7
		eventsource@3.0.7
		eventsource-parser@3.1.1
		expect-type@1.4.0
		express@5.3.0
		express-rate-limit@8.7.3
		extend@3.0.2
		fast-deep-equal@3.1.3
		fast-json-stable-stringify@2.1.0
		fast-levenshtein@2.0.6
		fast-uri@3.1.9
		fdir@6.5.0
		fflate@0.8.3
		file-entry-cache@11.1.5
		finalhandler@2.1.1
		find-up@5.0.0
		flat-cache@6.1.23
		flatted@3.4.4
		follow-redirects@1.16.3
		forwarded@0.2.0
		fresh@2.0.0
		function-bind@1.1.2
		get-intrinsic@1.3.0
		get-proto@1.0.1
		glob-parent@6.0.2
		globals@16.5.0
		gopd@1.2.0
		graceful-fs@4.2.11
		has-flag@4.0.0
		has-symbols@1.1.0
		hashery@1.5.1
		hasown@2.0.4
		hast-util-from-dom@5.0.1
		hast-util-from-html@2.1.0
		hast-util-from-html-isomorphic@2.0.0
		hast-util-from-parse5@8.0.4
		hast-util-parse-selector@4.0.0
		hast-util-sanitize@5.0.2
		hast-util-to-html@9.0.6
		hast-util-to-text@4.0.3
		hast-util-whitespace@3.0.0
		hastscript@9.0.3
		he@1.2.0
		highlight.js@11.11.1
		hono@4.13.17
		hookified@1.15.1
		hookified@2.2.0
		html-encoding-sniffer@6.0.0
		html-escaper@2.0.2
		html-void-elements@3.0.0
		http-errors@2.0.1
		http-proxy@1.18.1
		http-server@14.1.1
		ico-endec@0.1.6
		iconv-lite@0.7.3
		ignore@5.3.2
		ignore@7.0.14
		immutable@5.1.10
		imurmurhash@0.1.4
		indent-string@4.0.0
		inherits@2.0.4
		inline-style-parser@0.2.7
		ip-address@10.7.6
		ipaddr.js@1.9.1
		is-docker@3.0.0
		is-extglob@2.1.1
		is-glob@4.0.3
		is-inside-container@1.0.0
		is-plain-obj@4.1.0
		is-promise@4.0.0
		is-reference@3.0.3
		is-wsl@3.1.1
		isexe@2.0.0
		istanbul-lib-coverage@3.2.2
		istanbul-lib-report@3.0.1
		istanbul-reports@3.2.0
		jiti@2.7.0
		jose@6.2.16
		js-tokens@10.0.0
		js-tokens@4.0.0
		json-rpc-2.0@1.8.1
		json-schema-traverse@0.4.1
		json-schema-traverse@1.0.0
		json-schema-typed@8.0.2
		json-stable-stringify-without-jsonify@1.0.1
		jsonc-parser@3.3.1
		jsonfile@6.2.1
		katex@0.19.0
		keyv@5.6.0
		known-css-properties@0.37.0
		levn@0.4.1
		lightningcss@1.33.0
		lightningcss-linux-arm64-gnu@1.33.0|arm64
		lightningcss-linux-arm64-musl@1.33.0|arm64,elibc_musl
		lightningcss-linux-x64-gnu@1.33.0|amd64
		lightningcss-linux-x64-musl@1.33.0|amd64,elibc_musl
		lilconfig@2.1.0
		locate-character@3.0.0
		locate-path@6.0.0
		longest-streak@3.1.0
		loupe@3.2.1
		lowlight@3.3.0
		lz-string@1.5.0
		magic-string@0.30.21
		magic-string@1.4.5
		magicast@0.5.5
		make-dir@4.0.0
		markdown-table@3.1.0
		math-intrinsics@1.1.0
		mdast-util-find-and-replace@3.0.4
		mdast-util-from-markdown@2.1.0
		mdast-util-gfm@3.1.0
		mdast-util-gfm-autolink-literal@2.1.0
		mdast-util-gfm-footnote@2.1.0
		mdast-util-gfm-strikethrough@2.0.1
		mdast-util-gfm-table@2.0.1
		mdast-util-gfm-task-list-item@2.0.1
		mdast-util-math@3.0.0
		mdast-util-newline-to-break@2.0.0
		mdast-util-phrasing@4.1.0
		mdast-util-to-hast@13.2.1
		mdast-util-to-markdown@2.2.3
		mdast-util-to-string@4.0.0
		mdsvex@0.12.7
		media-typer@1.1.1
		merge-descriptors@2.0.0
		micromark@4.0.3
		micromark-core-commonmark@2.0.4
		micromark-extension-gfm@3.0.0
		micromark-extension-gfm-autolink-literal@2.1.0
		micromark-extension-gfm-footnote@2.1.0
		micromark-extension-gfm-strikethrough@2.1.0
		micromark-extension-gfm-table@2.1.2
		micromark-extension-gfm-tagfilter@2.0.0
		micromark-extension-gfm-task-list-item@2.1.0
		micromark-extension-math@3.1.0
		micromark-factory-destination@2.0.1
		micromark-factory-label@2.0.1
		micromark-factory-space@2.1.0
		micromark-factory-title@2.0.1
		micromark-factory-whitespace@2.0.1
		micromark-util-character@2.1.1
		micromark-util-chunked@2.0.1
		micromark-util-classify-character@2.0.1
		micromark-util-combine-extensions@2.0.1
		micromark-util-decode-numeric-character-reference@2.0.2
		micromark-util-decode-string@2.0.1
		micromark-util-edit-map@1.0.0
		micromark-util-encode@2.0.1
		micromark-util-html-tag-name@2.0.1
		micromark-util-normalize-identifier@2.0.1
		micromark-util-resolve-all@2.0.1
		micromark-util-sanitize-uri@2.0.1
		micromark-util-subtokenize@2.1.0
		micromark-util-symbol@2.0.1
		micromark-util-types@2.0.3
		mime@1.6.0
		mime-db@1.54.0
		mime-types@3.0.2
		min-indent@1.0.1
		mini-svg-data-uri@1.4.4
		minimatch@11.0.5
		minimist@1.2.8
		mode-watcher@1.1.0
		mri@1.2.0
		mrmime@2.0.1
		ms@2.1.3
		nanoid@3.3.20
		natural-compare@1.4.0
		natural-orderby@5.0.0
		negotiator@1.1.0
		node-addon-api@7.1.1
		object-assign@4.1.1
		object-inspect@1.13.4
		obug@2.2.1
		on-finished@2.4.2
		once@1.4.0
		open@10.2.0
		opener@1.5.2
		optionator@0.9.4
		oxc-parser@0.127.0
		oxc-resolver@11.21.2
		p-limit@3.1.0
		p-locate@5.0.0
		parse5@8.1.1
		parseurl@1.3.3
		path-exists@4.0.0
		path-key@3.1.1
		path-to-regexp@8.4.2
		pathe@2.0.3
		pathval@2.0.1
		pdfjs-dist@5.4.54
		pele@1.13.0
		picocolors@1.1.1
		picomatch@4.0.7
		pkce-challenge@5.0.1
		playwright@1.56.1
		playwright-core@1.56.1
		pngjs@7.0.0
		portfinder@1.0.38
		postcss@8.5.32
		postcss-load-config@3.1.4
		postcss-safe-parser@7.1.0
		postcss-scss@4.0.9
		postcss-selector-parser@7.1.6
		prelude-ls@1.2.1
		prettier@3.8.3
		prettier-plugin-svelte@4.1.0
		prettier-plugin-tailwindcss@0.8.0
		pretty-format@27.5.1
		prism-svelte@0.4.7
		prismjs@1.30.0
		property-information@7.2.0
		proxy-addr@2.0.8
		punycode@2.3.1
		qified@0.10.1
		qs@6.17.1
		quansync@1.0.0
		range-parser@1.3.0
		raw-body@3.0.2
		react@19.3.1
		react-dom@19.3.1
		react-is@17.0.2
		readdirp@4.1.2
		readdirp@5.1.1
		recast@0.23.21
		redent@3.0.0
		rehype-highlight@7.0.2
		rehype-katex@7.0.1
		rehype-stringify@10.0.1
		remark@15.0.1
		remark-breaks@4.0.0
		remark-gfm@4.0.1
		remark-html@16.0.1
		remark-math@6.0.0
		remark-parse@11.0.0
		remark-rehype@11.1.2
		remark-stringify@11.0.0
		require-from-string@2.0.2
		requires-port@1.0.0
		rolldown@1.2.18
		router@2.2.0
		run-applescript@7.1.0
		runed@0.23.4
		runed@0.25.0
		runed@0.28.0
		runed@0.35.1
		sade@1.8.1
		safe-buffer@5.1.2
		safer-buffer@2.1.2
		sass@1.100.0
		scheduler@0.28.0
		scule@1.3.0
		secure-compare@3.0.1
		semver@7.8.6
		send@1.2.1
		serve-static@2.2.1
		setprototypeof@1.2.0
		sharp@0.35.5
		sharp-ico@0.1.5
		shebang-command@2.0.0
		shebang-regex@3.0.0
		side-channel@1.1.1
		side-channel-list@1.0.1
		side-channel-map@1.0.1
		side-channel-weakmap@1.0.2
		siginfo@2.0.0
		sirv@3.0.2
		source-map@0.6.1
		source-map-js@1.2.2
		space-separated-tokens@2.0.2
		sqids@0.3.0
		stackback@0.0.2
		statuses@2.0.2
		std-env@4.3.0
		storybook@10.6.6
		stringify-entities@4.0.4
		strip-ansi@7.2.0
		strip-indent@3.0.0
		style-mod@4.1.4
		style-to-object@1.0.14
		supports-color@7.2.0
		svelte@5.57.3
		svelte-ast-print@0.4.2
		svelte-check@4.7.8
		svelte-eslint-parser@1.10.1
		svelte-sonner@1.1.1
		svelte-toolbelt@0.10.7
		svelte-toolbelt@0.7.1
		svelte2tsx@0.7.63
		tabbable@6.5.1
		tagged-tag@1.0.0
		tailwind-merge@3.6.0
		tailwind-variants@3.3.1
		tailwindcss@4.3.5
		tapable@2.3.3
		tiny-invariant@1.3.3
		tinybench@2.9.0
		tinyexec@1.3.1
		tinyglobby@0.2.17
		tinyrainbow@2.0.0
		tinyrainbow@3.2.0
		tinyspy@4.0.6
		tmcp@1.20.1
		to-data-view@1.1.0
		toidentifier@1.0.1
		totalist@3.0.1
		trim-lines@3.0.1
		trough@2.2.0
		ts-api-utils@2.5.0
		ts-dedent@2.3.0
		tslib@2.9.1
		tw-animate-css@1.4.0
		type-check@0.4.0
		type-fest@2.19.0
		type-fest@5.10.0
		type-is@2.1.0
		typescript@5.9.3
		typescript@6.0.3
		typescript-eslint@8.72.1
		unconfig@7.5.0
		unconfig-core@7.5.0
		undici-types@7.18.2
		unified@11.0.5
		union@0.5.0
		unist-util-is@4.1.0
		unist-util-is@6.0.1
		unist-util-position@5.0.0
		unist-util-remove-position@5.0.0
		unist-util-stringify-position@2.0.3
		unist-util-stringify-position@4.0.0
		unist-util-visit@2.0.3
		unist-util-visit@5.1.0
		unist-util-visit-parents@3.1.1
		unist-util-visit-parents@6.1.0
		universalify@2.0.1
		unpipe@1.0.0
		unplugin@2.3.11
		uri-js@4.4.1
		uri-template-matcher@1.1.2
		url-join@4.0.1
		use-sync-external-store@1.7.0
		util-deprecate@1.0.2
		uuid@13.0.2
		uuid@14.0.3
		valibot@1.4.2
		vary@1.1.2
		vaul-svelte@1.0.0-next.7
		vfile@6.0.3
		vfile-location@5.0.4
		vfile-message@2.0.4
		vfile-message@4.0.4
		vite@8.3.6
		vite-plugin-devtools-json@1.1.2
		vitefu@1.1.3
		vitest@4.1.12
		vitest-browser-svelte@2.1.1
		w3c-keyname@2.2.8
		web-namespaces@2.0.1
		webpack-virtual-modules@0.6.2
		which@2.0.2
		why-is-node-running@2.3.0
		word-wrap@1.2.5
		wrappy@1.0.2
		ws@8.22.2
		wsl-utils@0.1.0
		yaml@1.10.3
		yocto-queue@0.1.0
		zimmerframe@1.1.2
		zimmerframe@1.1.5
		zod@4.6.7
		zod-to-json-schema@3.25.2
		zwitch@2.0.4
	"
	NPM_STUB_PKGS="
		@esbuild/aix-ppc64@0.28.2
		@esbuild/android-arm64@0.28.2
		@esbuild/android-arm@0.28.2
		@esbuild/android-x64@0.28.2
		@esbuild/darwin-arm64@0.28.2
		@esbuild/darwin-x64@0.28.2
		@esbuild/freebsd-arm64@0.28.2
		@esbuild/freebsd-x64@0.28.2
		@esbuild/linux-arm@0.28.2
		@esbuild/linux-ia32@0.28.2
		@esbuild/linux-loong64@0.28.2
		@esbuild/linux-mips64el@0.28.2
		@esbuild/linux-ppc64@0.28.2
		@esbuild/linux-riscv64@0.28.2
		@esbuild/linux-s390x@0.28.2
		@esbuild/netbsd-arm64@0.28.2
		@esbuild/netbsd-x64@0.28.2
		@esbuild/openbsd-arm64@0.28.2
		@esbuild/openbsd-x64@0.28.2
		@esbuild/openharmony-arm64@0.28.2
		@esbuild/sunos-x64@0.28.2
		@esbuild/win32-arm64@0.28.2
		@esbuild/win32-ia32@0.28.2
		@esbuild/win32-x64@0.28.2
		@img/sharp-darwin-arm64@0.35.5
		@img/sharp-darwin-x64@0.35.5
		@img/sharp-freebsd-wasm32@0.35.5
		@img/sharp-libvips-darwin-arm64@1.3.4
		@img/sharp-libvips-darwin-x64@1.3.4
		@img/sharp-libvips-linux-arm@1.3.4
		@img/sharp-libvips-linux-ppc64@1.3.4
		@img/sharp-libvips-linux-riscv64@1.3.4
		@img/sharp-libvips-linux-s390x@1.3.4
		@img/sharp-linux-arm@0.35.5
		@img/sharp-linux-ppc64@0.35.5
		@img/sharp-linux-riscv64@0.35.5
		@img/sharp-linux-s390x@0.35.5
		@img/sharp-webcontainers-wasm32@0.35.5
		@img/sharp-win32-arm64@0.35.5
		@img/sharp-win32-ia32@0.35.5
		@img/sharp-win32-x64@0.35.5
		@napi-rs/canvas-android-arm64@0.1.100
		@napi-rs/canvas-darwin-arm64@0.1.100
		@napi-rs/canvas-darwin-x64@0.1.100
		@napi-rs/canvas-linux-arm-gnueabihf@0.1.100
		@napi-rs/canvas-linux-riscv64-gnu@0.1.100
		@napi-rs/canvas-win32-arm64-msvc@0.1.100
		@napi-rs/canvas-win32-x64-msvc@0.1.100
		@oxc-parser/binding-android-arm-eabi@0.127.0
		@oxc-parser/binding-android-arm64@0.127.0
		@oxc-parser/binding-darwin-arm64@0.127.0
		@oxc-parser/binding-darwin-x64@0.127.0
		@oxc-parser/binding-freebsd-x64@0.127.0
		@oxc-parser/binding-linux-arm-gnueabihf@0.127.0
		@oxc-parser/binding-linux-arm-musleabihf@0.127.0
		@oxc-parser/binding-linux-ppc64-gnu@0.127.0
		@oxc-parser/binding-linux-riscv64-gnu@0.127.0
		@oxc-parser/binding-linux-riscv64-musl@0.127.0
		@oxc-parser/binding-linux-s390x-gnu@0.127.0
		@oxc-parser/binding-openharmony-arm64@0.127.0
		@oxc-parser/binding-wasm32-wasi@0.127.0
		@oxc-parser/binding-win32-arm64-msvc@0.127.0
		@oxc-parser/binding-win32-ia32-msvc@0.127.0
		@oxc-parser/binding-win32-x64-msvc@0.127.0
		@oxc-resolver/binding-android-arm-eabi@11.21.2
		@oxc-resolver/binding-android-arm64@11.21.2
		@oxc-resolver/binding-darwin-arm64@11.21.2
		@oxc-resolver/binding-darwin-x64@11.21.2
		@oxc-resolver/binding-freebsd-x64@11.21.2
		@oxc-resolver/binding-linux-arm-gnueabihf@11.21.2
		@oxc-resolver/binding-linux-arm-musleabihf@11.21.2
		@oxc-resolver/binding-linux-ppc64-gnu@11.21.2
		@oxc-resolver/binding-linux-riscv64-gnu@11.21.2
		@oxc-resolver/binding-linux-riscv64-musl@11.21.2
		@oxc-resolver/binding-linux-s390x-gnu@11.21.2
		@oxc-resolver/binding-openharmony-arm64@11.21.2
		@oxc-resolver/binding-wasm32-wasi@11.21.2
		@oxc-resolver/binding-win32-arm64-msvc@11.21.2
		@oxc-resolver/binding-win32-x64-msvc@11.21.2
		@parcel/watcher-android-arm64@2.6.0
		@parcel/watcher-darwin-arm64@2.6.0
		@parcel/watcher-darwin-x64@2.6.0
		@parcel/watcher-freebsd-x64@2.6.0
		@parcel/watcher-linux-arm-glibc@2.6.0
		@parcel/watcher-linux-arm-musl@2.6.0
		@parcel/watcher-win32-arm64@2.6.0
		@parcel/watcher-win32-x64@2.6.0
		@rolldown/binding-android-arm-eabi@1.2.18
		@rolldown/binding-android-arm64@1.2.18
		@rolldown/binding-darwin-arm64@1.2.18
		@rolldown/binding-darwin-x64@1.2.18
		@rolldown/binding-freebsd-x64@1.2.18
		@rolldown/binding-linux-arm-gnueabihf@1.2.18
		@rolldown/binding-linux-ppc64-gnu@1.2.18
		@rolldown/binding-linux-s390x-gnu@1.2.18
		@rolldown/binding-openharmony-arm64@1.2.18
		@rolldown/binding-win32-arm64-msvc@1.2.18
		@rolldown/binding-win32-x64-msvc@1.2.18
		@tailwindcss/oxide-android-arm64@4.3.5
		@tailwindcss/oxide-darwin-arm64@4.3.5
		@tailwindcss/oxide-darwin-x64@4.3.5
		@tailwindcss/oxide-freebsd-x64@4.3.5
		@tailwindcss/oxide-linux-arm-gnueabihf@4.3.5
		@tailwindcss/oxide-win32-arm64-msvc@4.3.5
		@tailwindcss/oxide-win32-x64-msvc@4.3.5
		fsevents@2.3.2
		fsevents@2.3.3
		lightningcss-android-arm64@1.33.0
		lightningcss-darwin-arm64@1.33.0
		lightningcss-darwin-x64@1.33.0
		lightningcss-freebsd-x64@1.33.0
		lightningcss-linux-arm-gnueabihf@1.33.0
		lightningcss-win32-arm64-msvc@1.33.0
		lightningcss-win32-x64-msvc@1.33.0
	"
	NPM_NATIVE_DEPEND="
		dev-util/lightningcss:1.33.0
		dev-util/oxc-parser:0.127.0
		dev-util/oxc-resolver:11.21.2
		dev-util/rolldown:1.2.18
		dev-util/tailwindcss-oxide:4.3.5
	"
	XDNA_COMMIT="fade39f670ae40af184a529e61c8eaa7b799c3b2"
fi

inherit cmake cuda flag-o-matic linux-info npm rocm toolchain-funcs
[[ ${PV} == 9999 ]] && inherit git-r3

UI_DIR=ui/apps/chat

DESCRIPTION="Port of Facebook's LLaMA model in C/C++, with its web UI"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"
if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/ggml-org/llama.cpp.git"
else
	SRC_URI="
		https://github.com/ggml-org/llama.cpp/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz
		xdna? (
			https://github.com/FireBurn/ggml-xdna1/archive/${XDNA_COMMIT}.tar.gz
				-> ggml-xdna1-${XDNA_COMMIT:0:10}.gh.tar.gz
		)
		webui? (
			${NPM_PKG_URIS}
		)
	"
	S="${WORKDIR}/llama.cpp-${PV}"
fi

LICENSE="MIT"
# Web UI npm package licenses
LICENSE+=" 0BSD Apache-2.0 BSD BSD-2 CC0-1.0 ISC MIT MPL-2.0 Unlicense"
SLOT="0"
KEYWORDS="~amd64"
IUSE="curl openblas +openmp blis hip cuda opencl vulkan xdna +webui"
RESTRICT="mirror"

BDEPEND="
	webui? (
		${NPM_NODE_DEPEND}
		${NPM_NATIVE_DEPEND}
		media-libs/vips
	)
	virtual/pkgconfig
"

CDEPEND="
	curl? ( net-misc/curl:= )
	openblas? ( sci-libs/openblas:= )
	openmp? ( llvm-runtimes/openmp:= )
	blis? ( sci-libs/blis:= )
	hip? ( >=dev-util/hip-10.0:= >=sci-libs/hipBLAS-10.0:= )
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
"
DEPEND="${CDEPEND}
	opencl? ( dev-util/opencl-headers )
	vulkan? ( dev-util/vulkan-headers )
"
RDEPEND="${CDEPEND}
	dev-python/numpy
	opencl? ( dev-libs/opencl-icd-loader )
	vulkan? ( media-libs/vulkan-loader )
"

PATCHES=(
	"${FILESDIR}/0001-vulkan-handle-IQ4_XS-mat-vec-with-more-than-2-column.patch"
	"${FILESDIR}/0002-vulkan-share-the-K-V-pass-between-query-rows-in-coop.patch"
	"${FILESDIR}/0003-qwen35-optional-reduced-vocab-LM-head-for-MTP-drafti.patch"
	"${FILESDIR}/0004-vulkan-use-4-rows-for-legacy-quant-mat-vec-from-2-co.patch"
	"${FILESDIR}/0006-server-keep-speculative-checkpoints-on-device.patch"
	"${FILESDIR}/0007-hip-keep-MMQ-WMMA-k-loops-rolled-to-avoid-VGPR-spill.patch"
	"${FILESDIR}/0009-hip-share-the-FA-vec-K-V-pass-between-the-Q-heads-of.patch"
	"${FILESDIR}/0010-vulkan-write-gated-delta-net-state-straight-into-the.patch"
	"${FILESDIR}/0011-vulkan-keep-the-rms_norm-row-in-registers-for-the-.patch"
	"${FILESDIR}/0012-vulkan-dual-issue-friendly-int8-epilogue-in-cm1-mmq-.patch"
	"${FILESDIR}/0014-vulkan-store-the-flash-attention-quantized-K-V-scrat.patch"
	"${FILESDIR}/0016-vulkan-load-16-values-per-thread-for-q4_K-q5_K-q6_K-.patch"
	"${FILESDIR}/0017-vulkan-stage-large-writes-to-host-visible-VRAM-throu.patch"
	"${FILESDIR}/0018-vulkan-index-iq4-mxfp4-codebooks-as-a-constant-array.patch"
	"${FILESDIR}/0019-vulkan-use-the-float-mat-vec-for-single-tokens-with-.patch"
	"${FILESDIR}/0020-vulkan-hoist-loop-invariants-in-the-Q4_K-and-Q5_K-in.patch"
	"${FILESDIR}/0021-vulkan-keep-P-transposed-in-shared-memory-for-the-co.patch"
	"${FILESDIR}/0022-hip-allow-host-constexpr-use-of-physical-warp-size.patch"
)

pkg_setup() {
	if use hip || use xdna; then
		linux-info_pkg_setup
	fi
	if use hip && linux-info_get_any_version && linux_config_exists; then
		linux_chkconfig_present HSA_AMD_SVM ||
			ewarn "ROCm/HIP requires CONFIG_HSA_AMD_SVM in the kernel."
	fi
	if use xdna; then
		if linux-info_get_any_version && linux_config_exists; then
			if ! linux_chkconfig_present DRM_AMDXDNA; then
				ewarn "To use the XDNA1 backend, you likely need the AMD XDNA DRM driver enabled"
				ewarn "(CONFIG_DRM_AMDXDNA) or built out-of-tree."
			fi
		fi
	fi
}

src_unpack() {
	if [[ ${PV} == 9999 ]]; then
		git-r3_src_unpack
		if use xdna; then
			local xdna_uri="https://github.com/FireBurn/ggml-xdna1.git"
			git-r3_fetch "${xdna_uri}"
			git-r3_checkout "${xdna_uri}" "${WORKDIR}/ggml-xdna1"
		fi

		# A live ebuild may use the network here; the build then runs offline
		pushd "${S}/${UI_DIR}" >/dev/null || die
		HOME="${T}/npm-home" npm ci --ignore-scripts --no-audit --no-fund \
			--cache "${T}/npm-cache" || die "npm ci failed"
		popd >/dev/null || die
	else
		if use webui; then
			npm_src_unpack
		else
			default
		fi
		if use xdna; then
			mv "${WORKDIR}/ggml-xdna1-${XDNA_COMMIT}" "${WORKDIR}/ggml-xdna1" || die
		fi
	fi
}

src_prepare() {
	use cuda && cuda_src_prepare

	if use xdna; then
		# Fix hardcoded library installation path to match llama.cpp's isolation
		# so `libggml-xdna1.so` ends up in `/usr/$(get_libdir)/llama.cpp/` instead of `/usr/lib/`
		sed -i -e "s|DESTINATION lib|DESTINATION $(get_libdir)/llama.cpp|g" \
			"${WORKDIR}/ggml-xdna1/CMakeLists.txt" || die

		# ggml added alloc_buffer_n and get_alloc_size_n to the buffer type
		# interface; the backend's positional initialiser predates them.
		if ! grep -q 'alloc_buffer_n' "${WORKDIR}/ggml-xdna1/src/ggml-xdna1.cpp"; then
			sed -i \
				-e '/\/\* \.alloc_buffer   = \*\/ xdna1_buft_alloc,/a\        /* .alloc_buffer_n   = */ NULL,' \
				-e '/\/\* \.get_alloc_size = \*\/ NULL,/a\        /* .get_alloc_size_n = */ NULL,' \
				"${WORKDIR}/ggml-xdna1/src/ggml-xdna1.cpp" || die
		fi
	fi

	cmake_src_prepare
}

src_configure() {
	# the Gentoo build type does not define it, and the asserts slow inference
	append-cppflags -DNDEBUG

	if use webui; then
		# Force enable the Web UI macros
		append-cppflags -DLLAMA_BUILD_UI=1 -DLLAMA_BUILD_WEBUI=1
	fi

	local mycmakeargs=(
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_BUILD_UI=$(usex webui ON OFF)
		# Point CMake to the directory where we will build the UI assets
		-DUI_SOURCE_DIR="${S}/${UI_DIR}"
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
		-DGGML_NATIVE=0
		-DGGML_RPC=ON
		-DLLAMA_CURL=$(usex curl ON OFF)
		-DBUILD_NUMBER="1"
		-DGGML_CUDA=$(usex cuda ON OFF)
		-DGGML_OPENCL=$(usex opencl ON OFF)
		-DGGML_OPENMP=$(usex openmp ON OFF)
		-DGGML_VULKAN=$(usex vulkan ON OFF)

		# avoid clashing with whisper.cpp
		-DCMAKE_INSTALL_LIBDIR="${EPREFIX}/usr/$(get_libdir)/llama.cpp"
		-DCMAKE_INSTALL_RPATH="${EPREFIX}/usr/$(get_libdir)/llama.cpp"
	)

	if use openblas ; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS )
	fi

	if use blis ; then
		mycmakeargs+=( -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=FLAME )
	fi

	if use hip; then
		# rocm_use_hipcc replaces CC and CXX, and the web UI's native
		# addon needs the host's
		_LLAMA_HOST_CC=$(tc-getCC)
		_LLAMA_HOST_CXX=$(tc-getCXX)
		rocm_use_hipcc
		mycmakeargs+=( -DGGML_HIP=ON -DAMDGPU_TARGETS="$(get_amdgpu_flags)" )
	fi

	if use cuda; then
		local -x CUDAHOSTCXX="$(cuda_gccdir)"
		cuda_add_sandbox
		addpredict "/dev/char/"
	fi

	# Configure llama.cpp
	local CMAKE_USE_DIR="${S}"
	local BUILD_DIR="${WORKDIR}/${P}_build"
	cmake_src_configure

	# Configure ggml-xdna1
	if use xdna; then
		einfo "Configuring ggml-xdna1 backend..."
		local CMAKE_USE_DIR="${WORKDIR}/ggml-xdna1"
		local BUILD_DIR="${WORKDIR}/ggml-xdna1_build"
		local mycmakeargs=(
			-DGGML_SOURCE_DIR="${S}/ggml"
			-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		)
		cmake_src_configure
	fi
}

# sharp's prebuilt libvips needs libstdc++ and glibc, so it is built against
# the system's
_llama_build_sharp() {
	local npm_modules="${BROOT}/usr/$(get_libdir)/node_modules/npm/node_modules"
	[[ -d ${npm_modules} ]] || npm_modules="${BROOT}/usr/lib/node_modules/npm/node_modules"

	# The addon runs under Node on this machine, so it takes the host's
	# compilers, not the hipcc that rocm_use_hipcc left in CC and CXX.
	local -x CC=${_LLAMA_HOST_CC:-$(tc-getCC)} CXX=${_LLAMA_HOST_CXX:-$(tc-getCXX)}
	local -x CFLAGS="-O2 -pipe" CXXFLAGS="-O2 -pipe"

	pushd node_modules/sharp >/dev/null || die
	# npm.eclass exports SHARP_IGNORE_GLOBAL_LIBVIPS, which would win over
	# the request for the system's.  npm_config_libc would make the build
	# name the addon for the glibc platform while the loader looks for the
	# plain linux one, so unset it.
	env -u SHARP_IGNORE_GLOBAL_LIBVIPS -u npm_config_libc \
		HOME="${T}/npm-home" SHARP_FORCE_GLOBAL_LIBVIPS=1 \
		npm_config_nodedir="${BROOT}/usr" NODE_PATH="${npm_modules}" \
		npm run build || die "Failed to build sharp"
	popd >/dev/null || die
}

src_compile() {
	if use webui; then
		# 1. Build the Web UI assets from source
		einfo "Building Web UI assets using npm..."
		pushd "${S}/${UI_DIR}" > /dev/null || die

		# Releases install the UI's dependencies from the offline registry
		if [[ ${PV} != 9999 ]]; then
			npm_with_registry npm ci --ignore-scripts
		fi
		_llama_build_sharp
		# Generates the dist/ directory CMake embeds
		HOME="${T}/npm-home" npm run build --offline || die

		popd > /dev/null || die
	fi

	# 2. Run the standard C++ build for llama.cpp
	local CMAKE_USE_DIR="${S}"
	local BUILD_DIR="${WORKDIR}/${P}_build"
	cmake_src_compile

	# 3. Build ggml-xdna1
	if use xdna; then
		einfo "Building ggml-xdna1 backend..."
		local CMAKE_USE_DIR="${WORKDIR}/ggml-xdna1"
		local BUILD_DIR="${WORKDIR}/ggml-xdna1_build"
		cmake_src_compile
	fi
}

src_install() {
	# 1. Install llama.cpp
	local CMAKE_USE_DIR="${S}"
	local BUILD_DIR="${WORKDIR}/${P}_build"
	cmake_src_install
	dobin "${BUILD_DIR}/bin/ggml-rpc-server"

	# 2. Install ggml-xdna1
	if use xdna; then
		einfo "Installing ggml-xdna1 backend..."
		local CMAKE_USE_DIR="${WORKDIR}/ggml-xdna1"
		local BUILD_DIR="${WORKDIR}/ggml-xdna1_build"
		cmake_src_install
	fi
}

pkg_postinst() {
	if use xdna; then
		elog ""
		elog "You have installed the AMD Ryzen AI NPU backend (ggml-xdna1)."
		elog "Requirements for hardware offloading:"
		elog "  1. You must load the 'amdxdna' Linux DRM driver."
		elog "  2. You must raise RLIMIT_MEMLOCK (e.g. ulimit -l unlimited or via pam_limits)."
		elog "     Without this, the device heap allocation will fail with EAGAIN."
		elog "  3. Use '--device XDNA1 -ngl 0' to run models on the NPU."
		elog "  4. Set 'export GGML_BACKEND_PATH=/usr/$(get_libdir)/llama.cpp/libggml-xdna1.so'"
		elog "     so the plugin is properly dynamically loaded by llama-cli or llama-server."
		elog ""
	fi
}
