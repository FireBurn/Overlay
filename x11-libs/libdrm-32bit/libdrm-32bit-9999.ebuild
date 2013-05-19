# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
ABI=x86

inherit xorg-2

DESCRIPTION="X.Org libdrm library"
HOMEPAGE="http://dri.freedesktop.org/"
if [[ ${PV} = 9999* ]]; then
	EGIT_REPO_URI="git://anongit.freedesktop.org/git/mesa/drm"
else
	SRC_URI="http://dri.freedesktop.org/${PN}/${P}.tar.bz2"
fi

KEYWORDS="~amd64"
VIDEO_CARDS="exynos freedreno intel nouveau omap radeon vmware"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS} libkms"
RESTRICT="test" # see bug #236845

RDEPEND="dev-libs/libpthread-stubs
	video_cards_intel? ( >=x11-libs/libpciaccess-0.10 )"
DEPEND="${RDEPEND}
	!<=app-emulation/emul-linux-x86-opengl-20130224-r49
	=app-emulation/emul-linux-x86-xlibs-20130224-r50"

PATCHES=(
	"${FILESDIR}"/${PN}-2.4.28-solaris.patch
)

src_prepare() {
	if [[ ${PV} = 9999* ]]; then
		# tests are restricted, no point in building them
		sed -ie 's/tests //' "${S}"/Makefile.am
	fi
	xorg-2_src_prepare
}

src_configure() {
	append-flags -m32

	XORG_CONFIGURE_OPTIONS=(
		--enable-udev
		$(use_enable video_cards_exynos exynos-experimental-api)
		$(use_enable video_cards_freedreno freedreno-experimental-api)
		$(use_enable video_cards_intel intel)
		$(use_enable video_cards_nouveau nouveau)
		$(use_enable video_cards_omap omap-experimental-api)
		$(use_enable video_cards_radeon radeon)
		$(use_enable video_cards_vmware vmwgfx)
		$(use_enable libkms)
	)
	xorg-2_src_configure
}

src_install() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${CATEGORY} == x11-proto ]]; then
		autotools-utils_src_install \
			${PN/proto/}docdir="${EPREFIX}/usr/share/doc/${PF}" \
			docdir="${EPREFIX}/usr/share/doc/${PF}"
	else
		autotools-utils_src_install \
			docdir="${EPREFIX}/usr/share/doc/${PF}"
	fi

	if [[ -n ${GIT_ECLASS} ]]; then
		pushd "${EGIT_STORE_DIR}/${EGIT_CLONE_DIR}" > /dev/null
		git log ${EGIT_COMMIT} > "${S}"/ChangeLog
		popd > /dev/null
	fi

	if [[ -e "${S}"/ChangeLog ]]; then
		dodoc "${S}"/ChangeLog || die "dodoc failed"
	fi

	# Don't install libtool archives (even with static-libs)
	remove_libtool_files all

	[[ -n ${FONT} ]] && remove_font_metadata

	rm -rf "${D}"/usr/include* || die "Removing includes failed."
	rm -rf "${D}"/usr/share/man* || die "Removing man files failed."
}
