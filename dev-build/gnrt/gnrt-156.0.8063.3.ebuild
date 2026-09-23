# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER=1.91.0
CRATES="
	addr2line@0.24.2
	adler2@2.0.0
	ahash@0.8.11
	anstream@0.6.18
	anstyle-parse@0.2.6
	anstyle-query@1.1.2
	anstyle-wincon@3.0.7
	anstyle@1.0.10
	anyhow@1.0.98
	atomic-waker@1.1.2
	autocfg@1.4.0
	backtrace@0.3.74
	base64@0.22.1
	bitflags@2.9.0
	block-buffer@0.10.4
	bumpalo@3.17.0
	bytes@1.10.1
	camino@1.1.9
	cargo-platform@0.1.9
	cargo-platform@0.2.0
	cargo_metadata@0.19.2
	cc@1.2.21
	cfg-expr@0.18.0
	cfg-if@1.0.0
	clap@4.5.37
	clap_builder@4.5.37
	clap_derive@4.5.32
	clap_lex@0.7.4
	colorchoice@1.0.3
	core-foundation-sys@0.8.7
	core-foundation@0.9.4
	cpufeatures@0.2.17
	crc32fast@1.4.2
	crossbeam-deque@0.8.6
	crossbeam-epoch@0.9.18
	crossbeam-utils@0.8.21
	crypto-common@0.1.6
	darling@0.20.11
	darling_core@0.20.11
	darling_macro@0.20.11
	debug-ignore@1.0.5
	derive_builder@0.20.2
	derive_builder_core@0.20.2
	derive_builder_macro@0.20.2
	diff@0.1.13
	digest@0.10.7
	displaydoc@0.2.5
	either@1.15.0
	encoding_rs@0.8.35
	env_filter@0.1.3
	env_logger@0.11.8
	equivalent@1.0.2
	errno@0.3.11
	fastrand@2.3.0
	filetime@0.2.25
	fixedbitset@0.5.7
	flate2@1.1.1
	fnv@1.0.7
	foreign-types-shared@0.1.1
	foreign-types@0.3.2
	form_urlencoded@1.2.1
	futures-channel@0.3.31
	futures-core@0.3.31
	futures-io@0.3.31
	futures-sink@0.3.31
	futures-task@0.3.31
	futures-util@0.3.31
	generic-array@0.14.7
	getrandom@0.2.16
	getrandom@0.3.2
	gimli@0.31.1
	glob@0.3.3
	guppy-workspace-hack@0.1.0
	guppy@0.17.18
	h2@0.4.10
	handlebars@6.3.2
	hashbrown@0.16.0
	heck@0.5.0
	http-body-util@0.1.3
	http-body@1.0.1
	http@1.3.1
	httparse@1.10.1
	hyper-rustls@0.27.5
	hyper-tls@0.6.0
	hyper-util@0.1.11
	hyper@1.6.0
	icu_collections@1.5.0
	icu_locid@1.5.0
	icu_locid_transform@1.5.0
	icu_locid_transform_data@1.5.1
	icu_normalizer@1.5.0
	icu_normalizer_data@1.5.1
	icu_properties@1.5.1
	icu_properties_data@1.5.1
	icu_provider@1.5.0
	icu_provider_macros@1.5.0
	ident_case@1.0.1
	idna@1.0.3
	idna_adapter@1.2.0
	indexmap@2.12.0
	ipnet@2.11.0
	is_terminal_polyfill@1.70.1
	itertools@0.14.0
	itoa@1.0.15
	js-sys@0.3.77
	libc@0.2.172
	libredox@0.1.3
	linux-raw-sys@0.9.4
	litemap@0.7.5
	log@0.4.27
	memchr@2.7.4
	mime@0.3.17
	miniz_oxide@0.8.8
	mio@1.0.3
	native-tls@0.2.14
	nested@0.1.1
	num-modular@0.6.1
	num-order@1.2.0
	object@0.36.7
	once_cell@1.21.3
	openssl-macros@0.1.1
	openssl-probe@0.1.6
	openssl-sys@0.9.108
	openssl@0.10.72
	pathdiff@0.2.3
	percent-encoding@2.3.1
	pest@2.8.0
	pest_derive@2.8.0
	pest_generator@2.8.0
	pest_meta@2.8.0
	petgraph@0.7.1
	pin-project-lite@0.2.16
	pin-utils@0.1.0
	pkg-config@0.3.32
	pretty_assertions@1.4.1
	prettyplease@0.2.32
	proc-macro2@1.0.103
	quote@1.0.40
	r-efi@5.2.0
	rayon-core@1.13.0
	rayon@1.12.0
	redox_syscall@0.5.12
	reqwest@0.12.15
	ring@0.17.14
	rustc-demangle@0.1.24
	rustix@1.0.7
	rustls-pemfile@2.2.0
	rustls-pki-types@1.12.0
	rustls-webpki@0.103.3
	rustls@0.23.27
	rustversion@1.0.20
	ryu@1.0.20
	schannel@0.1.27
	security-framework-sys@2.14.0
	security-framework@2.11.1
	semver@1.0.26
	serde@1.0.228
	serde_core@1.0.228
	serde_derive@1.0.228
	serde_json@1.0.140
	serde_spanned@0.6.8
	serde_urlencoded@0.7.1
	sha2@0.10.9
	shlex@1.3.0
	slab@0.4.9
	smallvec@1.15.0
	socket2@0.5.9
	spdx@0.12.0
	stable_deref_trait@1.2.0
	static_assertions@1.1.0
	strsim@0.11.1
	strum@0.27.1
	strum_macros@0.27.1
	subtle@2.6.1
	syn@2.0.110
	sync_wrapper@1.0.2
	synstructure@0.13.2
	system-configuration-sys@0.6.0
	system-configuration@0.6.1
	tar@0.4.44
	target-lexicon@0.13.2
	target-spec@3.4.2
	tempfile@3.19.1
	thiserror-impl@2.0.12
	thiserror@2.0.12
	tinystr@0.7.6
	tokio-native-tls@0.3.1
	tokio-rustls@0.26.2
	tokio-util@0.7.15
	tokio@1.44.2
	toml@0.8.22
	toml_datetime@0.6.9
	toml_datetime@0.7.3
	toml_edit@0.22.26
	toml_edit@0.23.7
	toml_parser@1.0.4
	toml_write@0.1.1
	toml_writer@1.0.4
	tower-layer@0.3.3
	tower-service@0.3.3
	tower@0.5.2
	tracing-core@0.1.33
	tracing@0.1.41
	try-lock@0.2.5
	typenum@1.18.0
	ucd-trie@0.1.7
	unicode-ident@1.0.18
	untrusted@0.9.0
	url@2.5.4
	utf16_iter@1.0.5
	utf8_iter@1.0.4
	utf8parse@0.2.2
	vcpkg@0.2.15
	version_check@0.9.5
	want@0.3.1
	wasi@0.11.0+wasi-snapshot-preview1
	wasi@0.14.2+wasi-0.2.4
	wasm-bindgen-backend@0.2.100
	wasm-bindgen-futures@0.4.50
	wasm-bindgen-macro-support@0.2.100
	wasm-bindgen-macro@0.2.100
	wasm-bindgen-shared@0.2.100
	wasm-bindgen@0.2.100
	web-sys@0.3.77
	windows-link@0.1.1
	windows-registry@0.4.0
	windows-result@0.3.2
	windows-strings@0.3.1
	windows-sys@0.52.0
	windows-sys@0.59.0
	windows-targets@0.52.6
	windows-targets@0.53.0
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_gnullvm@0.53.0
	windows_aarch64_msvc@0.52.6
	windows_aarch64_msvc@0.53.0
	windows_i686_gnu@0.52.6
	windows_i686_gnu@0.53.0
	windows_i686_gnullvm@0.52.6
	windows_i686_gnullvm@0.53.0
	windows_i686_msvc@0.52.6
	windows_i686_msvc@0.53.0
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnu@0.53.0
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_gnullvm@0.53.0
	windows_x86_64_msvc@0.52.6
	windows_x86_64_msvc@0.53.0
	winnow@0.7.13
	wit-bindgen-rt@0.39.0
	write16@1.0.0
	writeable@0.5.5
	xattr@1.5.0
	yansi@1.0.1
	yoke-derive@0.7.5
	yoke@0.7.5
	zerocopy-derive@0.7.35
	zerocopy@0.7.35
	zerofrom-derive@0.1.6
	zerofrom@0.1.6
	zeroize@1.8.1
	zerovec-derive@0.10.3
	zerovec@0.10.4
