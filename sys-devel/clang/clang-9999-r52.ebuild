# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/clang/clang-9999.ebuild,v 1.35 2013/02/04 08:50:49 mgorny Exp $

EAPI=5

PYTHON_COMPAT=( python{2_5,2_6,2_7} pypy{1_8,1_9} )
inherit python-r1 multilib-minimal

DESCRIPTION="C language family frontend for LLVM"
HOMEPAGE="http://clang.llvm.org/"
SRC_URI=""

LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="!sys-devel/clang-32bit"
RDEPEND="~sys-devel/llvm-${PV}[clang,${MULTILIB_USEDEP}]"

src_unpack(){
	mkdir -p "${S}"
}
