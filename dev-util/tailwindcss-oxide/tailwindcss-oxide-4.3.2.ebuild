# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER=1.95.0
CRATES="
	aho-corasick@1.1.3
	arrayvec@0.7.6
	bexpand@1.2.0
	bitflags@2.6.0
	bstr@1.11.3
	cfg-if@1.0.0
	convert_case@0.11.0
	crossbeam-channel@0.5.15
	crossbeam-deque@0.8.5
	crossbeam-epoch@0.9.18
	crossbeam-utils@0.8.20
	ctor-proc-macro@0.0.13
	ctor@0.10.1
	diff@0.1.13
	dtor-proc-macro@0.0.13
	dtor@0.8.1
	dunce@1.0.5
	either@1.8.1
	errno@0.3.9
	fast-glob@0.4.3
	fastrand@2.1.1
	futures-channel@0.3.32
	futures-core@0.3.32
	futures-executor@0.3.32
	futures-io@0.3.32
	futures-macro@0.3.32
	futures-sink@0.3.32
	futures-task@0.3.32
	futures-util@0.3.32
	futures@0.3.32
	globset@0.4.17
	globwalk@0.9.1
	ignore@0.4.23
	itertools@0.11.0
	lazy_static@1.4.0
	libc@0.2.159
	libloading@0.9.0
	linux-raw-sys@0.4.14
	log@0.4.22
	matchers@0.1.0
	memchr@2.7.4
	minimal-lexical@0.2.1
	napi-build@2.3.1
	napi-derive-backend@5.0.3
	napi-derive@3.5.4
	napi-sys@3.2.1
	napi@3.8.5
	nohash-hasher@0.2.0
	nom@7.1.3
	nu-ansi-term@0.46.0
	once_cell@1.19.0
	overload@0.1.1
	pin-project-lite@0.2.9
	pretty_assertions@1.4.1
	proc-macro2@1.0.86
	quote@1.0.45
	rayon-core@1.12.1
	rayon@1.10.0
	regex-automata@0.1.10
	regex-automata@0.4.8
	regex-syntax@0.6.29
	regex-syntax@0.8.5
	regex@1.11.1
	rustc-hash@2.1.1
	rustix@0.38.37
	same-file@1.0.6
	semver@1.0.17
	serde@1.0.163
	sharded-slab@0.1.4
	slab@0.4.12
	smallvec@1.10.0
	syn@2.0.87
	tempfile@3.13.0
	thread_local@1.1.7
	tracing-attributes@0.1.27
	tracing-core@0.1.32
	tracing-log@0.2.0
	tracing-subscriber@0.3.18
	tracing@0.1.40
	unicode-ident@1.0.9
	unicode-segmentation@1.10.1
	unicode-width@0.2.0
	valuable@0.1.0
	walkdir@2.5.0
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-util@0.1.5
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-link@0.2.1
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
	yansi@1.0.1
"

inherit cargo

DESCRIPTION="Native Node.js binding of the Tailwind CSS Oxide engine"
HOMEPAGE="https://tailwindcss.com/"
SRC_URI="
	https://github.com/tailwindlabs/tailwindcss/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/tailwindcss-${PV}"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	ISC MIT MPL-2.0
	|| ( Apache-2.0 CC0-1.0 MIT-0 )
"
SLOT="${PV}"
KEYWORDS="~amd64 ~arm64"

src_configure() {
	cargo_src_configure --frozen
}

src_compile() {
	cargo_src_compile -p tailwind-oxide
}

src_test() {
	:
}

src_install() {
	insinto /usr/$(get_libdir)/${P}
	newins "$(cargo_target_dir)/libtailwind_oxide.so" tailwindcss-oxide.node
	fperms 0755 /usr/$(get_libdir)/${P}/tailwindcss-oxide.node
}
