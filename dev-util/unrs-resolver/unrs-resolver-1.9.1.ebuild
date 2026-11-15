# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER=1.87.0
CRATES="
	adler@1.0.2
	aho-corasick@1.1.3
	android-tzdata@0.1.1
	android_system_properties@0.1.5
	anes@0.2.0
	arca@0.7.0
	autocfg@1.4.0
	base64@0.22.1
	bit-set@0.5.3
	bit-vec@0.6.3
	bitflags@2.9.1
	bpaf@0.9.20
	bumpalo@3.18.1
	byteorder@1.5.0
	cast@0.3.0
	cc@1.2.26
	cfg-if@1.0.1
	chrono@0.4.41
	ciborium-io@0.2.2
	ciborium-ll@0.2.2
	ciborium@0.2.2
	clean-path@0.2.1
	cmake@0.1.54
	codspeed@2.10.1
	colored@2.2.0
	colored@3.0.0
	concurrent_lru@0.2.0
	convert_case@0.8.0
	core-foundation-sys@0.8.7
	criterion2@3.0.0
	crossbeam-deque@0.8.6
	crossbeam-epoch@0.9.18
	crossbeam-utils@0.8.21
	crunchy@0.2.3
	ctor-proc-macro@0.0.5
	ctor@0.4.2
	darling@0.20.11
	darling_core@0.20.11
	darling_macro@0.20.11
	dashmap@7.0.0-rc2
	deranged@0.4.0
	dirs-sys@0.5.0
	dirs@6.0.0
	displaydoc@0.2.5
	document-features@0.2.11
	dtor-proc-macro@0.0.5
	dtor@0.0.6
	dunce@1.0.5
	either@1.15.0
	endian-type@0.1.2
	equivalent@1.0.2
	fancy-regex@0.13.0
	filetime@0.2.25
	fnv@1.0.7
	form_urlencoded@1.2.1
	getrandom@0.2.16
	getrandom@0.3.3
	half@2.6.0
	hashbrown@0.12.3
	hashbrown@0.15.4
	hex@0.4.3
	iana-time-zone-haiku@0.1.2
	iana-time-zone@0.1.63
	icu_collections@2.0.0
	icu_locale_core@2.0.0
	icu_normalizer@2.0.0
	icu_normalizer_data@2.0.0
	icu_properties@2.0.1
	icu_properties_data@2.0.1
	icu_provider@2.0.0
	ident_case@1.0.1
	idna@1.0.3
	idna_adapter@1.2.1
	indexmap@1.9.3
	indexmap@2.9.0
	itoa@1.0.15
	js-sys@0.3.77
	json-strip-comments@1.0.4
	lazy_static@1.5.0
	libc@0.2.172
	libloading@0.8.8
	libmimalloc-sys2@0.1.49
	libredox@0.1.3
	litemap@0.8.0
	litrs@0.4.1
	lock_api@0.4.13
	log@0.4.27
	memchr@2.7.4
	mimalloc-safe@0.1.53
	miniz_oxide@0.7.4
	napi-build@2.2.1
	napi-derive-backend@2.0.0-beta.8
	napi-derive@3.0.0-beta.8
	napi-sys@3.0.0-alpha.3
	napi@3.0.0-beta.8
	nibble_vec@0.1.0
	nohash-hasher@0.2.0
	normalize-path@0.2.1
	num-conv@0.1.0
	num-traits@0.2.19
	once_cell@1.21.3
	oorandom@11.1.5
	option-ext@0.2.0
	papaya@0.2.1
	parking_lot_core@0.9.11
	path-slash@0.2.1
	pathdiff@0.2.3
	percent-encoding@2.3.1
	pico-args@0.5.0
	pin-project-lite@0.2.16
	pnp@0.9.4
	potential_utf@0.1.2
	powerfmt@0.2.0
	proc-macro2@1.0.95
	quote@1.0.40
	r-efi@5.2.0
	radix_trie@0.2.1
	rayon-core@1.12.1
	rayon@1.10.0
	redox_syscall@0.5.12
	redox_users@0.5.0
	regex-automata@0.4.9
	regex-syntax@0.8.5
	regex@1.11.1
	rustc-hash@2.1.1
	rustversion@1.0.21
	ryu@1.0.20
	same-file@1.0.6
	scopeguard@1.2.0
	seize@0.5.0
	semver@1.0.26
	serde@1.0.219
	serde_derive@1.0.219
	serde_json@1.0.140
	serde_with@3.12.0
	serde_with_macros@3.12.0
	sharded-slab@0.1.7
	shlex@1.3.0
	simdutf8@0.1.5
	smallvec@1.15.1
	stable_deref_trait@1.2.0
	strsim@0.11.1
	syn@2.0.102
	synstructure@0.13.2
	thiserror-impl@2.0.12
	thiserror@2.0.12
	thread_local@1.1.8
	time-core@0.1.4
	time-macros@0.2.22
	time@0.3.41
	tinystr@0.8.1
	tracing-attributes@0.1.29
	tracing-core@0.1.34
	tracing-subscriber@0.3.19
	tracing@0.1.41
	unicode-ident@1.0.18
	unicode-segmentation@1.12.0
	url@2.5.4
	utf8_iter@1.0.4
	uuid@1.17.0
	vfs@0.12.1
	walkdir@2.5.0
	wasi@0.11.1+wasi-snapshot-preview1
	wasi@0.14.2+wasi-0.2.4
	wasm-bindgen-backend@0.2.100
	wasm-bindgen-macro-support@0.2.100
	wasm-bindgen-macro@0.2.100
	wasm-bindgen-shared@0.2.100
	wasm-bindgen@0.2.100
	winapi-util@0.1.9
	windows-core@0.61.2
	windows-implement@0.60.0
	windows-interface@0.59.1
	windows-link@0.1.1
	windows-result@0.3.4
	windows-strings@0.4.2
	windows-sys@0.52.0
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
	wit-bindgen-rt@0.39.0
	writeable@0.6.1
	yoke-derive@0.8.0
	yoke@0.8.0
	zerofrom-derive@0.1.6
	zerofrom@0.1.6
	zerotrie@0.2.2
	zerovec-derive@0.11.1
	zerovec@0.11.2
"

inherit cargo

DESCRIPTION="Native Node.js binding of the unrs module resolver"
HOMEPAGE="https://github.com/unrs/unrs-resolver"
SRC_URI="
	https://github.com/unrs/unrs-resolver/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD-2 ISC MIT MPL-2.0 Unicode-3.0
"
SLOT="${PV}"
KEYWORDS="~amd64 ~arm64"

src_configure() {
	cargo_src_configure --frozen
}

src_compile() {
	cargo_src_compile -p unrs_resolver_napi
}

src_test() {
	:
}

src_install() {
	insinto /usr/$(get_libdir)/${P}
	newins "$(cargo_target_dir)/libunrs_resolver_napi.so" unrs-resolver.node
	fperms 0755 /usr/$(get_libdir)/${P}/unrs-resolver.node
}
