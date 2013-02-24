# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/glu"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-2"
	EXPERIMENTAL="true"
fi

inherit autotools-utils multilib ${GIT_ECLASS}

DESCRIPTION="The OpenGL Utility Library"
HOMEPAGE="http://cgit.freedesktop.org/mesa/glu/"

if [[ ${PV} = 9999* ]]; then
	SRC_URI=""
else
	SRC_URI="ftp://ftp.freedesktop.org/pub/mesa/${PN}/${P}.tar.bz2"
fi

LICENSE="SGI-B-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE="multilib static-libs"

DEPEND="media-libs/mesa
	media-libs/mesa-32bit"
RDEPEND="${DEPEND}
	!<=app-emulation/emul-linux-x86-opengl-20121202-r49
	=app-emulation/emul-linux-x86-opengl-20121202-r50
	!<media-libs/mesa-9"

foreachabi() {
	local ABI
	for ABI in $(get_all_abis); do
		multilib_toolchain_setup ${ABI}
		AUTOTOOLS_BUILD_DIR=${WORKDIR}/${ABI} "${@}"
	done
}

src_unpack() {
	default
	[[ $PV = 9999* ]] && git-2_src_unpack
}

src_prepare() {
	AUTOTOOLS_AUTORECONF=1 autotools-utils_src_prepare
}

src_configure() {
	foreachabi autotools-utils_src_configure
}

src_compile() {
	foreachabi autotools-utils_src_compile
}

src_install() {
	foreachabi autotools-utils_src_install
}

src_test() {
	:;
}
