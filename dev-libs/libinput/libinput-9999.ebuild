# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

XORG_DRI=always
XORG_EAUTORECONF=yes
XORG_MODULE_REBUILD=yes

inherit xorg-2

DESCRIPTION="A library to handle input devices in Wayland compositors"
if [[ ${PV} == 9999* ]]; then
	EGIT_REPO_URI="git://anongit.freedesktop.org/wayland/libinput"
else
	SRC_URI="mirror://gentoo/${P}.tar.gz"
fi

KEYWORDS="~amd64 ~ia64 ~x86"

RDEPEND="sys-libs/mtdev
	virtual/libudev
	dev-libs/libevdev"
DEPEND="${RDEPEND}"
