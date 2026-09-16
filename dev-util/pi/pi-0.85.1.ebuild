# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit wrapper

DESCRIPTION="AI agent toolkit and interactive coding agent CLI"
HOMEPAGE="https://pi.dev https://github.com/earendil-works/pi"

URI_BASE="https://github.com/earendil-works/pi/releases/download/v${PV}"
SRC_URI="
	amd64? (
		${URI_BASE}/pi-linux-x64.tar.gz
			-> ${P}-linux-x64.tar.gz
	)
	arm64? (
		${URI_BASE}/pi-linux-arm64.tar.gz
			-> ${P}-linux-arm64.tar.gz
	)
"

S="${WORKDIR}/pi"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror strip"

QA_PREBUILT="opt/${PN}/*"

RDEPEND="
	dev-vcs/git
	sys-apps/fd
	sys-apps/ripgrep
	sys-libs/glibc
"

src_install() {
	insinto /opt/${PN}
	doins -r .

	fperms +x /opt/${PN}/pi

	make_wrapper pi "${EPREFIX}/opt/${PN}/pi"

	einstalldocs
}
