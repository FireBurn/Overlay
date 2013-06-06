# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/glu"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-2"
	EXPERIMENTAL="true"
fi

inherit autotools-utils ${GIT_ECLASS} multilib-minimal

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
IUSE="static-libs"

DEPEND="media-libs/mesa[${MULTILIB_USEDEP}]"
RDEPEND="${DEPEND}
	!<=app-emulation/emul-linux-x86-opengl-20130224-r50
	!<media-libs/mesa-9"

src_unpack() {
	default
	[[ $PV = 9999* ]] && git-2_src_unpack
}

src_prepare() {
	eautoreconf
	multilib_copy_sources
}
