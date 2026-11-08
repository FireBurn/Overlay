# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit pypi python-r1

DESCRIPTION="CLI tools for Frida dynamic instrumentation toolkit"
HOMEPAGE="https://frida.re/ https://github.com/frida/frida-tools"

# The sdist rebuilds the TypeScript agents through npm and a node binding
# of frida-core. The wheel is pure Python and carries those agents already
# compiled to architecture-neutral JavaScript, so there is no native code in
# it to build.
SRC_URI="$(pypi_wheel_url ${PN} ${PV} py3 none-any)"
S=${WORKDIR}

LICENSE="wxWinLL-3.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
REQUIRED_USE=${PYTHON_REQUIRED_USE}
RESTRICT="test" # tests require running target/device environment

RDEPEND="
	${PYTHON_DEPS}
	>=dev-python/colorama-0.2.7[${PYTHON_USEDEP}]
	<dev-python/colorama-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/frida-17.26.0[${PYTHON_USEDEP}]
	<dev-python/frida-18.0.0[${PYTHON_USEDEP}]
	>=dev-python/prompt-toolkit-2.0.0[${PYTHON_USEDEP}]
	<dev-python/prompt-toolkit-4.0.0[${PYTHON_USEDEP}]
	>=dev-python/pygments-2.0.2[${PYTHON_USEDEP}]
	<dev-python/pygments-3.0.0[${PYTHON_USEDEP}]
	>=dev-python/websockets-13.0.0[${PYTHON_USEDEP}]
"
BDEPEND="
	${PYTHON_DEPS}
	dev-python/gpep517[${PYTHON_USEDEP}]
"

src_unpack() {
	:
}

src_install() {
	install_wheel() {
		gpep517 install-wheel --destdir="${D}" --interpreter="${PYTHON}" \
			"${DISTDIR}/frida_tools-${PV}-py3-none-any.whl" || die
		python_optimize "${D}$(python_get_sitedir)"
	}
	python_foreach_impl install_wheel
}
