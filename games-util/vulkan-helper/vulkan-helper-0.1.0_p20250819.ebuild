# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	anstream@0.3.2
	anstyle-parse@0.2.1
	anstyle-query@1.0.0
	anstyle-wincon@1.0.1
	anstyle@1.0.1
	ash@0.37.3+1.3.251
	bitflags@1.3.2
	cc@1.0.79
	cfg-if@1.0.0
	clap@4.3.5
	clap_builder@4.3.5
	clap_derive@4.3.2
	clap_lex@0.5.0
	colorchoice@1.0.0
	errno-dragonfly@0.1.2
	errno@0.3.1
	heck@0.4.1
	hermit-abi@0.3.1
	io-lifetimes@1.0.11
	is-terminal@0.4.7
	itoa@1.0.6
	libc@0.2.147
	libloading@0.7.4
	linux-raw-sys@0.3.8
	once_cell@1.18.0
	proc-macro2@1.0.60
	quote@1.0.28
	rustix@0.37.20
	ryu@1.0.13
	serde@1.0.164
	serde_derive@1.0.164
	serde_json@1.0.97
	strsim@0.10.0
	syn@2.0.18
	unicode-ident@1.0.9
	utf8parse@0.2.1
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-sys@0.48.0
	windows-targets@0.48.0
	windows_aarch64_gnullvm@0.48.0
	windows_aarch64_msvc@0.48.0
	windows_i686_gnu@0.48.0
	windows_i686_msvc@0.48.0
	windows_x86_64_gnu@0.48.0
	windows_x86_64_gnullvm@0.48.0
	windows_x86_64_msvc@0.48.0
"

inherit cargo

# Upstream tags no releases
COMMIT="b2fdbab594dc4d41987fcdcdb893c7441d804550"

DESCRIPTION="Reports Vulkan instance and device versions for Heroic Games Launcher"
HOMEPAGE="https://github.com/imLinguin/vulkan-helper-rs"
SRC_URI="
	https://github.com/imLinguin/vulkan-helper-rs/archive/${COMMIT}.tar.gz -> ${P}.gh.tar.gz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/vulkan-helper-rs-${COMMIT}"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+=" Apache-2.0 MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror"

RDEPEND="media-libs/vulkan-loader"

QA_FLAGS_IGNORED="usr/bin/vulkan-helper"

src_install() {
	cargo_src_install
	dodoc README.md
}
