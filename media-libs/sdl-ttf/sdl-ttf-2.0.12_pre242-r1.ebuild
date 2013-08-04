# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

inherit flag-o-matic toolchain-funcs mercurial versionator multilib-minimal

MY_PV=${PV/_pre/-}
EHG_REVISION=$(get_version_component_range 4 ${MY_PV})

DESCRIPTION="TrueType font decoding add-on for SDL"
HOMEPAGE="http://www.libsdl.org/projects/SDL_ttf"
EHG_REPO_URI="http://hg.libsdl.org/SDL_ttf"

LICENSE="ZLIB"
SLOT="2"
KEYWORDS="~amd64 ~x86"

#FIXME: Add "test".
IUSE="showfont static-libs X"

RDEPEND="
	media-libs/libsdl:2[${MULTILIB_USEDEP}]
	>=media-libs/freetype-2.3[${MULTILIB_USEDEP}]
	X? ( x11-libs/libXt[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}"

src_prepare() {
	multilib_copy_sources
}

multilib_src_configure() {
	if version_is_at_least 4.8 $(gcc-version); then
		append-flags "-fuse-ld=bfd"
	fi
	MISSING=true econf \
		$(use_enable static-libs static) \
		$(use_with X x)
}

multilib_src_install() {
	emake DESTDIR="${D}" install
	use static-libs || prune_libtool_files --all
	use showfont && newbin '.libs/showfont' "showfont2"
	dodoc {CHANGES,README}.txt
}
