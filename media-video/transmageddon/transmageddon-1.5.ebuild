# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit autotools python

PYTHON_DEPEND="2:2.7"

DESCRIPTION="Simple python application for transcoding video into formats
supported by GStreamer."
HOMEPAGE="http://www.linuxrising.org/index.html"
SRC_URI="http://www.linuxrising.org/files/${P}.tar.xz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="ffmpeg nls"

DEPEND="media-libs/gstreamer
	media-libs/gst-plugins-base
	media-plugins/gst-plugins-meta
	dev-python/pygobject
	dev-python/pycairo
	dev-python/pygtk
	>=dev-python/gst-python-0.10.22
	ffmpeg? ( media-plugins/gst-plugins-ffmpeg ) "
RDEPEND="${DEPEND}"

src_prepare() {
	eautomake || die "Automake failed."
}

src_configure() {
	econf \
		$(use_enable nls) \
		|| die "Configure failed."
}

src_compile() {
	emake || die "Make failed."
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed."
	dodoc AUTHORS NEWS TODO
}

pkg_postinst() {
	ewarn
	ewarn "If transmageddon fails to convert some video or audio format,"
	ewarn "please check your USE flags on media-plugins/gst-plugins-meta"
	ewarn
}
