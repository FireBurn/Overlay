# Copyright 2021-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="The open source AI coding agent (CLI)"
HOMEPAGE="https://opencode.ai https://github.com/anomalyco/opencode"

URI_BASE="https://github.com/anomalyco/opencode/releases/download/v${PV}"
SRC_URI="
	amd64? (
		elibc_glibc? (
			cpu_flags_x86_avx2? (
				${URI_BASE}/opencode-linux-x64.tar.gz
					-> ${P}-amd64-glibc.tar.gz
			)
			!cpu_flags_x86_avx2? (
				${URI_BASE}/opencode-linux-x64-baseline.tar.gz
					-> ${P}-amd64-baseline-glibc.tar.gz
			)
		)
		elibc_musl? (
			cpu_flags_x86_avx2? (
				${URI_BASE}/opencode-linux-x64-musl.tar.gz
					-> ${P}-amd64-musl.tar.gz
			)
			!cpu_flags_x86_avx2? (
				${URI_BASE}/opencode-linux-x64-baseline-musl.tar.gz
					-> ${P}-amd64-baseline-musl.tar.gz
			)
		)
	)
	arm64? (
		elibc_glibc? (
			${URI_BASE}/opencode-linux-arm64.tar.gz
				-> ${P}-arm64-glibc.tar.gz
		)
		elibc_musl? (
			${URI_BASE}/opencode-linux-arm64-musl.tar.gz
				-> ${P}-arm64-musl.tar.gz
		)
	)
"

S="${WORKDIR}"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="cpu_flags_x86_avx2"
RESTRICT="mirror strip"

QA_PREBUILT="usr/bin/opencode"

RDEPEND="
	dev-vcs/git
	sys-apps/ripgrep
"

src_install() {
	dobin opencode

	newbashcomp "${FILESDIR}/opencode.bash" opencode
}
