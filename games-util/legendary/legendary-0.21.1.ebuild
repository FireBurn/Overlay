# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1

DESCRIPTION="A free and open-source replacement for the Epic Games Launcher"
HOMEPAGE="https://legendary.gl/ https://github.com/legendary-gl/legendary"
SRC_URI="https://github.com/legendary-gl/${PN}/archive/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror"

RDEPEND="
	$(python_gen_cond_dep '
		dev-python/filelock[${PYTHON_USEDEP}]
		dev-python/pycryptodome[${PYTHON_USEDEP}]
		<dev-python/requests-3.0[${PYTHON_USEDEP}]
	')
"

src_prepare() {
	distutils-r1_src_prepare

	sed -i -e '/^\[build-system\]/,/^$/d' -e '/^\[tool\.uv/,$d' pyproject.toml || die
	cat >> pyproject.toml <<-EOF || die
		[build-system]
		requires = ["hatchling"]
		build-backend = "hatchling.build"

		[tool.hatch.build.targets.wheel]
		packages = ["legendary"]
	EOF

	# Gentoo's pycryptodome provides the Crypto namespace, not Cryptodome
	grep -rlZ Cryptodome legendary | xargs -0 sed -i 's/\bCryptodome\b/Crypto/g' || die
}
