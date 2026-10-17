# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1

# jmacd/xdelta submodule commit at v${PV}
XDELTA_COMMIT="0525275fe4b553a10f38e455d30c60dc6ed9b45d"

DESCRIPTION="GOG download module for Heroic Games Launcher"
HOMEPAGE="https://github.com/Heroic-Games-Launcher/heroic-gogdl"
SRC_URI="
	https://github.com/Heroic-Games-Launcher/heroic-gogdl/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz
	https://github.com/jmacd/xdelta/archive/${XDELTA_COMMIT}.tar.gz -> xdelta-${XDELTA_COMMIT}.gh.tar.gz
"
S="${WORKDIR}/heroic-gogdl-${PV}"

LICENSE="GPL-3 Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror"

RDEPEND="
	$(python_gen_cond_dep '
		dev-python/requests[${PYTHON_USEDEP}]
	')
"

src_unpack() {
	default
	rmdir "${S}/xdelta3" || die
	mv "${WORKDIR}/xdelta-${XDELTA_COMMIT}" "${S}/xdelta3" || die
}
