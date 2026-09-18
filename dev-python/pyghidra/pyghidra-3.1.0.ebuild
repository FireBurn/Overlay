# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYPI_NO_NORMALIZE=1
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Native CPython integration for Ghidra"
HOMEPAGE="https://github.com/NationalSecurityAgency/ghidra https://pypi.org/project/pyghidra/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RDEPEND="
	>=dev-python/jpype-1.5.2[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
"
BDEPEND="
	>=dev-python/setuptools-61.0.0[${PYTHON_USEDEP}]
	dev-python/wheel[${PYTHON_USEDEP}]
"

src_prepare() {
	distutils-r1_src_prepare
	# Allow any compatible jpype >= 1.5.2
	sed -i 's/Jpype1==1.5.2/Jpype1>=1.5.2/' pyproject.toml || die
}
