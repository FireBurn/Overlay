# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI="git://people.freedesktop.org/~tstellar/${PN}"

if [[ ${PV} = 9999* ]]; then
        GIT_ECLASS="git-2"
        EXPERIMENTAL="true"
fi

PYTHON_COMPAT=( python{2_6,2_7} )

inherit base python-single-r1 $GIT_ECLASS

DESCRIPTION="OpenCL C library"
HOMEPAGE="http://libclc.llvm.org/"

if [[ $PV = 9999* ]]; then
        SRC_URI="${SRC_PATCHES}"
else
        SRC_URI=""
fi

LICENSE="MIT BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
        =sys-devel/clang-9999-r50[video_cards_radeon]
        =sys-devel/llvm-9999-r50[video_cards_radeon]"
DEPEND="${RDEPEND}"

src_configure() {
        ./configure.py \
                --with-llvm-config="${EPREFIX}/usr/bin/llvm-config" \
                --prefix="${EPREFIX}/usr"
}
