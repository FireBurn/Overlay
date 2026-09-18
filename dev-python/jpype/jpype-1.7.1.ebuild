# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=scikit-build-core
PYPI_PN="jpype1"
PYPI_NO_NORMALIZE=1
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Bridge to allow Python programs full access to Java class libraries"
HOMEPAGE="https://github.com/jpype-project/jpype/ https://pypi.org/project/JPype1/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

DEPEND="virtual/jdk:*"
RDEPEND="
	${DEPEND}
	dev-python/packaging[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/scikit-build-core[${PYTHON_USEDEP}]
	dev-python/pathspec[${PYTHON_USEDEP}]
"
