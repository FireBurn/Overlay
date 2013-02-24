# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/glew/glew-1.9.0.ebuild,v 1.7 2013/01/26 11:52:16 ago Exp $

EAPI=5
ABI=x86

inherit multilib toolchain-funcs flag-o-matic

DESCRIPTION="The OpenGL Extension Wrangler Library"
HOMEPAGE="http://glew.sourceforge.net/"
MY_PN="glew"
MY_P=${MY_PN}-${PV}
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.tgz"

LICENSE="BSD MIT"
SLOT="0"
KEYWORDS="amd64"
IUSE="doc static-libs"

RDEPEND="=media-libs/glu-9999-r50
	!<=app-emulation/emul-linux-x86-opengl-20121202-r49
	=app-emulation/emul-linux-x86-opengl-20121202-r50"
DEPEND=${RDEPEND}

S=${WORKDIR}/${MY_P}

pkg_setup() {
	append-flags -m32
	append-ldflags -m32

	myglewopts=(
		AR="$(tc-getAR)"
		STRIP=true
		CC="$(tc-getCC)"
		LD="$(tc-getCC) ${LDFLAGS}"
		M_ARCH=""
		LDFLAGS.EXTRA=""
		POPT="${CFLAGS}"
	)
}

src_prepare() {
	sed -i \
		-e '/INSTALL/s:-s::' \
		-e '/$(CC) $(CFLAGS) -o/s:$(CFLAGS):$(CFLAGS) $(LDFLAGS):' \
		Makefile || die

	if ! use static-libs ; then
		sed -i \
			-e '/glew.lib:/s|lib/$(LIB.STATIC) ||' \
			-e '/glew.lib.mx:/s|lib/$(LIB.STATIC.MX) ||' \
			-e '/INSTALL.*LIB.STATIC/d' \
			Makefile || die
	fi

	# don't do stupid Solaris specific stuff that won't work in Prefix
	cp config/Makefile.linux config/Makefile.solaris || die
	# and let freebsd be built as on linux too
	cp config/Makefile.linux config/Makefile.freebsd || die
}

src_compile(){
	emake GLEW_DEST="${EPREFIX}/usr" "${myglewopts[@]}"
}

src_install() {
	emake \
		GLEW_DEST="${ED}/usr" \
		LIBDIR="${ED}/usr/$(get_libdir)" \
		"${myglewopts[@]}" \
		install.all

	dodoc TODO.txt
	use doc && dohtml doc/*

	rm -rf "${D}"/usr/bin || die "Removing bin files failed."
	rm -rf "${D}"/usr/share || die "Removing man files failed."
	rm -rf "${D}"/usr/include || die "Removing include files failed."
}
