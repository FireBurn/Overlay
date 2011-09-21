# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/libav/libav-0.7.1.ebuild,v 1.1 2011/07/23 16:32:19 lu_zero Exp $

EAPI=4

if [[ ${PV} == *9999 ]] ; then
	SCM="git-2"
	EGIT_REPO_URI="git://git.libav.org/libav.git"
	[[ ${PV%9999} != "" ]] && EGIT_BRANCH="release/${PV%.9999}"
fi

inherit eutils flag-o-matic multilib toolchain-funcs ${SCM}

DESCRIPTION="Complete solution to record, convert and stream audio and video."
HOMEPAGE="http://libav.org/"
if [[ ${PV} == *9999 ]] ; then
	SRC_URI=""
elif [[ ${PV%_p*} != ${PV} ]] ; then # Gentoo snapshot
	SRC_URI="mirror://gentoo/${P}.tar.xz"
else # Official release
	SRC_URI="http://${PN}.org/releases/${P}.tar.xz"
fi

LICENSE="LGPL-2 gpl? ( GPL-3 )"
SLOT="0"
[[ ${PV} == *9999 ]] || KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64
~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos
~x64-solaris ~x86-solaris"
IUSE="+3dnow +3dnowext aac alsa altivec amr bindist +bzip2 cpudetection custom-cflags debug dirac doc +encode faac frei0r +gpl gsm +hardcoded-tables ieee1394 jack jpeg2k +mmx +mmxext mp3 network oss pic qt-faststart rtmp schroedinger sdl speex +ssse3 static-libs test theora threads v4l v4l2 vaapi vdpau vorbis vpx X x264 xvid +zlib"

VIDEO_CARDS="nvidia"
for x in ${VIDEO_CARDS}; do
	IUSE="${IUSE} video_cards_${x}"
done

RDEPEND="
	!media-video/ffmpeg
	alsa? ( media-libs/alsa-lib )
	amr? ( media-libs/opencore-amr )
	bzip2? ( app-arch/bzip2 )
	dirac? ( media-video/dirac )
	encode? (
		aac? ( media-libs/vo-aacenc )
		amr? ( media-libs/vo-amrwbenc )
		faac? ( media-libs/faac )
		mp3? ( >=media-sound/lame-3.98.3 )
		theora? ( >=media-libs/libtheora-1.1.1[encode] media-libs/libogg )
		vorbis? ( media-libs/libvorbis media-libs/libogg )
		x264? ( >=media-libs/x264-0.0.20110426 )
		xvid? ( >=media-libs/xvid-1.1.0 )
	)
	frei0r? ( media-plugins/frei0r-plugins )
	gsm? ( >=media-sound/gsm-1.0.12-r1 )
	ieee1394? ( media-libs/libdc1394 sys-libs/libraw1394 )
	jack? ( media-sound/jack-audio-connection-kit )
	jpeg2k? ( >=media-libs/openjpeg-1.3-r2 )
	rtmp? ( >=media-video/rtmpdump-2.2f )
	sdl? ( >=media-libs/libsdl-1.2.13-r1[audio,video] )
	schroedinger? ( media-libs/schroedinger )
	speex? ( >=media-libs/speex-1.2_beta3 )
	vaapi? ( x11-libs/libva )
	video_cards_nvidia? ( vdpau? ( x11-libs/libvdpau ) )
	vpx? ( >=media-libs/libvpx-0.9.6 )
	X? ( x11-libs/libX11 x11-libs/libXext )
	zlib? ( sys-libs/zlib )
"

DEPEND="${RDEPEND}
	>=sys-devel/make-3.81
	dirac? ( dev-util/pkgconfig )
	doc? ( app-text/texi2html )
	mmx? ( dev-lang/yasm )
	rtmp? ( dev-util/pkgconfig )
	schroedinger? ( dev-util/pkgconfig )
	test? ( net-misc/wget )
	v4l? ( sys-kernel/linux-headers )
	v4l2? ( sys-kernel/linux-headers )
"

# faac can't be binary distributed
# faac and aac are concurent implementations
# amr and aac require gpl
REQUIRED_USE="bindist? ( !faac )
	faac? ( !aac ) aac? ( !faac )
	amr? ( gpl ) aac? ( gpl )"

src_prepare() {
	# if we have snapshot then we need to hardcode the version
	if [[ ${PV%_p*} != ${PV} ]]; then
		sed -i -e "s/UNKNOWN/DATE-${PV#*_pre}/" "${S}/version.sh" || die
	fi
}

