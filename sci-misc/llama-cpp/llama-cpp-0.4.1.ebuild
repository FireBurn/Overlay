# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION="10.0"

if [[ ${PV} == 9999 ]]; then
	# The web UI's npm dependencies change with every commit, so the live
	# ebuild installs them from the checked-out lockfile in src_unpack
	NPM_PKGS=""
else
	# Generated from tools/ui/package-lock.json by scripts/npm-deps.py
	NPM_PKGS="
		@adobe/css-tools@4.5.0
		@ampproject/remapping@2.3.0
		@antfu/install-pkg@1.1.0
		@apideck/better-ajv-errors@0.3.7
		@babel/code-frame@7.29.7
		@babel/compat-data@7.29.7
		@babel/core@7.29.7
		@babel/generator@7.29.7
		@babel/helper-annotate-as-pure@7.29.7
		@babel/helper-compilation-targets@7.29.7
		@babel/helper-create-class-features-plugin@7.29.7
		@babel/helper-create-regexp-features-plugin@7.29.7
		@babel/helper-define-polyfill-provider@0.6.8
		@babel/helper-globals@7.29.7
		@babel/helper-member-expression-to-functions@7.29.7
		@babel/helper-module-imports@7.29.7
		@babel/helper-module-transforms@7.29.7
		@babel/helper-optimise-call-expression@7.29.7
		@babel/helper-plugin-utils@7.29.7
		@babel/helper-remap-async-to-generator@7.29.7
		@babel/helper-replace-supers@7.29.7
		@babel/helper-skip-transparent-expression-wrappers@7.29.7
		@babel/helper-string-parser@7.29.7
		@babel/helper-validator-identifier@7.29.7
		@babel/helper-validator-option@7.29.7
		@babel/helper-wrap-function@7.29.7
		@babel/helpers@7.29.7
		@babel/parser@7.29.7
		@babel/plugin-bugfix-firefox-class-in-computed-class-key@7.29.7
		@babel/plugin-bugfix-safari-class-field-initializer-scope@7.29.7
		@babel/plugin-bugfix-safari-id-destructuring-collision-in-function-expression@7.29.7
		@babel/plugin-bugfix-safari-rest-destructuring-rhs-array@7.29.7
		@babel/plugin-bugfix-v8-spread-parameters-in-optional-chaining@7.29.7
		@babel/plugin-bugfix-v8-static-class-fields-redefine-readonly@7.29.7
		@babel/plugin-proposal-private-property-in-object@7.21.0-placeholder-for-preset-env.2
		@babel/plugin-syntax-import-assertions@7.29.7
		@babel/plugin-syntax-import-attributes@7.29.7
		@babel/plugin-syntax-unicode-sets-regex@7.18.6
		@babel/plugin-transform-arrow-functions@7.29.7
		@babel/plugin-transform-async-generator-functions@7.29.7
		@babel/plugin-transform-async-to-generator@7.29.7
		@babel/plugin-transform-block-scoped-functions@7.29.7
		@babel/plugin-transform-block-scoping@7.29.7
		@babel/plugin-transform-class-properties@7.29.7
		@babel/plugin-transform-class-static-block@7.29.7
		@babel/plugin-transform-classes@7.29.7
		@babel/plugin-transform-computed-properties@7.29.7
		@babel/plugin-transform-destructuring@7.29.7
		@babel/plugin-transform-dotall-regex@7.29.7
		@babel/plugin-transform-duplicate-keys@7.29.7
		@babel/plugin-transform-duplicate-named-capturing-groups-regex@7.29.7
		@babel/plugin-transform-dynamic-import@7.29.7
		@babel/plugin-transform-explicit-resource-management@7.29.7
		@babel/plugin-transform-exponentiation-operator@7.29.7
		@babel/plugin-transform-export-namespace-from@7.29.7
		@babel/plugin-transform-for-of@7.29.7
		@babel/plugin-transform-function-name@7.29.7
		@babel/plugin-transform-json-strings@7.29.7
		@babel/plugin-transform-literals@7.29.7
		@babel/plugin-transform-logical-assignment-operators@7.29.7
		@babel/plugin-transform-member-expression-literals@7.29.7
		@babel/plugin-transform-modules-amd@7.29.7
		@babel/plugin-transform-modules-commonjs@7.29.7
		@babel/plugin-transform-modules-systemjs@7.29.7
		@babel/plugin-transform-modules-umd@7.29.7
		@babel/plugin-transform-named-capturing-groups-regex@7.29.7
		@babel/plugin-transform-new-target@7.29.7
		@babel/plugin-transform-nullish-coalescing-operator@7.29.7
		@babel/plugin-transform-numeric-separator@7.29.7
		@babel/plugin-transform-object-rest-spread@7.29.7
		@babel/plugin-transform-object-super@7.29.7
		@babel/plugin-transform-optional-catch-binding@7.29.7
		@babel/plugin-transform-optional-chaining@7.29.7
		@babel/plugin-transform-parameters@7.29.7
		@babel/plugin-transform-private-methods@7.29.7
		@babel/plugin-transform-private-property-in-object@7.29.7
		@babel/plugin-transform-property-literals@7.29.7
		@babel/plugin-transform-regenerator@7.29.7
		@babel/plugin-transform-regexp-modifiers@7.29.7
		@babel/plugin-transform-reserved-words@7.29.7
		@babel/plugin-transform-shorthand-properties@7.29.7
		@babel/plugin-transform-spread@7.29.7
		@babel/plugin-transform-sticky-regex@7.29.7
		@babel/plugin-transform-template-literals@7.29.7
		@babel/plugin-transform-typeof-symbol@7.29.7
		@babel/plugin-transform-unicode-escapes@7.29.7
		@babel/plugin-transform-unicode-property-regex@7.29.7
		@babel/plugin-transform-unicode-regex@7.29.7
		@babel/plugin-transform-unicode-sets-regex@7.29.7
		@babel/preset-env@7.29.7
		@babel/preset-modules@0.1.6-no-external-plugins
		@babel/runtime@7.29.7
		@babel/template@7.29.7
		@babel/traverse@7.29.7
		@babel/types@7.29.7
		@bcoe/v8-coverage@1.0.2
		@blazediff/core@1.9.1
		@braintree/sanitize-url@7.1.2
		@canvas/image-data@1.1.0
		@chevrotain/types@11.1.2
		@chromatic-com/storybook@5.2.1
		@emnapi/core@1.10.0
		@emnapi/core@1.9.2
		@emnapi/runtime@1.10.0
		@emnapi/runtime@1.11.3
		@emnapi/runtime@1.9.2
		@emnapi/wasi-threads@1.2.1
		@esbuild/linux-arm64@0.28.1|arm64
		@esbuild/linux-x64@0.28.1|amd64
		@eslint-community/eslint-utils@4.9.1
		@eslint-community/regexpp@4.12.2
		@eslint/compat@1.4.1
		@eslint/config-array@0.21.2
		@eslint/config-helpers@0.4.2
		@eslint/core@0.17.0
		@eslint/eslintrc@3.3.5
		@eslint/js@9.39.2
		@eslint/js@9.39.4
		@eslint/object-schema@2.1.7
		@eslint/plugin-kit@0.4.1
		@floating-ui/core@1.7.5
		@floating-ui/dom@1.7.6
		@floating-ui/utils@0.2.11
		@hono/node-server@2.1.0
		@humanfs/core@0.19.2
		@humanfs/node@0.16.8
		@humanfs/types@0.15.0
		@humanwhocodes/module-importer@1.0.1
		@humanwhocodes/retry@0.4.3
		@iconify/types@2.0.0
		@iconify/utils@3.1.3
		@img/colour@1.1.0
		@img/sharp-libvips-linux-arm64@1.3.2|arm64
		@img/sharp-libvips-linux-x64@1.3.2|amd64
		@img/sharp-libvips-linuxmusl-arm64@1.3.2|arm64
		@img/sharp-libvips-linuxmusl-x64@1.3.2|amd64
		@img/sharp-linux-arm64@0.35.3|arm64
		@img/sharp-linux-x64@0.35.3|amd64
		@img/sharp-linuxmusl-arm64@0.35.3|arm64
		@img/sharp-linuxmusl-x64@0.35.3|amd64
		@img/sharp-wasm32@0.35.3
		@internationalized/date@3.12.2
		@isaacs/cliui@9.0.0
		@isaacs/fs-minipass@4.0.1
		@jridgewell/gen-mapping@0.3.13
		@jridgewell/remapping@2.3.5
		@jridgewell/resolve-uri@3.1.2
		@jridgewell/source-map@0.3.11
		@jridgewell/sourcemap-codec@1.5.5
		@jridgewell/trace-mapping@0.3.31
		@lucide/svelte@1.25.0
		@mdx-js/react@3.1.1
		@mermaid-js/parser@1.1.1
		@modelcontextprotocol/sdk@1.30.0
		@napi-rs/canvas@0.1.100
		@napi-rs/canvas-linux-arm64-gnu@0.1.100|arm64
		@napi-rs/canvas-linux-arm64-musl@0.1.100|arm64
		@napi-rs/canvas-linux-x64-gnu@0.1.100|amd64
		@napi-rs/canvas-linux-x64-musl@0.1.100|amd64
		@napi-rs/wasm-runtime@1.1.4
		@neoconfetti/react@1.0.0
		@oxc-parser/binding-linux-arm64-gnu@0.127.0|arm64
		@oxc-parser/binding-linux-arm64-musl@0.127.0|arm64
		@oxc-parser/binding-linux-x64-gnu@0.127.0|amd64
		@oxc-parser/binding-linux-x64-musl@0.127.0|amd64
		@oxc-project/types@0.127.0
		@oxc-resolver/binding-linux-arm64-gnu@11.20.0|arm64
		@oxc-resolver/binding-linux-arm64-musl@11.20.0|arm64
		@oxc-resolver/binding-linux-x64-gnu@11.20.0|amd64
		@oxc-resolver/binding-linux-x64-musl@11.20.0|amd64
		@parcel/watcher@2.5.6
		@parcel/watcher-linux-arm64-glibc@2.5.6|arm64
		@parcel/watcher-linux-arm64-musl@2.5.6|arm64
		@parcel/watcher-linux-x64-glibc@2.5.6|amd64
		@parcel/watcher-linux-x64-musl@2.5.6|amd64
		@playwright/test@1.56.1
		@polka/url@1.0.0-next.29
		@quansync/fs@1.0.0
		@rollup/plugin-babel@6.1.0
		@rollup/plugin-node-resolve@16.0.3
		@rollup/plugin-replace@6.0.3
		@rollup/plugin-terser@1.0.0
		@rollup/pluginutils@5.4.0
		@rollup/rollup-linux-arm64-gnu@4.61.1|arm64
		@rollup/rollup-linux-arm64-musl@4.61.1|arm64
		@rollup/rollup-linux-x64-gnu@4.61.1|amd64
		@rollup/rollup-linux-x64-musl@4.61.1|amd64
		@standard-schema/spec@1.1.0
		@storybook/addon-a11y@10.5.6
		@storybook/addon-docs@10.5.6
		@storybook/addon-mcp@0.7.0
		@storybook/addon-svelte-csf@5.1.2
		@storybook/addon-vitest@10.5.6
		@storybook/builder-vite@10.5.6
		@storybook/csf@0.1.13
		@storybook/csf-plugin@10.5.6
		@storybook/global@5.0.0
		@storybook/icons@2.0.2
		@storybook/mcp@0.8.0
		@storybook/react-dom-shim@10.5.6
		@storybook/svelte@10.5.6
		@storybook/svelte-vite@10.5.6
		@storybook/sveltekit@10.5.6
		@sveltejs/acorn-typescript@1.0.10
		@sveltejs/adapter-static@3.0.10
		@sveltejs/kit@2.70.2
		@sveltejs/load-config@0.1.1
		@sveltejs/vite-plugin-svelte@6.2.1
		@sveltejs/vite-plugin-svelte-inspector@5.0.2
		@swc/helpers@0.5.23
		@tailwindcss/forms@0.5.10
		@tailwindcss/node@4.1.11
		@tailwindcss/oxide@4.1.11
		@tailwindcss/oxide-linux-arm64-gnu@4.1.11|arm64
		@tailwindcss/oxide-linux-arm64-musl@4.1.11|arm64
		@tailwindcss/oxide-linux-x64-gnu@4.1.11|amd64
		@tailwindcss/oxide-linux-x64-musl@4.1.11|amd64
		@tailwindcss/typography@0.5.16
		@tailwindcss/vite@4.1.11
		@testing-library/dom@10.4.1
		@testing-library/jest-dom@6.9.1
		@testing-library/svelte-core@1.0.0
		@testing-library/user-event@14.6.1
		@tmcp/adapter-valibot@0.1.6
		@tmcp/session-manager@0.2.2
		@tmcp/transport-http@0.8.6
		@trickfilm400/rollup-plugin-off-main-thread@3.0.0-pre1
		@tybys/wasm-util@0.10.2
		@types/aria-query@5.0.4
		@types/chai@5.2.3
		@types/cookie@0.6.0
		@types/d3@7.4.3
		@types/d3-array@3.2.2
		@types/d3-axis@3.0.6
		@types/d3-brush@3.0.6
		@types/d3-chord@3.0.6
		@types/d3-color@3.1.3
		@types/d3-contour@3.0.6
		@types/d3-delaunay@6.0.4
		@types/d3-dispatch@3.0.7
		@types/d3-drag@3.0.7
		@types/d3-dsv@3.0.7
		@types/d3-ease@3.0.2
		@types/d3-fetch@3.0.7
		@types/d3-force@3.0.10
		@types/d3-format@3.0.4
		@types/d3-geo@3.1.0
		@types/d3-hierarchy@3.1.7
		@types/d3-interpolate@3.0.4
		@types/d3-path@3.1.1
		@types/d3-polygon@3.0.2
		@types/d3-quadtree@3.0.6
		@types/d3-random@3.0.3
		@types/d3-scale@4.0.9
		@types/d3-scale-chromatic@3.1.0
		@types/d3-selection@3.0.11
		@types/d3-shape@3.1.8
		@types/d3-time@3.0.4
		@types/d3-time-format@4.0.3
		@types/d3-timer@3.0.2
		@types/d3-transition@3.0.9
		@types/d3-zoom@3.0.8
		@types/debug@4.1.13
		@types/deep-eql@4.0.2
		@types/estree@1.0.9
		@types/geojson@7946.0.16
		@types/hast@3.0.4
		@types/json-schema@7.0.15
		@types/katex@0.16.8
		@types/mdast@4.0.4
		@types/mdx@2.0.13
		@types/ms@2.1.0
		@types/node@24.13.0
		@types/react@19.2.17
		@types/resolve@1.20.2
		@types/trusted-types@2.0.7
		@types/unist@2.0.11
		@types/unist@3.0.3
		@typescript-eslint/eslint-plugin@8.60.1
		@typescript-eslint/parser@8.60.1
		@typescript-eslint/project-service@8.60.1
		@typescript-eslint/project-service@8.66.0
		@typescript-eslint/scope-manager@8.60.1
		@typescript-eslint/scope-manager@8.66.0
		@typescript-eslint/tsconfig-utils@8.60.1
		@typescript-eslint/tsconfig-utils@8.66.0
		@typescript-eslint/type-utils@8.60.1
		@typescript-eslint/types@8.60.1
		@typescript-eslint/types@8.66.0
		@typescript-eslint/typescript-estree@8.60.1
		@typescript-eslint/typescript-estree@8.66.0
		@typescript-eslint/utils@8.60.1
		@typescript-eslint/utils@8.66.0
		@typescript-eslint/visitor-keys@8.60.1
		@typescript-eslint/visitor-keys@8.66.0
		@ungap/structured-clone@1.3.1
		@upsetjs/venn.js@2.0.0
		@valibot/to-json-schema@1.7.1
		@vite-pwa/assets-generator@1.0.2
		@vite-pwa/sveltekit@1.1.0
		@vitest/browser@4.1.10
		@vitest/browser-playwright@4.1.10
		@vitest/coverage-v8@4.1.10
		@vitest/expect@3.2.4
		@vitest/expect@4.1.10
		@vitest/mocker@4.1.10
		@vitest/pretty-format@3.2.4
		@vitest/pretty-format@4.1.10
		@vitest/runner@4.1.10
		@vitest/snapshot@4.1.10
		@vitest/spy@3.2.4
		@vitest/spy@4.1.10
		@vitest/utils@3.2.4
		@vitest/utils@4.1.10
		@webcontainer/env@1.1.1
		accepts@2.0.0
		acorn@8.16.0
		acorn-jsx@5.3.2
		ajv@6.15.0
		ajv@8.20.0
		ajv-formats@3.0.1
		ansi-regex@5.0.1
		ansi-regex@6.2.2
		ansi-styles@4.3.0
		ansi-styles@5.2.0
		argparse@2.0.1
		aria-query@5.3.0
		aria-query@5.3.1
		array-buffer-byte-length@1.0.2
		arraybuffer.prototype.slice@1.0.4
		assertion-error@2.0.1
		ast-types@0.16.1
		ast-v8-to-istanbul@1.0.3
		async@3.2.6
		async-function@1.0.0
		at-least-node@1.0.0
		available-typed-arrays@1.0.7
		axe-core@4.12.0
		axobject-query@4.1.0
		babel-plugin-polyfill-corejs2@0.4.17
		babel-plugin-polyfill-corejs3@0.14.2
		babel-plugin-polyfill-regenerator@0.6.8
		bail@2.0.2
		balanced-match@1.0.2
		balanced-match@4.0.4
		baseline-browser-mapping@2.10.33
		basic-auth@2.0.1
		bits-ui@2.18.1
		body-parser@2.3.0
		brace-expansion@1.1.18
		brace-expansion@2.1.4
		brace-expansion@5.0.9
		browserslist@4.28.2
		buffer-from@1.1.2
		bundle-name@4.1.0
		bytes@3.1.2
		cac@6.7.14
		call-bind@1.0.9
		call-bind-apply-helpers@1.0.2
		call-bound@1.0.4
		callsites@3.1.0
		caniuse-lite@1.0.30001793
		ccount@2.0.1
		chai@5.3.3
		chai@6.2.2
		chalk@4.1.2
		character-entities@2.0.2
		character-entities-html4@2.1.0
		character-entities-legacy@3.0.0
		check-error@2.1.3
		chokidar@4.0.3
		chokidar@5.0.0
		chownr@3.0.0
		chromatic@16.10.0
		clsx@2.1.1
		color-convert@2.0.1
		color-name@1.1.4
		colorette@2.0.20
		comma-separated-tokens@2.0.3
		commander@2.20.3
		commander@7.2.0
		commander@8.3.0
		common-tags@1.8.2
		concat-map@0.0.1
		consola@3.4.2
		content-disposition@1.1.0
		content-type@1.0.5
		content-type@2.0.0
		convert-source-map@2.0.0
		cookie@1.1.1
		cookie-signature@1.2.2
		core-js-compat@3.49.0
		cors@2.8.6
		corser@2.0.1
		cose-base@1.0.3
		cose-base@2.2.0
		cross-spawn@7.0.6
		crypto-random-string@2.0.0
		css.escape@1.5.1
		cssesc@3.0.0
		csstype@3.2.3
		cytoscape@3.34.0
		cytoscape-cose-bilkent@4.1.0
		cytoscape-fcose@2.2.0
		d3@7.9.0
		d3-array@2.12.1
		d3-array@3.2.4
		d3-axis@3.0.0
		d3-brush@3.0.0
		d3-chord@3.0.1
		d3-color@3.1.0
		d3-contour@4.0.2
		d3-delaunay@6.0.4
		d3-dispatch@3.0.1
		d3-drag@3.0.0
		d3-dsv@3.0.1
		d3-ease@3.0.1
		d3-fetch@3.0.1
		d3-force@3.0.0
		d3-format@3.1.2
		d3-geo@3.1.1
		d3-hierarchy@3.1.2
		d3-interpolate@3.0.1
		d3-path@1.0.9
		d3-path@3.1.0
		d3-polygon@3.0.1
		d3-quadtree@3.0.1
		d3-random@3.0.1
		d3-sankey@0.12.3
		d3-scale@4.0.2
		d3-scale-chromatic@3.1.0
		d3-selection@3.0.0
		d3-shape@1.3.7
		d3-shape@3.2.0
		d3-time@3.1.0
		d3-time-format@4.1.0
		d3-timer@3.0.1
		d3-transition@3.0.1
		d3-zoom@3.0.0
		dagre-d3-es@7.0.14
		data-view-buffer@1.0.2
		data-view-byte-length@1.0.2
		data-view-byte-offset@1.0.1
		dayjs@1.11.21
		debug@4.4.3
		decode-bmp@0.2.1
		decode-ico@0.4.1
		decode-named-character-reference@1.3.0
		dedent@1.7.2
		dedent-js@1.0.1
		deep-eql@5.0.2
		deep-is@0.1.4
		deepmerge@4.3.1
		default-browser@5.5.0
		default-browser-id@5.0.1
		define-data-property@1.1.4
		define-lazy-prop@3.0.0
		define-properties@1.2.1
		defu@6.1.7
		delaunator@5.1.0
		depd@2.0.0
		dequal@2.0.3
		detect-libc@2.1.2
		devalue@5.8.1
		devlop@1.1.0
		dexie@4.4.3
		dom-accessibility-api@0.5.16
		dom-accessibility-api@0.6.3
		dompurify@3.4.13
		dunder-proto@1.0.1
		ee-first@1.1.1
		ejs@3.1.10
		electron-to-chromium@1.5.367
		encodeurl@2.0.0
		enhanced-resolve@5.23.0
		entities@6.0.1
		es-abstract@1.24.2
		es-define-property@1.0.1
		es-errors@1.3.0
		es-module-lexer@2.1.0
		es-object-atoms@1.1.2
		es-set-tostringtag@2.1.0
		es-to-primitive@1.3.0
		es-toolkit@1.47.0
		esbuild@0.28.1
		escalade@3.2.0
		escape-html@1.0.3
		escape-string-regexp@4.0.0
		escape-string-regexp@5.0.0
		eslint@9.39.4
		eslint-config-prettier@10.1.8
		eslint-plugin-perfectionist@5.10.1
		eslint-plugin-simple-import-sort@14.0.0
		eslint-plugin-storybook@10.5.6
		eslint-plugin-svelte@3.19.0
		eslint-scope@8.4.0
		eslint-visitor-keys@3.4.3
		eslint-visitor-keys@4.2.1
		eslint-visitor-keys@5.0.1
		esm-env@1.2.2
		espree@10.4.0
		esprima@4.0.1
		esquery@1.7.0
		esrap@1.2.2
		esrap@1.4.9
		esrap@2.2.11
		esrecurse@4.3.0
		estraverse@5.3.0
		estree-walker@2.0.2
		estree-walker@3.0.3
		esutils@2.0.3
		eta@4.6.0
		etag@1.8.1
		eventemitter3@4.0.7
		eventsource@3.0.7
		eventsource-parser@3.1.0
		expect-type@1.3.0
		express@5.2.1
		express-rate-limit@8.5.2
		extend@3.0.2
		fast-deep-equal@3.1.3
		fast-json-stable-stringify@2.1.0
		fast-levenshtein@2.0.6
		fast-uri@3.1.5
		fdir@6.5.0
		fflate@0.8.3
		file-entry-cache@8.0.0
		filelist@1.0.6
		finalhandler@2.1.1
		find-up@5.0.0
		flat-cache@4.0.1
		flatted@3.4.2
		follow-redirects@1.16.0
		for-each@0.3.5
		foreground-child@3.3.1
		forwarded@0.2.0
		fresh@2.0.0
		fs-extra@9.1.0
		function-bind@1.1.2
		function.prototype.name@1.1.8
		functions-have-names@1.2.3
		generator-function@2.0.1
		gensync@1.0.0-beta.2
		get-intrinsic@1.3.0
		get-own-enumerable-property-symbols@3.0.2
		get-proto@1.0.1
		get-symbol-description@1.1.0
		glob@11.1.0
		glob-parent@6.0.2
		globals@14.0.0
		globals@16.5.0
		globalthis@1.0.4
		gopd@1.2.0
		graceful-fs@4.2.11
		hachure-fill@0.5.2
		has-bigints@1.1.0
		has-flag@4.0.0
		has-property-descriptors@1.0.2
		has-proto@1.2.0
		has-symbols@1.1.0
		has-tostringtag@1.0.2
		hasown@2.0.4
		hast-util-from-dom@5.0.1
		hast-util-from-html@2.0.3
		hast-util-from-html-isomorphic@2.0.0
		hast-util-from-parse5@8.0.3
		hast-util-is-element@3.0.0
		hast-util-parse-selector@4.0.0
		hast-util-sanitize@5.0.2
		hast-util-to-html@9.0.5
		hast-util-to-text@4.0.2
		hast-util-whitespace@3.0.0
		hastscript@9.0.1
		he@1.2.0
		highlight.js@11.11.1
		hono@4.13.0
		html-encoding-sniffer@3.0.0
		html-escaper@2.0.2
		html-void-elements@3.0.0
		http-errors@2.0.1
		http-proxy@1.18.1
		http-server@14.1.1
		ico-endec@0.1.6
		iconv-lite@0.6.3
		iconv-lite@0.7.2
		idb@7.1.1
		ignore@5.3.2
		ignore@7.0.5
		immutable@5.1.9
		import-fresh@3.3.1
		import-meta-resolve@4.2.0
		imurmurhash@0.1.4
		indent-string@4.0.0
		inherits@2.0.4
		inline-style-parser@0.2.7
		internal-slot@1.1.0
		internmap@1.0.1
		internmap@2.0.3
		ip-address@10.4.0
		ipaddr.js@1.9.1
		is-array-buffer@3.0.5
		is-async-function@2.1.1
		is-bigint@1.1.0
		is-boolean-object@1.2.2
		is-callable@1.2.7
		is-core-module@2.16.2
		is-data-view@1.0.2
		is-date-object@1.1.0
		is-docker@3.0.0
		is-extglob@2.1.1
		is-finalizationregistry@1.1.1
		is-generator-function@1.1.2
		is-glob@4.0.3
		is-inside-container@1.0.0
		is-map@2.0.3
		is-module@1.0.0
		is-negative-zero@2.0.3
		is-number-object@1.1.1
		is-obj@1.0.1
		is-plain-obj@4.1.0
		is-promise@4.0.0
		is-reference@3.0.3
		is-regex@1.2.1
		is-regexp@1.0.0
		is-set@2.0.3
		is-shared-array-buffer@1.0.4
		is-stream@2.0.1
		is-string@1.1.1
		is-symbol@1.1.1
		is-typed-array@1.1.15
		is-weakmap@2.0.2
		is-weakref@1.1.1
		is-weakset@2.0.4
		is-wsl@3.1.1
		isarray@2.0.5
		isexe@2.0.0
		istanbul-lib-coverage@3.2.2
		istanbul-lib-report@3.0.1
		istanbul-reports@3.2.0
		jackspeak@4.2.3
		jake@10.9.4
		jiti@2.7.0
		jose@6.2.3
		js-tokens@10.0.0
		js-tokens@4.0.0
		js-yaml@4.3.1
		jsesc@3.1.0
		json-buffer@3.0.1
		json-rpc-2.0@1.7.1
		json-schema-traverse@0.4.1
		json-schema-traverse@1.0.0
		json-schema-typed@8.0.2
		json-stable-stringify-without-jsonify@1.0.1
		json5@2.2.3
		jsonc-parser@3.3.1
		jsonfile@6.2.1
		jsonpointer@5.0.1
		katex@0.16.47
		keyv@4.5.4
		khroma@2.1.0
		kleur@4.1.5
		known-css-properties@0.37.0
		kolorist@1.8.0
		layout-base@1.0.2
		layout-base@2.0.1
		leven@3.1.0
		levn@0.4.1
		lightningcss@1.30.1
		lightningcss-linux-arm64-gnu@1.30.1|arm64
		lightningcss-linux-arm64-musl@1.30.1|arm64
		lightningcss-linux-x64-gnu@1.30.1|amd64
		lightningcss-linux-x64-musl@1.30.1|amd64
		lilconfig@2.1.0
		locate-character@3.0.0
		locate-path@6.0.0
		lodash-es@4.18.1
		lodash.castarray@4.4.0
		lodash.debounce@4.0.8
		lodash.isplainobject@4.0.6
		lodash.merge@4.6.2
		lodash.sortby@4.7.0
		longest-streak@3.1.0
		loupe@3.2.1
		lowlight@3.3.0
		lru-cache@11.5.1
		lru-cache@5.1.1
		lz-string@1.5.0
		magic-string@0.30.21
		magicast@0.5.3
		make-dir@4.0.0
		markdown-table@3.0.4
		marked@16.4.2
		math-intrinsics@1.1.0
		mdast@3.0.0
		mdast-util-find-and-replace@3.0.2
		mdast-util-from-markdown@2.0.3
		mdast-util-gfm@3.1.0
		mdast-util-gfm-autolink-literal@2.0.1
		mdast-util-gfm-footnote@2.1.0
		mdast-util-gfm-strikethrough@2.0.0
		mdast-util-gfm-table@2.0.0
		mdast-util-gfm-task-list-item@2.0.0
		mdast-util-math@3.0.0
		mdast-util-newline-to-break@2.0.0
		mdast-util-phrasing@4.1.0
		mdast-util-to-hast@13.2.1
		mdast-util-to-markdown@2.1.2
		mdast-util-to-string@4.0.0
		mdsvex@0.12.7
		media-typer@1.1.0
		merge-descriptors@2.0.0
		mermaid@11.15.0
		micromark@4.0.2
		micromark-core-commonmark@2.0.3
		micromark-extension-gfm@3.0.0
		micromark-extension-gfm-autolink-literal@2.1.0
		micromark-extension-gfm-footnote@2.1.0
		micromark-extension-gfm-strikethrough@2.1.0
		micromark-extension-gfm-table@2.1.1
		micromark-extension-gfm-tagfilter@2.0.0
		micromark-extension-gfm-task-list-item@2.1.0
		micromark-extension-math@3.1.0
		micromark-factory-destination@2.0.1
		micromark-factory-label@2.0.1
		micromark-factory-space@2.0.1
		micromark-factory-title@2.0.1
		micromark-factory-whitespace@2.0.1
		micromark-util-character@2.1.1
		micromark-util-chunked@2.0.1
		micromark-util-classify-character@2.0.1
		micromark-util-combine-extensions@2.0.1
		micromark-util-decode-numeric-character-reference@2.0.2
		micromark-util-decode-string@2.0.1
		micromark-util-encode@2.0.1
		micromark-util-html-tag-name@2.0.1
		micromark-util-normalize-identifier@2.0.1
		micromark-util-resolve-all@2.0.1
		micromark-util-sanitize-uri@2.0.1
		micromark-util-subtokenize@2.1.0
		micromark-util-symbol@2.0.1
		micromark-util-types@2.0.2
		mime@1.6.0
		mime-db@1.54.0
		mime-types@3.0.2
		min-indent@1.0.1
		mini-svg-data-uri@1.4.4
		minimatch@10.2.5
		minimatch@10.2.6
		minimatch@3.1.5
		minimatch@5.1.9
		minimist@1.2.8
		minipass@7.1.3
		minizlib@3.1.0
		mode-watcher@1.1.0
		mri@1.2.0
		mrmime@2.0.1
		ms@2.1.3
		nanoid@3.3.17
		natural-compare@1.4.0
		natural-orderby@5.0.0
		negotiator@1.0.0
		node-addon-api@7.1.1
		node-releases@2.0.47
		object-assign@4.1.1
		object-inspect@1.13.4
		object-keys@1.1.1
		object.assign@4.1.7
		obug@2.1.2
		on-finished@2.4.1
		once@1.4.0
		open@10.2.0
		opener@1.5.2
		optionator@0.9.4
		own-keys@1.0.1
		oxc-parser@0.127.0
		oxc-resolver@11.20.0
		p-limit@3.1.0
		p-locate@5.0.0
		package-json-from-dist@1.0.1
		package-manager-detector@1.6.0
		parent-module@1.0.1
		parse5@7.3.0
		parseurl@1.3.3
		path-data-parser@0.1.0
		path-exists@4.0.0
		path-key@3.1.1
		path-parse@1.0.7
		path-scurry@2.0.2
		path-to-regexp@8.4.2
		pathe@2.0.3
		pathval@2.0.1
		pdfjs-dist@5.4.54
		picocolors@1.1.1
		picomatch@4.0.4
		picoquery@2.5.0
		pkce-challenge@5.0.1
		playwright@1.56.1
		playwright-core@1.56.1
		pngjs@7.0.0
		points-on-curve@0.2.0
		points-on-path@0.2.1
		portfinder@1.0.38
		possible-typed-array-names@1.1.0
		postcss@8.5.25
		postcss-load-config@3.1.4
		postcss-safe-parser@7.0.1
		postcss-scss@4.0.9
		postcss-selector-parser@6.0.10
		postcss-selector-parser@7.1.1
		prelude-ls@1.2.1
		prettier@3.8.3
		prettier-plugin-svelte@4.1.0
		prettier-plugin-tailwindcss@0.8.0
		pretty-bytes@5.6.0
		pretty-bytes@6.1.1
		pretty-format@27.5.1
		prism-svelte@0.4.7
		prismjs@1.30.0
		property-information@7.2.0
		proxy-addr@2.0.7
		punycode@2.3.1
		qs@6.15.2
		quansync@1.0.0
		range-parser@1.2.1
		raw-body@3.0.2
		react@19.2.7
		react-dom@19.2.7
		react-is@17.0.2
		readdirp@4.1.2
		readdirp@5.0.0
		recast@0.23.11
		redent@3.0.0
		reflect.getprototypeof@1.0.10
		regenerate@1.4.2
		regenerate-unicode-properties@10.2.2
		regexp.prototype.flags@1.5.4
		regexpu-core@6.4.0
		regjsgen@0.8.0
		regjsparser@0.13.1
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
		resolve@1.22.12
		resolve-from@4.0.0
		robust-predicates@3.0.3
		rollup@4.61.1
		roughjs@4.6.6
		router@2.2.0
		run-applescript@7.1.0
		runed@0.23.4
		runed@0.25.0
		runed@0.28.0
		runed@0.35.1
		rw@1.3.3
		sade@1.8.1
		safe-array-concat@1.1.4
		safe-buffer@5.1.2
		safe-push-apply@1.0.0
		safe-regex-test@1.1.0
		safer-buffer@2.1.2
		sass@1.100.0
		scheduler@0.27.0
		scule@1.3.0
		secure-compare@3.0.1
		semver@6.3.1
		semver@7.8.5
		send@1.2.1
		serialize-javascript@7.0.5
		serve-static@2.2.1
		set-cookie-parser@3.1.0
		set-function-length@1.2.2
		set-function-name@2.0.2
		set-proto@1.0.0
		setprototypeof@1.2.0
		sharp@0.35.3
		sharp-ico@0.1.5
		shebang-command@2.0.0
		shebang-regex@3.0.0
		side-channel@1.1.0
		side-channel-list@1.0.1
		side-channel-map@1.0.1
		side-channel-weakmap@1.0.2
		siginfo@2.0.0
		signal-exit@4.1.0
		sirv@3.0.2
		smob@1.6.2
		source-map@0.6.1
		source-map@0.8.0-beta.0
		source-map-js@1.2.1
		source-map-support@0.5.21
		space-separated-tokens@2.0.2
		sqids@0.3.0
		stackback@0.0.2
		statuses@2.0.2
		std-env@4.1.0
		stop-iteration-iterator@1.1.0
		storybook@10.5.6
		string.prototype.matchall@4.0.12
		string.prototype.trim@1.2.10
		string.prototype.trimend@1.0.9
		string.prototype.trimstart@1.0.8
		stringify-entities@4.0.4
		stringify-object@3.3.0
		strip-ansi@7.2.0
		strip-comments@2.0.1
		strip-indent@3.0.0
		strip-json-comments@3.1.1
		style-to-object@1.0.14
		stylis@4.4.0
		supports-color@7.2.0
		supports-preserve-symlinks-flag@1.0.0
		svelte@5.56.1
		svelte-ast-print@0.4.2
		svelte-check@4.6.0
		svelte-eslint-parser@1.8.0
		svelte-sonner@1.1.1
		svelte-toolbelt@0.10.6
		svelte-toolbelt@0.7.1
		svelte2tsx@0.7.59
		tabbable@6.4.0
		tagged-tag@1.0.0
		tailwind-merge@3.6.0
		tailwind-variants@3.2.2
		tailwindcss@4.1.11
		tailwindcss@4.3.0
		tapable@2.3.3
		tar@7.5.22
		temp-dir@2.0.0
		tempy@0.6.0
		terser@5.48.0
		tiny-invariant@1.3.3
		tinybench@2.9.0
		tinyexec@1.2.4
		tinyglobby@0.2.17
		tinyrainbow@2.0.0
		tinyrainbow@3.1.1
		tinyspy@4.0.4
		tmcp@1.19.4
		to-data-view@1.1.0
		toidentifier@1.0.1
		totalist@3.0.1
		tr46@1.0.1
		trim-lines@3.0.1
		trough@2.2.0
		ts-api-utils@2.5.0
		ts-dedent@2.2.0
		tslib@2.8.1
		tw-animate-css@1.4.0
		type-check@0.4.0
		type-fest@0.16.0
		type-fest@2.19.0
		type-fest@5.8.0
		type-is@2.1.0
		typed-array-buffer@1.0.3
		typed-array-byte-length@1.0.3
		typed-array-byte-offset@1.0.4
		typed-array-length@1.0.8
		typescript@5.9.3
		typescript-eslint@8.60.1
		unbox-primitive@1.1.0
		unconfig@7.5.0
		unconfig-core@7.5.0
		undici-types@7.18.2
		unicode-canonical-property-names-ecmascript@2.0.1
		unicode-match-property-ecmascript@2.0.0
		unicode-match-property-value-ecmascript@2.2.1
		unicode-property-aliases-ecmascript@2.2.0
		unified@11.0.5
		union@0.5.0
		unique-string@2.0.0
		unist-util-find-after@5.0.0
		unist-util-is@4.1.0
		unist-util-is@6.0.1
		unist-util-position@5.0.0
		unist-util-remove-position@5.0.0
		unist-util-stringify-position@2.0.3
		unist-util-stringify-position@4.0.0
		unist-util-visit@2.0.3
		unist-util-visit@5.1.0
		unist-util-visit-parents@3.1.1
		unist-util-visit-parents@6.0.2
		universalify@2.0.1
		unpipe@1.0.0
		unplugin@2.3.11
		upath@1.2.0
		update-browserslist-db@1.2.3
		uri-js@4.4.1
		uri-template-matcher@1.1.2
		url-join@4.0.1
		use-sync-external-store@1.6.0
		util-deprecate@1.0.2
		uuid@11.1.1
		uuid@13.0.2
		valibot@1.4.2
		vary@1.1.2
		vfile@6.0.3
		vfile-location@5.0.3
		vfile-message@2.0.4
		vfile-message@4.0.3
		vite@7.3.6
		vite-plugin-devtools-json@0.2.1
		vite-plugin-pwa@1.3.0
		vitefu@1.1.3
		vitest@4.1.10
		vitest-browser-svelte@2.1.1
		web-namespaces@2.0.1
		webidl-conversions@4.0.2
		webpack-virtual-modules@0.6.2
		whatwg-encoding@2.0.0
		whatwg-url@7.1.0
		which@2.0.2
		which-boxed-primitive@1.1.1
		which-builtin-type@1.2.1
		which-collection@1.0.2
		which-typed-array@1.1.21
		why-is-node-running@2.3.0
		word-wrap@1.2.5
		workbox-background-sync@7.4.1
		workbox-broadcast-update@7.4.1
		workbox-build@7.4.1
		workbox-cacheable-response@7.4.1
		workbox-core@7.4.1
		workbox-expiration@7.4.1
		workbox-google-analytics@7.4.1
		workbox-navigation-preload@7.4.1
		workbox-precaching@7.4.1
		workbox-range-requests@7.4.1
		workbox-recipes@7.4.1
		workbox-routing@7.4.1
		workbox-strategies@7.4.1
		workbox-streams@7.4.1
		workbox-sw@7.4.1
		workbox-window@7.4.1
		wrappy@1.0.2
		ws@8.21.2
		wsl-utils@0.1.0
		yallist@3.1.1
		yallist@5.0.0
		yaml@1.10.3
		yocto-queue@0.1.0
		zimmerframe@1.1.2
		zimmerframe@1.1.4
		zod@4.4.3
		zod-to-json-schema@3.25.2
		zwitch@2.0.4
	"
	NPM_STUB_PKGS="
		@esbuild/aix-ppc64@0.28.1
		@esbuild/android-arm64@0.28.1
		@esbuild/android-arm@0.28.1
		@esbuild/android-x64@0.28.1
		@esbuild/darwin-arm64@0.28.1
		@esbuild/darwin-x64@0.28.1
		@esbuild/freebsd-arm64@0.28.1
		@esbuild/freebsd-x64@0.28.1
		@esbuild/linux-arm@0.28.1
		@esbuild/linux-ia32@0.28.1
		@esbuild/linux-loong64@0.28.1
		@esbuild/linux-mips64el@0.28.1
		@esbuild/linux-ppc64@0.28.1
		@esbuild/linux-riscv64@0.28.1
		@esbuild/linux-s390x@0.28.1
		@esbuild/netbsd-arm64@0.28.1
		@esbuild/netbsd-x64@0.28.1
		@esbuild/openbsd-arm64@0.28.1
		@esbuild/openbsd-x64@0.28.1
		@esbuild/openharmony-arm64@0.28.1
		@esbuild/sunos-x64@0.28.1
		@esbuild/win32-arm64@0.28.1
		@esbuild/win32-ia32@0.28.1
		@esbuild/win32-x64@0.28.1
		@img/sharp-darwin-arm64@0.35.3
		@img/sharp-darwin-x64@0.35.3
		@img/sharp-freebsd-wasm32@0.35.3
		@img/sharp-libvips-darwin-arm64@1.3.2
		@img/sharp-libvips-darwin-x64@1.3.2
		@img/sharp-libvips-linux-arm@1.3.2
		@img/sharp-libvips-linux-ppc64@1.3.2
		@img/sharp-libvips-linux-riscv64@1.3.2
		@img/sharp-libvips-linux-s390x@1.3.2
		@img/sharp-linux-arm@0.35.3
		@img/sharp-linux-ppc64@0.35.3
		@img/sharp-linux-riscv64@0.35.3
		@img/sharp-linux-s390x@0.35.3
		@img/sharp-webcontainers-wasm32@0.35.3
		@img/sharp-win32-arm64@0.35.3
		@img/sharp-win32-ia32@0.35.3
		@img/sharp-win32-x64@0.35.3
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
		@oxc-resolver/binding-android-arm-eabi@11.20.0
		@oxc-resolver/binding-android-arm64@11.20.0
		@oxc-resolver/binding-darwin-arm64@11.20.0
		@oxc-resolver/binding-darwin-x64@11.20.0
		@oxc-resolver/binding-freebsd-x64@11.20.0
		@oxc-resolver/binding-linux-arm-gnueabihf@11.20.0
		@oxc-resolver/binding-linux-arm-musleabihf@11.20.0
		@oxc-resolver/binding-linux-ppc64-gnu@11.20.0
		@oxc-resolver/binding-linux-riscv64-gnu@11.20.0
		@oxc-resolver/binding-linux-riscv64-musl@11.20.0
		@oxc-resolver/binding-linux-s390x-gnu@11.20.0
		@oxc-resolver/binding-openharmony-arm64@11.20.0
		@oxc-resolver/binding-wasm32-wasi@11.20.0
		@oxc-resolver/binding-win32-arm64-msvc@11.20.0
		@oxc-resolver/binding-win32-x64-msvc@11.20.0
		@parcel/watcher-android-arm64@2.5.6
		@parcel/watcher-darwin-arm64@2.5.6
		@parcel/watcher-darwin-x64@2.5.6
		@parcel/watcher-freebsd-x64@2.5.6
		@parcel/watcher-linux-arm-glibc@2.5.6
		@parcel/watcher-linux-arm-musl@2.5.6
		@parcel/watcher-win32-arm64@2.5.6
		@parcel/watcher-win32-ia32@2.5.6
		@parcel/watcher-win32-x64@2.5.6
		@rollup/rollup-android-arm-eabi@4.61.1
		@rollup/rollup-android-arm64@4.61.1
		@rollup/rollup-darwin-arm64@4.61.1
		@rollup/rollup-darwin-x64@4.61.1
		@rollup/rollup-freebsd-arm64@4.61.1
		@rollup/rollup-freebsd-x64@4.61.1
		@rollup/rollup-linux-arm-gnueabihf@4.61.1
		@rollup/rollup-linux-arm-musleabihf@4.61.1
		@rollup/rollup-linux-loong64-gnu@4.61.1
		@rollup/rollup-linux-loong64-musl@4.61.1
		@rollup/rollup-linux-ppc64-gnu@4.61.1
		@rollup/rollup-linux-ppc64-musl@4.61.1
		@rollup/rollup-linux-riscv64-gnu@4.61.1
		@rollup/rollup-linux-riscv64-musl@4.61.1
		@rollup/rollup-linux-s390x-gnu@4.61.1
		@rollup/rollup-openbsd-x64@4.61.1
		@rollup/rollup-openharmony-arm64@4.61.1
		@rollup/rollup-win32-arm64-msvc@4.61.1
		@rollup/rollup-win32-ia32-msvc@4.61.1
		@rollup/rollup-win32-x64-gnu@4.61.1
		@rollup/rollup-win32-x64-msvc@4.61.1
		@tailwindcss/oxide-android-arm64@4.1.11
		@tailwindcss/oxide-darwin-arm64@4.1.11
		@tailwindcss/oxide-darwin-x64@4.1.11
		@tailwindcss/oxide-freebsd-x64@4.1.11
		@tailwindcss/oxide-linux-arm-gnueabihf@4.1.11
		@tailwindcss/oxide-wasm32-wasi@4.1.11
		@tailwindcss/oxide-win32-arm64-msvc@4.1.11
		@tailwindcss/oxide-win32-x64-msvc@4.1.11
		fsevents@2.3.2
		fsevents@2.3.3
		lightningcss-darwin-arm64@1.30.1
		lightningcss-darwin-x64@1.30.1
		lightningcss-freebsd-x64@1.30.1
		lightningcss-linux-arm-gnueabihf@1.30.1
		lightningcss-win32-arm64-msvc@1.30.1
		lightningcss-win32-x64-msvc@1.30.1
	"
	XDNA_COMMIT="fade39f670ae40af184a529e61c8eaa7b799c3b2"
