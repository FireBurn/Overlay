# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )
DISTUTILS_SINGLE_IMPL=1
inherit distutils-r1

DESCRIPTION="Unofficial Amazon Games client"
HOMEPAGE="https://github.com/imLinguin/nile"
SRC_URI="https://github.com/imLinguin/nile/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror"

RDEPEND="
	$(python_gen_cond_dep '
		dev-python/json5[${PYTHON_USEDEP}]
		dev-python/platformdirs[${PYTHON_USEDEP}]
		dev-python/protobuf[${PYTHON_USEDEP}]
		dev-python/pycryptodome[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/zstandard[${PYTHON_USEDEP}]
	')
"

src_prepare() {
	distutils-r1_src_prepare

	# Upstream builds with PyInstaller; tell setuptools which package to ship
	cat >> pyproject.toml <<-EOT || die

	[tool.setuptools.packages.find]
	include = ["nile*"]
	EOT
}
