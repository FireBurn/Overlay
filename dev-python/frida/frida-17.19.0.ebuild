# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit pypi python-r1

DESCRIPTION="Dynamic instrumentation toolkit for developers, reverse-engineers, and researchers"
HOMEPAGE="https://frida.re/ https://github.com/frida/frida-python"

# Upstream's sdist downloads a prebuilt frida-core devkit at build time, so
# the prebuilt wheel is no less "from source"
SRC_URI="
	amd64? ( $(pypi_wheel_url ${PN} ${PV} cp37 abi3-manylinux1_x86_64) )
	arm64? ( $(pypi_wheel_url ${PN} ${PV} cp37 abi3-manylinux_2_17_aarch64) )
	x86? ( $(pypi_wheel_url ${PN} ${PV} cp37 abi3-manylinux1_i686) )
"

S="${WORKDIR}"
LICENSE="wxWinLL-3.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="
	${PYTHON_DEPS}
	dev-python/gpep517[${PYTHON_USEDEP}]
"
RDEPEND="${PYTHON_DEPS}"

QA_PREBUILT="usr/lib*/python*/*-packages/frida/_frida.abi3.so"

src_unpack() {
	:
}

src_install() {
	local wheel
	case ${ARCH} in
		amd64) wheel="${DISTDIR}/${P}-cp37-abi3-manylinux1_x86_64.whl" ;;
		arm64) wheel="${DISTDIR}/${P}-cp37-abi3-manylinux_2_17_aarch64.whl" ;;
		x86)   wheel="${DISTDIR}/${P}-cp37-abi3-manylinux1_i686.whl" ;;
		*)     die "Unsupported architecture: ${ARCH}" ;;
	esac

	install_wheel() {
		gpep517 install-wheel --destdir="${D}" --interpreter="${PYTHON}" "${wheel}" || die
		python_optimize "${D}$(python_get_sitedir)"
	}
	python_foreach_impl install_wheel
}
