# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER=1.92.0
CRATES="
	ahash@0.7.8
	ahash@0.8.11
	aho-corasick@1.1.3
	android-tzdata@0.1.1
	android_system_properties@0.1.5
	anstyle@1.0.10
	assert_cmd@2.0.16
	assert_fs@1.1.2
	atty@0.2.14
	autocfg@1.4.0
	base64-simd@0.7.0
	bitflags@1.3.2
	bitflags@2.6.0
	bitvec@1.0.1
	browserslist-rs@0.17.0
	browserslist-rs@0.18.1
	bstr@1.11.1
	bumpalo@3.16.0
	bytecheck@0.6.12
	bytecheck_derive@0.6.12
	bytes@1.9.0
	cbindgen@0.24.5
	cc@1.2.5
	cfg-if@1.0.0
	chrono@0.4.39
	clap@3.2.25
	clap_derive@3.2.25
	clap_lex@0.2.4
	const-str-proc-macro@0.3.2
	const-str@0.3.2
	convert_case@0.6.0
	core-foundation-sys@0.8.7
	crossbeam-channel@0.5.14
	crossbeam-deque@0.8.6
	crossbeam-epoch@0.9.18
	crossbeam-utils@0.8.21
	cssparser-color@0.1.0
	cssparser-macros@0.6.1
	cssparser@0.33.0
	ctor@0.2.9
	dashmap@5.5.3
	data-encoding@2.6.0
	data-url@0.1.1
	diff@0.1.13
	difflib@0.4.0
	doc-comment@0.3.3
	dtoa-short@0.3.5
	dtoa@1.0.9
	dyn-clone@1.0.17
	either@1.13.0
	equivalent@1.0.1
	errno@0.3.10
	fastrand@2.3.0
	float-cmp@0.9.0
	fs_extra@1.3.0
	funty@2.0.0
	getrandom@0.2.15
	globset@0.4.15
	globwalk@0.9.1
	hashbrown@0.12.3
	hashbrown@0.14.5
	hashbrown@0.15.2
	heck@0.4.1
	hermit-abi@0.1.19
	iana-time-zone-haiku@0.1.2
	iana-time-zone@0.1.61
	ignore@0.4.23
	indexmap@1.9.3
	indexmap@2.7.0
	indoc@1.0.9
	itertools@0.10.5
	itertools@0.13.0
	itoa@1.0.14
	jemalloc-sys@0.3.2
	jemallocator@0.3.2
	js-sys@0.3.76
	lazy_static@1.5.0
	libc@0.2.169
	libloading@0.8.6
	linux-raw-sys@0.4.14
	lock_api@0.4.12
	log@0.4.22
	matches@0.1.10
	memchr@2.7.4
	minimal-lexical@0.2.1
	napi-build@1.2.1
	napi-derive-backend@1.0.75
	napi-derive@2.16.13
	napi-sys@2.4.0
	napi@2.16.13
	nom@7.1.3
	normalize-line-endings@0.3.0
	num-traits@0.2.19
	once_cell@1.20.2
	os_str_bytes@6.6.1
	outref@0.1.0
	parcel_sourcemap@2.1.1
	parking_lot_core@0.9.10
	paste@1.0.15
	pathdiff@0.2.3
	phf@0.11.2
	phf_codegen@0.11.2
	phf_generator@0.11.2
	phf_macros@0.11.2
	phf_shared@0.11.2
	precomputed-hash@0.1.1
	predicates-core@1.0.9
	predicates-tree@1.0.12
	predicates@2.1.5
	predicates@3.1.3
	pretty_assertions@1.4.1
	proc-macro-error-attr@1.0.4
	proc-macro-error@1.0.4
	proc-macro2@1.0.92
	ptr_meta@0.1.4
	ptr_meta_derive@0.1.4
	quote@1.0.37
	radium@0.7.0
	rand@0.8.5
	rand_core@0.6.4
	rayon-core@1.12.1
	rayon@1.10.0
	redox_syscall@0.5.8
	regex-automata@0.4.9
	regex-syntax@0.8.5
	regex@1.11.1
	rend@0.4.2
	rkyv@0.7.45
	rkyv_derive@0.7.45
	rustc-hash@2.1.0
	rustix@0.38.42
	ryu@1.0.18
	same-file@1.0.6
	schemars@0.8.21
	schemars_derive@0.8.21
	scopeguard@1.2.0
	seahash@4.1.0
	semver@1.0.24
	serde-detach@0.0.1
	serde@1.0.216
	serde_bytes@0.11.15
	serde_derive@1.0.216
	serde_derive_internals@0.29.1
	serde_json@1.0.133
	shlex@1.3.0
	simd-abstraction@0.7.1
	simdutf8@0.1.5
	siphasher@0.3.11
	smallvec@1.13.2
	strsim@0.10.0
	syn@1.0.109
	syn@2.0.90
	tap@1.0.1
	tempfile@3.14.0
	termcolor@1.4.1
	termtree@0.5.1
	textwrap@0.16.1
	thiserror-impl@1.0.69
	thiserror@1.0.69
	tinyvec@1.8.1
	tinyvec_macros@0.1.1
	toml@0.5.11
	unicode-ident@1.0.14
	unicode-segmentation@1.12.0
	uuid@1.11.0
	version_check@0.9.5
	vlq@0.5.1
	wait-timeout@0.2.0
	walkdir@2.5.0
	wasi@0.11.0+wasi-snapshot-preview1
	wasm-bindgen-backend@0.2.99
	wasm-bindgen-macro-support@0.2.99
	wasm-bindgen-macro@0.2.99
	wasm-bindgen-shared@0.2.99
	wasm-bindgen@0.2.99
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-util@0.1.9
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-core@0.52.0
	windows-sys@0.59.0
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.52.6
	wyz@0.2.0
	wyz@0.5.1
	yansi@1.0.1
	zerocopy-derive@0.7.35
	zerocopy@0.7.35
"

inherit cargo

DESCRIPTION="Native Node.js binding of the Lightning CSS parser and minifier"
HOMEPAGE="https://lightningcss.dev/"
SRC_URI="
	https://github.com/parcel-bundler/lightningcss/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

LICENSE="MPL-2.0"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 ISC MIT MPL-2.0
"
SLOT="${PV}"
KEYWORDS="~amd64 ~arm64"

src_configure() {
	cargo_src_configure --frozen
}

src_compile() {
	cargo_src_compile -p lightningcss_node
}

src_test() {
	:
}

src_install() {
	insinto /usr/$(get_libdir)/${P}
	newins "$(cargo_target_dir)/liblightningcss_node.so" lightningcss.node
	fperms 0755 /usr/$(get_libdir)/${P}/lightningcss.node
}
