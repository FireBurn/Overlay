# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

inherit eutils mercurial versionator multilib-minimal

MY_PV=${PV/_pre/-}
EHG_REVISION=$(get_version_component_range 4 ${MY_PV})

DESCRIPTION="Image file loading library"
HOMEPAGE="http://www.libsdl.org/projects/SDL_image"
EHG_REPO_URI="http://hg.libsdl.org/SDL_image"

LICENSE="ZLIB"
SLOT="2"
KEYWORDS="~amd64 ~x86"

#FIXME: Add "test".
IUSE="showimage static-libs +bmp +gif +jpeg +lbm +pcx +png +pnm +tga +tiff +xcf +xv +xpm +webp"

RDEPEND="
	media-libs/libsdl:2[${MULTILIB_USEDEP}]
	jpeg? ( virtual/jpeg[${MULTILIB_USEDEP}] )
	png?  ( >=media-libs/libpng-1.5.7[${MULTILIB_USEDEP}] >=sys-libs/zlib-1.2.5[${MULTILIB_USEDEP}] )
	tiff? ( >=media-libs/tiff-4.0.0[${MULTILIB_USEDEP}] )
	webp? ( >=media-libs/libwebp-0.1.3[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/SDL_image-${MY_PV}"

src_prepare() {
	multilib_copy_sources
}

multilib_src_configure() {
	local myeconfargs=(
		# Disable support for OS X ImageIO library.
		--disable-imageio
		$(use_enable static-libs static)
		$(use_enable bmp)
		$(use_enable gif)
		$(use_enable jpeg jpg)
		$(use_enable lbm)
		$(use_enable pcx)
		$(use_enable png)
		$(use_enable pnm)
		$(use_enable tga)
		$(use_enable tiff tif)
		$(use_enable xcf)
		$(use_enable xv)
		$(use_enable xpm)
		$(use_enable webp)
	)

	# SDL_image 2.0 ships with a demonstrably horrible "configure" script. By
	# default, this script adds globals to the created "Makefile" resembling:
	#
	#   AUTOCONF = /bin/sh /var/tmp/portage/media-libs/sdl-image-9999/work/SDL_image/missing --run autoconf-1.10
	#
	# On running "make", "Makefile" then attempts to run the expansion of
	# "$(AUTOCONF)". Since the system is unlikely to have autoconf-1.0, the
	# "missing" script naturally fails with non-zero exit status. To sidestep
	# this insanity, force "configure" to instead set globals resembling:
	#
	#   AUTOCONF = true --run autoconf-1.10
	#
	# Since "true" always succeeds with zero exit status, this forces sanity.
	MISSING=true econf "${myeconfargs[@]}"
}

multilib_src_install() {
	emake DESTDIR="${D}" install
	dodoc {CHANGES,README}.txt
	use static-libs || prune_libtool_files --all

	# Prevent SDL 2.0's "showimage" from colliding with SDL 1.2's "showimage".
	use showimage && newbin '.libs/showimage' "showimage2"
}
