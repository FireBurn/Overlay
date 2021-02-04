# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="6"

inherit cmake-utils flag-o-matic versionator

DESCRIPTION="LuxCoreRender is a physically correct, unbiased rendering engine. It is built on physically based equations that model the transportation of light."
HOMEPAGE="http://www.luxcorerender.net"

if [[ "$PV" == "9999" ]] ; then
	inherit gir-r3

	EGIT_REPO_URI="https://github.com/LuxCoreRender/LuxCore.git"
else
	SRC_URI="https://codeload.github.com/LuxCoreRender/LuxCore/tar.gz/luxrender_v${PV} -> ${P}.tar.gz"

	einfo "$SRC_URI"
fi


LICENSE="GPL-3"
SLOT="1"
KEYWORDS="~amd64"
IUSE="debug opencl shared"

REQUIRED_USE="debug? ( shared )"

RDEPEND=">=dev-libs/boost-1.43:=
	media-libs/openimageio
	media-libs/embree
	virtual/opengl
	opencl? (
		dev-libs/clhpp
		virtual/opencl )"

DEPEND="${RDEPEND}"
S="${WORKDIR}/LuxCore-luxrender_v${PV}"

src_prepare() {

	rm "${S}/cmake/Packages/FindOpenCL.cmake"
	rm "${S}/cmake/Packages/FindEmbree.cmake"
	rm "${S}/cmake/Packages/FindGLEW.cmake"
	rm "${S}/cmake/Packages/FindGLUT.cmake"
	rm "${S}/cmake/Packages/FindOpenEXR.cmake"
	if use shared ; then
		epatch "${FILESDIR}/${PN}-shared_libs.patch"
	fi
	epatch "${FILESDIR}/${PN}-${SLOT}_cmake_python.patch"
	epatch "${FILESDIR}/${PN}-${SLOT}_cl2hpp.patch"
	epatch "${FILESDIR}/${P}_up_to_date_cpp.patch"
	epatch "${FILESDIR}/${P}_embree3.patch"
	cmake-utils_src_prepare
}


src_configure() {
	append-flags -fPIC
        use opencl || append-flags -DLUXRAYS_DISABLE_OPENCL
	if use debug ; then
		 append-flags -ggdb
		CMAKE_BUILD_TYPE="Debug"
	else
		CMAKE_BUILD_TYPE="Release"
	fi
	BoostPythons="$(equery u boost | grep -e 'python_targets_python[[:digit:]]_[[:digit:]]' | tr '\n' ';' | sed  -e 's/\([[:digit:]]\+\)_\([[:digit:]]\+\)/\1.\2/g'  -e 's/[+_\-]\+//g' -e 's;[[:alpha:]]\+;;g')"
	einfo "Boost python versions: $BoostPythons "
	mycmakeargs=( -DPythonVersions="${BoostPythons}")
	use opencl || mycmakeargs=( -DLUXRAYS_DISABLE_OPENCL=ON -Wno-dev -DPythonVersions="${BoostPythons}")
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_make luxcore
	cmake-utils_src_make smallluxgpu
	cmake-utils_src_make luxrays
}

src_install() {
	dodoc AUTHORS.txt

	insinto /usr/include/luxrays
	doins -r include/luxcore
	doins -r include/slg
	doins -r include/luxrays
	if use shared ; then
		newlib.so ${BUILD_DIR}/lib/libluxcore.so libluxcore-${SLOT}.so
		newlib.so ${BUILD_DIR}/lib/libsmallluxgpu.so libsmallluxgpu-${SLOT}.so
		newlib.so ${BUILD_DIR}/lib/libluxrays.so libluxrays-${SLOT}.so
	else
		newlib.a ${BUILD_DIR}/lib/libluxcore.a libluxcore-${SLOT}.a
		newlib.a ${BUILD_DIR}/lib/libsmallluxgpu.a libsmallluxgpu-${SLOT}.a
		newlib.a ${BUILD_DIR}/lib/libluxrays.a libluxrays-${SLOT}.a
	fi
}

