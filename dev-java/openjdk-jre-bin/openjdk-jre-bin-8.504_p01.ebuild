# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit java-vm-2

abi_uri() {
	local os=linux libc=

	case ${3} in
		glibc) libc=elibc_glibc ;;
		llvm)  libc=elibc_llvm os=alpine-linux ;;
	esac

	echo "${2-$1}? (
		${libc:+ ${libc}? ( }
			https://github.com/adoptium/temurin${SLOT}-binaries/releases/download/jdk${MY_PV}/OpenJDK8U-jre_${1}_${os}_hotspot_${MY_PV/-/}.tar.gz
		${libc:+ ) } )"
}

MY_PV=$(ver_rs 1 'u' 2 '-' ${PV//p/b})
SLOT="$(ver_cut 1)"

DESCRIPTION="Prebuilt Java JRE binaries provided by Eclipse Temurin"
HOMEPAGE="https://adoptium.net/"
SRC_URI="
	$(abi_uri x64 amd64 glibc)
	$(abi_uri x64 amd64 llvm)
"

LICENSE="GPL-2-with-classpath-exception"
KEYWORDS="~amd64"

# elibc_llvm is not one of the values the gentoo profiles declare, so it is
# named here rather than left to USE_EXPAND.
IUSE="alsa cups headless-awt selinux elibc_llvm"

RDEPEND="
	media-libs/fontconfig:1.0
	media-libs/freetype:2
	>net-libs/libnet-1.1
	>=sys-apps/baselayout-java-0.1.0-r1
	elibc_glibc? ( >=sys-libs/glibc-2.2.5:* )
	elibc_llvm? ( sys-libs/musl-abi )
	virtual/zlib:=
	alsa? ( media-libs/alsa-lib )
	cups? ( net-print/cups )
	selinux? ( sec-policy/selinux-java )
	!headless-awt? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/libXrender
		x11-libs/libXtst
	)"

RESTRICT="preserve-libs splitdebug"
QA_PREBUILT="*"

S="${WORKDIR}/jdk${MY_PV}-jre"

src_install() {
	local dest="/opt/${P}"
	local ddest="${ED}/${dest#/}"

	# https://bugs.gentoo.org/922741
	docompress "${dest}/man"

	rm ASSEMBLY_EXCEPTION LICENSE THIRD_PARTY_README || die

	# this does not exist on arm64 hence -f
	# The Alpine build links libfontmanager to the bundled copy by name.
	use elibc_llvm || rm -fv lib/*/libfreetype.so* || die

	if ! use alsa ; then
		rm -v lib/*/libjsoundalsa.so* || die
	fi

	if use headless-awt ; then
		rm -fvr lib/*/lib*{[jx]awt,splashscreen}* \
			bin/policytool || die
	fi

	rm -v lib/security/cacerts || die
	dosym -r /etc/ssl/certs/java/cacerts "${dest}"/lib/security/cacerts

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	# provide stable symlink
	dosym "${P}" "/opt/${PN}-${SLOT}"

	java-vm_install-env "${FILESDIR}"/${PN}-${SLOT}.env.sh
	java-vm_set-pax-markings "${ddest}"
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter
}
