# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

MY_PN=${PN/progs/demos}
MY_P=${MY_PN}-${PV}
EGIT_REPO_URI="https://gitlab.freedesktop.org/${MY_PN/-//}.git"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-r3"
	EXPERIMENTAL="true"
fi

inherit base autotools toolchain-funcs ${GIT_ECLASS} multilib-minimal

DESCRIPTION="Mesa's OpenGL utility and demo programs (glxgears and glxinfo)"
HOMEPAGE="http://mesa3d.sourceforge.net/"
if [[ ${PV} == 9999* ]]; then
	SRC_URI=""
else
	SRC_URI="ftp://ftp.freedesktop.org/pub/${MY_PN/-//}/${PV}/${MY_P}.tar.bz2"
fi

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="egl gles1 gles2"

RDEPEND="
	media-libs/mesa[egl?,gles1?,gles2?,${MULTILIB_USEDEP}]
	virtual/opengl[${MULTILIB_USEDEP}]
	x11-libs/libX11[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	virtual/glu[${MULTILIB_USEDEP}]
	x11-base/xorg-proto"

S=${WORKDIR}/${MY_P}
EGIT_CHECKOUT_DIR=${S}

src_unpack() {
	default
	[[ $PV = 9999* ]] && git-r3_src_unpack
}

src_prepare() {
	base_src_prepare

	eautoreconf

	multilib_copy_sources
}

multilib_src_configure() {
	default_src_configure
}

multilib_src_compile() {
	emake -C src/glad/ libglad.la
	emake -C src/xdemos glxgears glxinfo

	if use egl; then
		emake LDLIBS="-lEGL" -C src/egl/opengl/ eglinfo
		emake -C src/egl/eglut/ libeglut_x11.la
		emake LDLIBS="-lGL -lEGL -lX11 -lm" -C src/egl/opengl/ eglgears_x11

		if use gles1; then
			emake LDLIBS="-lGLESv1_CM -lEGL -lX11" -C src/egl/opengles1/ es1_info
			emake LDLIBS="-lGLESv1_CM -lEGL -lX11 -lm" -C src/egl/opengles1/ gears_x11
		fi
		if use gles2; then
			emake LDLIBS="-lGLESv2 -lEGL -lX11" -C src/egl/opengles2/ es2_info
			emake LDLIBS="-lGLESv2 -lEGL -lX11 -lm" -C src/egl/opengles2/ es2gears_x11
		fi
	fi
}

multilib_src_install() {
	if multilib_is_native_abi; then
		dobin src/xdemos/{glxgears,glxinfo}
		if use egl; then
			dobin src/egl/opengl/egl{info,gears_x11}

			if use gles1; then
				dobin src/egl/opengles1/es1_info
				newbin src/egl/opengles1/gears_x11 es1gears_x11
			fi

			use gles2 && dobin src/egl/opengles2/es2{_info,gears_x11}
		fi
	else
		newbin src/xdemos/glxgears glxgears-${ABI}
		newbin src/xdemos/glxinfo glxinfo-${ABI}
		if use egl; then
			newbin src/egl/opengl/eglinfo eglinfo-${ABI}
			newbin src/egl/opengl/eglgears_x11 eglgears_x11-${ABI}

			if use gles1; then
				newbin src/egl/opengles1/es1_info es1_info-${ABI}
				newbin src/egl/opengles1/gears_x11 es1gears_x11-${ABI}
			fi

			if use gles2; then
				newbin src/egl/opengles2/es2_info es2_info-${ABI}
				newbin src/egl/opengles2/es2gears_x11 es2gearsx11-${ABI}
			fi
		fi
	fi
}
