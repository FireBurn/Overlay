# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3
inherit games eutils

DESCRIPTION="A physics-based action game where diff characters allow diff solutions to challenges"
HOMEPAGE="http://trine-thegame.com/"
SRC_URI="trineUpdate5.zip
	amd64? ( TrineUpdate4.64.run )"
	#x86? ( TrineUpdate4.32.run )

LICENSE="frozenbyte-eula"
SLOT="0"
KEYWORDS="-* amd64 ~x86"
IUSE="doc"
RESTRICT="fetch strip"

DEPEND="app-arch/unzip"
RDEPEND=">=sys-libs/glibc-2.4
	>=sys-devel/gcc-4.3.0
	gnome-base/libglade
	=media-libs/libsdl-1.2*
	=media-libs/sdl-image-1.2*
	=media-libs/sdl-ttf-2.0*
	media-libs/libogg
	=media-libs/openal-1*
	media-libs/libpng:1.2
	media-libs/libvorbis
	amd64? ( dev-libs/libx86 )"
#	virtual/ffmpeg
#	x11-libs/libtxc_dxtn"

S=${WORKDIR}

d="${GAMES_PREFIX_OPT}/${PN}"
QA_PRESTRIPPED="${d#/}/trine-launcher ${d#/}/trine-bin ${d#/}/lib*/lib*.so*"
QA_TEXTRELS_x86="`echo ${d#/}/lib32/lib{avcodec.so.51,avformat.so.52,avutil.so.49,FLAC.so.8}`"

bits=$(use x86 && echo 32 || echo 64)

pkg_nofetch() {
	echo
	elog "Please purchase and download '${SRC_URI}'"
	elog "then copy to: '${DISTDIR}'"
	echo
}

src_unpack() {
	# manually run unzip as the initial seek causes it to exit(1)
	unzip -q "${DISTDIR}/TrineUpdate4.${bits}.run"
	# overwrite existing binaries with patch
	unpack trineUpdate5.zip || die "unpack patch failed"
}

src_prepare() {
	rm lib*/lib{gcc_s,m,rt,selinux}.so.?

	# remove bundled libraries
	rm "${S}/lib${bits}/libstdc++.so.6"
	rm "${S}/lib${bits}/libSDL-1.2.so.0"
	rm "${S}/lib${bits}/libSDL_image-1.2.so.0"
	rm "${S}/lib${bits}/libSDL_ttf-2.0.so.0"
	rm "${S}/lib${bits}/libogg.so.0"
	rm "${S}/lib${bits}/libopenal.so.1"
	rm "${S}/lib${bits}/libpng12.so.0"
	rm "${S}/lib${bits}/libvorbis.so.0"
	rm "${S}/lib${bits}/libvorbisfile.so.3"

	# the following are no longer installed by default in Gentoo stable
	#rm "${S}/lib${bits}/libGLEW.so.1.5"
	#rm "${S}/lib${bits}/libjpeg.so.62"
	#rm "${S}/lib${bits}/libavcodec.so.52"
	#rm "${S}/lib${bits}/libavformat.so.52"
	#rm "${S}/lib${bits}/libavutil.so.50"
	#rm "${S}/lib${bits}/libswscale.so.0"
}

src_install() {
	local b bb

	newicon Trine.xpm ${PN}.xpm || die
	for b in bin launcher ; do
		bb="trine-${b}"
		exeinto ${d}
		newexe ${bb}${bits} ${bb} || die "newexe '${bb}' failed"
		games_make_wrapper ${bb} "./${bb}" "${d}" \
			|| die "make wrapper '${bb}' failed"
		make_desktop_entry ${bb} "Trine ${b}" ${PN} \
			|| die "make desktop '${bb}' failed"
	done

	exeinto ${d}/lib${bits}
	doexe lib${bits}/* || die

	insinto ${d}
	doins -r binds config data dev profiles *.fbz *.glade trine-logo.png || die

	dodoc Trine_updates.txt || die "dodoc required failed"
	if use doc; then
		dodoc Trine_Manual_linux.pdf || die "dodoc optional failed"
	fi

	prepgamesdirs
}

pkg_postinst() {
	einfo "To play the game, run:"
	einfo "${PN}"
	echo
	games_pkg_postinst
}