fi

inherit cmake cuda flag-o-matic linux-info npm rocm
[[ ${PV} == 9999 ]] && inherit git-r3

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
		${NPM_PKG_URIS}
	"
	S="${WORKDIR}/llama.cpp-${PV}"
fi

LICENSE="MIT"
# Web UI npm package licenses
LICENSE+=" 0BSD Apache-2.0 BSD BSD-2 CC0-1.0 ISC MIT MPL-2.0 Unlicense"
SLOT="0"
KEYWORDS="~amd64"
IUSE="curl openblas +openmp blis hip cuda opencl vulkan xdna"
RESTRICT="mirror"

BDEPEND="
	${NPM_NODE_DEPEND}
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

PATCHES=( "${FILESDIR}/0006-hip-fix-gfx12-bf16-wmma-with-llvm-23.patch" )

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
		pushd "${S}/tools/ui" >/dev/null || die
		HOME="${T}/npm-home" npm ci --ignore-scripts --no-audit --no-fund \
			--cache "${T}/npm-cache" || die "npm ci failed"
		popd >/dev/null || die
	else
		npm_src_unpack
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
	fi

	cmake_src_prepare
}

src_configure() {
	# Force enable the Web UI macros
	append-cppflags -DLLAMA_BUILD_UI=1 -DLLAMA_BUILD_WEBUI=1

	local mycmakeargs=(
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_BUILD_UI=ON
		# Point CMake to the directory where we will build the UI assets
		-DUI_SOURCE_DIR="${S}/tools/ui"
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

src_compile() {
	# 1. Build the Web UI assets from source
	einfo "Building Web UI assets using npm..."
	pushd "${S}/tools/ui" > /dev/null || die

	# Releases install the UI's dependencies from the offline registry
	if [[ ${PV} != 9999 ]]; then
		npm_with_registry npm ci --ignore-scripts
	fi
	# Generates the dist/ directory CMake embeds
	HOME="${T}/npm-home" npm run build --offline || die

	popd > /dev/null || die

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
