# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER=1.88.0
CRATES="
	adler2@2.0.1
	allocator-api2@0.2.21
	anyhow@1.0.102
	approx@0.5.1
	arrayvec@0.7.6
	autocfg@1.5.0
	bitflags@2.11.0
	bpaf@0.9.26
	byteorder@1.5.0
	cast@0.3.0
	castaway@0.2.4
	cc@1.2.59
	cfg-if@1.0.4
	cfg_aliases@0.2.1
	ciborium-io@0.2.2
	ciborium-ll@0.2.2
	ciborium@0.2.2
	cmake@0.1.58
	codspeed@4.7.0
	colored@2.2.0
	colored@3.1.1
	compact_str@0.10.0
	concurrent_lru@0.2.0
	convert_case@0.11.0
	crc32fast@1.5.0
	criterion2@3.0.4
	crossbeam-deque@0.8.6
	crossbeam-epoch@0.9.20
	crossbeam-utils@0.8.21
	crunchy@0.2.4
	ctor@1.0.5
	dashmap@6.2.1
	dirs-sys@0.5.0
	dirs@6.0.0
	document-features@0.2.12
	either@1.15.0
	endian-type@0.2.0
	equivalent@1.0.2
	errno@0.3.14
	fast-glob@1.1.0
	filetime@0.2.26
	find-msvc-tools@0.1.9
	flate2@1.1.5
	float-cmp@0.10.0
	foldhash@0.2.0
	futures-channel@0.3.31
	futures-core@0.3.31
	futures-executor@0.3.31
	futures-io@0.3.31
	futures-macro@0.3.31
	futures-sink@0.3.31
	futures-task@0.3.31
	futures-util@0.3.31
	futures@0.3.31
	getrandom@0.2.17
	glob@0.3.3
	half@2.7.1
	halfbrown@0.4.0
	hashbrown@0.14.5
	hashbrown@0.16.1
	hashbrown@0.17.0
	indexmap@2.14.0
	itoa@1.0.18
	json-strip-comments@3.1.2
	lazy_static@1.5.0
	libc@0.2.184
	libloading@0.9.0
	libmimalloc-sys2@0.1.60
	libredox@0.1.10
	libz-rs-sys@0.5.2
	linux-raw-sys@0.12.1
	litrs@1.0.0
	lock_api@0.4.14
	memchr@2.8.3
	mimalloc-safe@0.1.64
	miniz_oxide@0.8.9
	napi-build@2.4.1
	napi-derive-backend@6.1.2
	napi-derive@3.6.3
	napi-sys@3.3.0
	napi@3.12.2
	nibble_vec@0.1.0
	nix@0.31.2
	nodejs-built-in-modules@1.0.0
	nohash-hasher@0.2.0
	num-traits@0.2.19
	once_cell@1.21.4
	oorandom@11.1.5
	option-ext@0.2.0
	parking_lot_core@0.9.12
	pathdiff@0.2.3
	percent-encoding@2.3.2
	pico-args@0.5.0
	pin-project-lite@0.2.16
	pin-utils@0.1.0
	pnp@0.12.12
	proc-macro2@1.0.106
	quote@1.0.45
	radix_trie@0.3.0
	rayon-core@1.13.0
	rayon@1.12.0
	redox_syscall@0.5.18
	redox_users@0.5.2
	ref-cast-impl@1.0.25
	ref-cast@1.0.25
	regress@0.12.0
	rustc-hash@2.1.3
	rustix@1.1.4
	rustversion@1.0.22
	ryu@1.0.20
	same-file@1.0.6
	scopeguard@1.2.0
	self_cell@1.3.0
	semver@1.0.27
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.151
	sharded-slab@0.1.7
	shlex@1.3.0
	simd-adler32@0.3.7
	simd-json@0.18.1
	simdutf8@0.1.5
	slab@0.4.11
	smallvec@1.15.1
	static_assertions@1.1.0
	statrs@0.18.0
	syn@2.0.117
	syn@3.0.0
	thiserror-impl@2.0.20
	thiserror@2.0.20
	thread_local@1.1.9
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing-subscriber@0.3.23
	tracing@0.1.44
	unicode-ident@1.0.24
	unicode-segmentation@1.12.0
	value-trait@0.12.1
	vfs@0.13.0
	walkdir@2.5.0
	wasi@0.11.1+wasi-snapshot-preview1
	winapi-util@0.1.11
	windows-collections@0.3.2
	windows-core@0.62.2
	windows-future@0.3.2
	windows-implement@0.60.2
	windows-interface@0.59.3
	windows-link@0.2.1
	windows-numerics@0.3.1
	windows-result@0.4.1
	windows-strings@0.5.1
	windows-sys@0.59.0
	windows-sys@0.60.2
	windows-sys@0.61.2
	windows-targets@0.52.6
	windows-targets@0.53.5
	windows-threading@0.2.1
	windows@0.62.2
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_gnullvm@0.53.1
	windows_aarch64_msvc@0.52.6
	windows_aarch64_msvc@0.53.1
	windows_i686_gnu@0.52.6
	windows_i686_gnu@0.53.1
	windows_i686_gnullvm@0.52.6
	windows_i686_gnullvm@0.53.1
	windows_i686_msvc@0.52.6
	windows_i686_msvc@0.53.1
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnu@0.53.1
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_gnullvm@0.53.1
	windows_x86_64_msvc@0.52.6
	windows_x86_64_msvc@0.53.1
	zerocopy-derive@0.8.48
	zerocopy@0.8.48
	zlib-rs@0.5.2
	zmij@1.0.21
"

inherit cargo

DESCRIPTION="Native Node.js binding of the Oxc module resolver"
HOMEPAGE="https://oxc.rs/ https://github.com/oxc-project/oxc-resolver"
SRC_URI="
	https://github.com/oxc-project/oxc-resolver/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/${P}"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD-2 ISC MIT MPL-2.0 ZLIB
"
SLOT="${PV}"
KEYWORDS="~amd64 ~arm64"

src_configure() {
	cargo_src_configure --frozen
}

src_compile() {
	cargo_src_compile -p oxc_resolver_napi
}

src_test() {
	:
}

src_install() {
	insinto /usr/$(get_libdir)/${P}
	newins "$(cargo_target_dir)/liboxc_resolver_napi.so" resolver.node
	fperms 0755 /usr/$(get_libdir)/${P}/resolver.node
}
