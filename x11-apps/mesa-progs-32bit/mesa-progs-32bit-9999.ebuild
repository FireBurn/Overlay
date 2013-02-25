# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
ABI="x86"

MY_PN="mesa-demos"
MY_P=${MY_PN}-${PV}
EGIT_REPO_URI="git://anongit.freedesktop.org/${MY_PN/-//}"
EGIT_PROJECT="mesa-progs"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-2"
	EXPERIMENTAL="true"
fi

inherit base autotools toolchain-funcs flag-o-matic ${GIT_ECLASS}

DESCRIPTION="Mesa's OpenGL utility and demo programs (glxgears and glxinfo)"
HOMEPAGE="http://mesa3d.sourceforge.net/"
if [[ ${PV} == 9999* ]]; then
	SRC_URI=""
else
	SRC_URI="ftp://ftp.freedesktop.org/pub/${MY_PN/-//}/${PV}/${MY_P}.tar.bz2"
fi

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="egl gles1 gles2"

RDEPEND="media-libs/mesa-32bit[egl?,gles1?,gles2?]
	virtual/opengl"
# glew and glu are only needed by the configure script which is only used
# when building EGL/GLESv1/GLESv2 programs. They are not actually required
# by the installed programs.
DEPEND="${RDEPEND}
	egl? (
		media-libs/glew-32bit
		=media-libs/glu-9999-r50
	)
	x11-proto/xproto"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	append-flags -m32
}

src_unpack() {
	default
	[[ $PV = 9999* ]] && git-2_src_unpack
}

src_prepare() {
	base_src_prepare

	eautoreconf
}

src_configure() {
	# We're not using the complete buildsystem if we only want to build
	# glxinfo and glxgears.
	if use egl || use gles1 || use gles2; then
		default_src_configure
	fi
}

src_compile() {
	if ! use egl && ! use gles1 && ! use gles2; then
		tc-export CC
		emake LDLIBS='-lX11 -lGL' src/xdemos/glxinfo
		emake LDLIBS='-lX11 -lGL -lm' src/xdemos/glxgears
	else
		emake -C src/xdemos glxgears glxinfo
	fi

	if use egl; then
		emake LDLIBS="-lEGL" -C src/egl/opengl/ eglinfo
		emake -C src/egl/eglut/ libeglut_screen.la libeglut_x11.la
		emake LDLIBS="-lGL -lEGL -lX11 -lm" -C src/egl/opengl/ eglgears_x11
		emake LDLIBS="-lGL -lEGL -lm" -C src/egl/opengl/ eglgears_screen

		if use gles1; then
			emake LDLIBS="-lGLESv1_CM -lEGL -lX11" -C src/egl/opengles1/ es1_info
			emake LDLIBS="-lGLESv1_CM -lEGL -lX11 -lm" -C src/egl/opengles1/ gears_x11
			emake LDLIBS="-lGLESv1_CM -lEGL -lm" -C src/egl/opengles1/ gears_screen
		fi
		if use gles2; then
			emake LDLIBS="-lGLESv2 -lEGL -lX11" -C src/egl/opengles2/ es2_info
			emake LDLIBS="-lGLESv2 -lEGL -lX11 -lm" -C src/egl/opengles2/ es2gears_x11
			emake LDLIBS="-lGLESv2 -lEGL -lm" -C src/egl/opengles2/ es2gears_screen
		fi
	fi
}

src_install() {
	mv src/xdemos/glxgears src/xdemos/glxgears32
	mv src/xdemos/glxinfo src/xdemos/glxinfo32
	dobin src/xdemos/{glxgears32,glxinfo32}
	if use egl; then
			mv src/egl/opengl/eglinfo src/egl/opengl/eglinfo32
			mv src/egl/opengl/eglgears_screen src/egl/opengl/eglgears_screen32
			mv src/egl/opengl/eglgears_x11 src/egl/opengl/eglgears_x11_32
			dobin src/egl/opengl/egl{info32,gears_{screen32,x11_32}}

		if use gles1; then
			mv src/egl/opengles1/es1_info src/egl/opengles1/es1_info32
			dobin src/egl/opengles1/es1_info32
			mv src/egl/opengles1/gears_screen src/egl/opengles1/gears_screen32
			mv src/egl/opengles1/gears_x11 src/egl/opengles1/gears_x11_32
			newbin src/egl/opengles1/gears_screen32 es1gears_screen32
			newbin src/egl/opengles1/gears_x11_32 es1gears_x11_32
		fi

		if use gles2; then
			mv src/egl/opengles2/es2_info src/egl/opengles2/es2_info32
			mv src/egl/opengles2/es2gears_screen src/egl/opengles2/es2gears_screen32
			mv src/egl/opengles2/es2gears_x11 src/egl/opengles2/es2gears_x11_32
			dobin src/egl/opengles2/es2{_info32,gears_{screen32,x11_32}}
		fi
	fi
}
