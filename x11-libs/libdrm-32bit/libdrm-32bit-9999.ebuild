# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
ABI=x86
inherit xorg-2 flag-o-matic

EGIT_REPO_URI="git://anongit.freedesktop.org/git/mesa/drm"

DESCRIPTION="X.Org libdrm library"
HOMEPAGE="http://dri.freedesktop.org/"
if [[ ${PV} = 9999* ]]; then
	SRC_URI=""
else
	SRC_URI="http://dri.freedesktop.org/${PN}/${P}.tar.bz2"
fi

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~sparc-solaris ~x64-solaris ~x86-solaris"
VIDEO_CARDS="exynos intel nouveau omap radeon vmware"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS} libkms"
RESTRICT="test" # see bug #236845

RDEPEND="dev-libs/libpthread-stubs
	video_cards_intel? ( >=x11-libs/libpciaccess-0.10 )"
DEPEND="${RDEPEND}
	app-emulation/emul-linux-x86-xlibs
	>=x11-libs/libpciaccess-0.10"

PATCHES=(
	"${FILESDIR}"/${PN}-2.4.28-solaris.patch
)

pkg_setup() {
        append-flags -m32

	XORG_CONFIGURE_OPTIONS=(
		--enable-udev
		$(use_enable video_cards_exynos exynos-experimental-api)
		$(use_enable video_cards_intel intel)
		$(use_enable video_cards_nouveau nouveau)
		$(use_enable video_cards_omap omap-experimental-api)
		$(use_enable video_cards_radeon radeon)
		$(use_enable video_cards_vmware vmwgfx-experimental-api)
		$(use_enable libkms)
	)

	xorg-2_pkg_setup
}

src_prepare() {
	if [[ ${PV} = 9999* ]]; then
		# tests are restricted, no point in building them
		sed -ie 's/tests //' "${S}"/Makefile.am
	fi
	xorg-2_src_prepare
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
}