"

inherit cargo

DESCRIPTION="Generate GN build rules for Chromium Rust dependencies"
HOMEPAGE="https://chromium.googlesource.com/chromium/src/+/main/tools/crates/gnrt/"
SRC_URI="
	https://github.com/chromium-linux-tarballs/chromium-tarballs/releases/download/${PV}/chromium-${PV}-linux.tar.xz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/chromium-${PV}/tools/crates/gnrt"

LICENSE="BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions ISC MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="dev-libs/openssl:="
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

src_unpack() {
	tar -xf "${DISTDIR}/chromium-${PV}-linux.tar.xz" \
		"chromium-${PV}/tools/crates/gnrt" \
		"chromium-${PV}/build/rust/known-target-triples.txt" \
		"chromium-${PV}/LICENSE" || die
	local A=${A/chromium-${PV}-linux.tar.xz/}
	cargo_src_unpack
}

pkg_setup() {
	rust_pkg_setup
	local rust_prefix=$(get_rust_prefix)
	export CARGO="${rust_prefix%/}/bin/cargo" RUSTC="${rust_prefix%/}/bin/rustc"
}

src_prepare() {
	local targets=../../../build/rust/known-target-triples.txt
	awk '/^x86_64-unknown-linux-gnu$|^#/ || /^$/' "${targets}" > "${targets}.tmp" || die
	mv "${targets}.tmp" "${targets}" || die
	sed -i '
/        match rust_arch {/,/        }/c\
        match rust_arch {\
            RustTargetArch::X8664 => "current_cpu == \\\"x64\\\"",\
        }
/        match rust_os {/,/        }/c\
        match rust_os {\
            RustTargetOs::Linux => "current_os == \\\"linux\\\"",\
        }
' lib/condition.rs || die
	eapply_user
}

src_configure() {
	local rust_prefix=$(get_rust_prefix)
	export CARGO="${rust_prefix%/}/bin/cargo" RUSTC="${rust_prefix%/}/bin/rustc"
	cargo_gen_config
	cargo_src_configure --frozen
}

src_compile() {
	local rust_prefix=$(get_rust_prefix)
	export CARGO="${rust_prefix%/}/bin/cargo" RUSTC="${rust_prefix%/}/bin/rustc"
	cargo_gen_config
	cargo_src_compile
}

src_test() {
	:
}

src_install() {
	dobin "$(cargo_target_dir)/gnrt"
	dodoc README.md
}
