# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER=1.91.0
CRATES="
	ahash@0.8.12
	aho-corasick@1.1.5
	allocator-api2@0.2.21
	anyhow@1.0.104
	ar_archive_writer@0.5.3
	arrayvec@0.7.8
	ascii@1.1.0
	ast_node@6.1.0
	autocfg@1.5.1
	base-encode@0.3.1
	base64-simd@0.8.0
	base64@0.22.1
	better_scoped_tls@1.0.1
	bitflags@2.13.1
	bitvec@1.1.1
	bstr@1.13.1
	bumpalo@3.20.3
	bytes-str@0.2.8
	bytes@1.12.1
	castaway@0.2.4
	cc@1.4.2
	cfg-if@1.0.4
	cmake@0.1.58
	compact_str@0.7.1
	console_error_panic_hook@0.1.7
	convert_case@0.11.0
	crossbeam-utils@0.8.22
	ctor@1.0.13
	dashmap@6.2.1
	data-encoding@2.11.1
	debugid@0.8.0
	displaydoc@0.2.7
	dragonbox_ecma@0.1.12
	either@1.17.0
	equivalent@1.0.2
	find-msvc-tools@0.1.10
	fixedbitset@0.5.7
	foldhash@0.2.0
	form_urlencoded@1.2.2
	from_variant@3.0.0
	funty@2.0.0
	futures-channel@0.3.34
	futures-core@0.3.34
	futures-executor@0.3.34
	futures-io@0.3.34
	futures-macro@0.3.34
	futures-sink@0.3.34
	futures-task@0.3.34
	futures-util@0.3.34
	futures@0.3.34
	globset@0.4.20
	hashbrown@0.14.5
	hashbrown@0.16.1
	hashbrown@0.17.1
	heck@0.5.0
	hermit-abi@0.5.2
	hstr@4.0.1
	icu_collections@2.3.0
	icu_locale_core@2.3.0
	icu_normalizer@2.3.0
	icu_normalizer_data@2.3.0
	icu_properties@2.3.0
	icu_properties_data@2.3.0
	icu_provider@2.3.0
	idna@1.1.0
	idna_adapter@1.2.2
	if_chain@1.0.3
	indexmap@2.14.0
	is-macro@0.3.7
	itoa@1.0.18
	js-sys@0.3.104
	libc@0.2.189
	libloading@0.9.0
	libmimalloc-sys2@0.1.60
	litemap@0.8.3
	lock_api@0.4.14
	memchr@2.8.3
	mimalloc-safe@0.1.64
	napi-build@2.4.1
	napi-derive-backend@6.1.2
	napi-derive@3.6.3
	napi-sys@3.3.0
	napi@3.12.1
	new_debug_unreachable@1.0.6
	nohash-hasher@0.2.0
	num-bigint@0.4.8
	num-integer@0.1.47
	num-traits@0.2.19
	num_cpus@1.17.0
	object@0.39.1
	once_cell@1.21.4
	outref@0.5.2
	par-core@2.0.0
	par-iter@2.0.0
	parking_lot@0.12.5
	parking_lot_core@0.9.12
	pathdiff@0.2.3
	percent-encoding@2.3.2
	petgraph@0.7.1
	phf@0.11.3
	phf_generator@0.11.3
	phf_macros@0.11.3
	phf_shared@0.11.3
	pin-project-lite@0.2.17
	potential_utf@0.1.6
	proc-macro2@1.0.107
	psm@0.1.32
	quote@1.0.47
	radium@0.7.0
	radix_fmt@1.0.0
	rand@0.8.7
	rand_core@0.6.4
	redox_syscall@0.5.18
	regex-automata@0.4.18
	regex-syntax@0.8.11
	regex@1.13.1
	regress@0.11.1
	rustc-hash@2.1.3
	rustversion@1.0.23
	ryu-js@1.0.3
	ryu@1.0.23
	scoped-tls@1.0.1
	scopeguard@1.2.0
	semver@1.0.28
	seq-macro@0.3.6
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.151
	shlex@2.0.1
	siphasher@0.3.11
	siphasher@1.0.3
	slab@0.4.12
	smallvec@1.15.2
	stable_deref_trait@1.2.1
	stacker@0.1.25
	static_assertions@1.1.0
	string_enum@1.0.2
	swc_allocator@5.0.0
	swc_atoms@10.0.0
	swc_common@25.0.0
	swc_compiler_base@63.0.0
	swc_config@6.0.0
	swc_config_macro@1.0.1
	swc_ecma_ast@28.0.0
	swc_ecma_codegen@31.0.0
	swc_ecma_codegen_macros@2.0.2
	swc_ecma_hooks@0.12.0
	swc_ecma_minifier@60.0.2
	swc_ecma_parser@44.0.0
	swc_ecma_transforms_base@48.0.0
	swc_ecma_transforms_optimization@51.0.1
	swc_ecma_utils@34.0.0
	swc_ecma_visit@28.0.0
	swc_eq_ignore_macros@1.0.1
	swc_macros_common@1.0.1
	swc_sourcemap@10.0.2
	swc_visit@2.0.1
	syn@2.0.119
	syn@3.0.3
	synstructure@0.13.2
	tap@1.0.1
	tinystr@0.8.4
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing@0.1.44
	triomphe@0.1.16
	unicode-id-start@1.4.0
	unicode-ident@1.0.24
	unicode-segmentation@1.13.3
	unicode-width@0.2.2
	url@2.5.8
	utf8_iter@1.0.4
	uuid@1.24.0
	version_check@0.9.5
	vsimd@0.8.0
	wasm-bindgen-macro-support@0.2.127
	wasm-bindgen-macro@0.2.127
	wasm-bindgen-shared@0.2.127
	wasm-bindgen@0.2.127
	windows-link@0.2.1
	windows-sys@0.61.2
	writeable@0.6.4
	wyz@0.5.1
	xxhash-rust@0.8.18
	yoke-derive@0.8.2
	yoke@0.8.3
	zerocopy-derive@0.8.56
	zerocopy@0.8.56
	zerofrom-derive@0.1.7
	zerofrom@0.1.8
	zerotrie@0.2.5
	zerovec-derive@0.11.4
	zerovec@0.11.7
	zmij@1.0.23
"

inherit cargo

DESCRIPTION="Native Node.js binding of the Rollup JavaScript bundler"
HOMEPAGE="https://rollupjs.org/"
SRC_URI="
	https://github.com/rollup/rollup/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/${P}/rust"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD Boost-1.0 ISC MIT
	Unicode-3.0 ZLIB
"
SLOT="${PV}"
KEYWORDS="~amd64 ~arm64"

src_configure() {
	# Gentoo strips at install
	export CARGO_PROFILE_RELEASE_STRIP=false
	cargo_src_configure --frozen
}

src_compile() {
	cargo_src_compile -p bindings_napi
}

src_test() {
	:
}

src_install() {
	insinto /usr/$(get_libdir)/${P}
	newins "$(cargo_target_dir)/libbindings_napi.so" rollup.node
	fperms 0755 /usr/$(get_libdir)/${P}/rollup.node
}