src_configure() {
	local myconf="${EXTRA_FFMPEG_CONF}"
	local uses i

	myconf="
		$(use_enable gpl)
		$(use_enable gpl version3)
		--enable-postproc
		--enable-avfilter
	"

	# enabled by default
	uses="debug doc network vaapi zlib"
	for i in ${uses}; do
		use ${i} || myconf+=" --disable-${i}"
	done
	use bzip2 || myconf+=" --disable-bzlib"
	use sdl || myconf+=" --disable-ffplay"

	use custom-cflags && myconf+=" --disable-optimizations"
	use cpudetection && myconf+=" --enable-runtime-cpudetect"

	#for i in h264_vdpau mpeg1_vdpau mpeg_vdpau vc1_vdpau wmv3_vdpau; do
	#	use video_cards_nvidia || myconf="${myconf} --disable-decoder=${i}"
	#	use vdpau || myconf="${myconf} --disable-decoder=${i}"
	#done
	use video_cards_nvidia && use vdpau || myconf+=" --disable-vdpau"

	# Encoders
	if use encode; then
		use mp3 && myconf+=" --enable-libmp3lame"
		use amr && myconf+=" --enable-libvo-amrwbenc"
		use faac && myconf+=" --enable-libfaac --enable-nonfree"
		use aac && myconf+=" --enable-libvo-aacenc"
		uses="theora vorbis x264 xvid"
		for i in ${uses}; do
			use ${i} && myconf+=" --enable-lib${i}"
		done
	else
		myconf+=" --disable-encoders"
	fi

	# libavdevice options
	use ieee1394 && myconf+=" --enable-libdc1394"
	# Indevs
	for i in v4l v4l2 alsa oss jack; do
		use ${i} || myconf+=" --disable-indev=${i}"
	done
	use X && myconf+=" --enable-x11grab"
	# Outdevs
	for i in alsa oss ; do
		use ${i} || myconf+=" --disable-outdev=${i}"
	done
	# libavfilter options
	use frei0r && myconf+=" --enable-frei0r"

	# Threads; we only support pthread for now but ffmpeg supports more
	use threads && myconf+=" --enable-pthreads"

	# Decoders
	use amr && myconf+=" --enable-libopencore-amrwb --enable-libopencore-amrnb"
	uses="gsm dirac rtmp schroedinger speex vpx"
	for i in ${uses}; do
		use ${i} && myconf+=" --enable-lib${i}"
	done
	use jpeg2k && myconf+=" --enable-libopenjpeg"

	# CPU features
	uses="mmx ssse3 altivec"
	for i in ${uses}; do
		use ${i} || myconf+=" --disable-${i}"
	done
	use mmxext || myconf+=" --disable-mmx2"
	use 3dnow || myconf+=" --disable-amd3dnow"
	use 3dnowext || myconf+=" --disable-amd3dnowext"
	# disable mmx accelerated code if PIC is required
	# as the provided asm decidedly is not PIC for x86.
	if use pic && use x86 ; then
		myconf+=" --disable-mmx --disable-mmx2"
	fi

	# Option to force building pic
	use pic && myconf+=" --enable-pic"

	# Try to get cpu type based on CFLAGS.
	# Bug #172723
	# We need to do this so that features of that CPU will be better used
	# If they contain an unknown CPU it will not hurt since ffmpeg's configure
	# will just ignore it.
	for i in $(get-flag march) $(get-flag mcpu) $(get-flag mtune) ; do
		[ "${i}" = "native" ] && i="host" # bug #273421
		[[ ${i} = *-sse3 ]] && i="${i%-sse3}" # bug 283968
		myconf+=" --cpu=${i}"
		break
	done

	# cross compile support
	if tc-is-cross-compiler ; then
		myconf+=" --enable-cross-compile --arch=$(tc-arch-kernel) --cross-prefix=${CHOST}-"
		case ${CHOST} in
			*freebsd*)
				myconf+=" --target-os=freebsd"
				;;
			mingw32*)
				myconf+=" --target-os=mingw32"
				;;
			*linux*)
				myconf+=" --target-os=linux"
				;;
		esac
	fi

	# Misc stuff
	use hardcoded-tables && myconf+=" --enable-hardcoded-tables"

	# Specific workarounds for too-few-registers arch...
	if [[ $(tc-arch) == "x86" ]]; then
		filter-flags -fforce-addr -momit-leaf-frame-pointer
		append-flags -fomit-frame-pointer
		is-flag -O? || append-flags -O2
		if use debug; then
			# no need to warn about debug if not using debug flag
			ewarn ""
			ewarn "Debug information will be almost useless as the frame pointer is omitted."
			ewarn "This makes debugging harder, so crashes that has no fixed behavior are"
			ewarn "difficult to fix. Please have that in mind."
			ewarn ""
		fi
	fi

	cd "${S}"
	./configure \
		--prefix="$EPREFIX"/usr \
		--libdir="$EPREFIX"/usr/$(get_libdir) \
		--shlibdir="$EPREFIX"/usr/$(get_libdir) \
		--mandir="$EPREFIX"/usr/share/man \
		--enable-shared \
		--cc="$(tc-getCC)" \
		$(use_enable static-libs static) \
		${myconf} || die
}

src_compile() {
	emake version.h
	emake

	if use qt-faststart; then
		tc-export CC
		emake -C tools qt-faststart
	fi
}

src_install() {
	emake DESTDIR="${D}" install install-man

	dodoc Changelog README INSTALL
	dodoc doc/*

	if use qt-faststart; then
		dobin tools/qt-faststart
	fi
}

src_test() {
	local i tests
	if use encode; then
		tests="codectest lavftest seektest"
		for i in ${tests}; do
			LD_LIBRARY_PATH="${S}/libavcore:${S}/libpostproc:${S}/libswscale:${S}/libavcodec:${S}/libavdevice:${S}/libavfilter:${S}/libavformat:${S}/libavutil" \
				emake ${i}
		done
	else
		ewarn "Tests fail without USE=encode, skipping"
	fi
}
