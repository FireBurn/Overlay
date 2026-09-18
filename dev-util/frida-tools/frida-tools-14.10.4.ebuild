# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYPI_NO_NORMALIZE=1
PYPI_PN="frida_tools"
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="CLI tools for Frida dynamic instrumentation toolkit"
HOMEPAGE="https://frida.re/ https://github.com/frida/frida-tools"

LICENSE="wxWinLL-3.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="test" # tests require running target/device environment

RDEPEND="
	>=dev-python/colorama-0.2.7[${PYTHON_USEDEP}]
	<dev-python/colorama-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/frida-17.10.0[${PYTHON_USEDEP}]
	<dev-python/frida-18.0.0[${PYTHON_USEDEP}]
	>=dev-python/prompt-toolkit-2.0.0[${PYTHON_USEDEP}]
	<dev-python/prompt-toolkit-4.0.0[${PYTHON_USEDEP}]
	>=dev-python/pygments-2.0.2[${PYTHON_USEDEP}]
	<dev-python/pygments-3.0.0[${PYTHON_USEDEP}]
	>=dev-python/websockets-13.0.0[${PYTHON_USEDEP}]
"
BDEPEND="
	>=dev-python/setuptools-60.0.0[${PYTHON_USEDEP}]
"
