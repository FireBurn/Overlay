# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/nspr/nspr-4.10.2.ebuild,v 1.7 2013/12/07 19:52:23 ago Exp $

EAPI=5
WANT_AUTOCONF="2.1"

inherit autotools eutils toolchain-funcs versionator multilib-minimal

MIN_PV="$(get_version_component_range 2)"

DESCRIPTION="Netscape Portable Runtime"
HOMEPAGE="http://www.mozilla.org/projects/nspr/"
SRC_URI="ftp://ftp.mozilla.org/pub/mozilla.org/nspr/releases/v${PV}/src/${P}.tar.gz"

LICENSE="|| ( MPL-2.0 GPL-2 LGPL-2.1 )"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ~mips ppc ppc64 ~s390 ~sh ~sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="debug"

src_prepare() {
	mkdir build inst
	cd "${S}"/nspr/
	epatch "${FILESDIR}"/${PN}-4.6.1-lang.patch
	epatch "${FILESDIR}"/${PN}-4.7.0-prtime.patch
	epatch "${FILESDIR}"/${PN}-4.7.1-solaris.patch
	epatch "${FILESDIR}"/${PN}-4.7.4-solaris.patch
	# epatch "${FILESDIR}"/${PN}-4.8.3-aix-gcc.patch
	epatch "${FILESDIR}"/${PN}-4.8.4-darwin-install_name.patch
	epatch "${FILESDIR}"/${PN}-4.8.9-link-flags.patch
	# We do not need to pass -L$libdir via nspr-config --libs
	epatch "${FILESDIR}"/${PN}-4.9.5_nspr_config.patch

	# We must run eautoconf to regenerate configure
	eautoconf

	# make sure it won't find Perl out of Prefix
	sed -i -e "s/perl5//g" "${S}"/nspr/configure || die

	# Respect LDFLAGS
	sed -i -e 's/\$(MKSHLIB) \$(OBJS)/\$(MKSHLIB) \$(LDFLAGS) \$(OBJS)/g' \
		"${S}"/nspr/config/rules.mk || die

	multilib_copy_sources
}

multilib_src_configure() {
	cd "${S}-${ABI}"/build

	# We use the standard BUILD_xxx but nspr uses HOST_xxx
	tc-export_build_env BUILD_CC
	export HOST_CC=${BUILD_CC} HOST_CFLAGS=${BUILD_CFLAGS} HOST_LDFLAGS=${BUILD_LDFLAGS}
	tc-export AR CC CXX RANLIB
	if multilib_is_native_abi; then
		export CROSS_COMPILE=1
	else
		unset CROSS_COMPILE
	fi

	local myconf
	echo > "${T}"/test.c
	${CC} ${CFLAGS} ${CPPFLAGS} -c "${T}"/test.c -o "${T}"/test.o || die
	case $(file "${T}"/test.o) in
		*32-bit*x86-64*|*64-bit*|*ppc64*|*x86_64*) myconf+=" --enable-64bit";;
		*32-bit*|*ppc*|*i386*) ;;
		*) die "Failed to detect whether your arch is 64bits or 32bits, disable distcc if you're using it, please";;
	esac

	# Ancient autoconf needs help finding the right tools.
	LC_ALL="C" ECONF_SOURCE="../nspr" \
	ac_cv_path_AR="${AR}" \
	econf \
		--libdir="${EPREFIX}/usr/$(get_libdir)" \
		$(use_enable debug) \
		$(use_enable !debug optimize) \
		${myconf}
}

multilib_src_compile() {
	cd "${S}-${ABI}"/build
	emake || die "failed to build"
}

multilib_src_install() {
	# Their build system is royally confusing, as usual
	MINOR_VERSION=${MIN_PV} # Used for .so version
	cd "${S}-${ABI}"/build
	emake DESTDIR="${D}" install || die "emake install failed"

	cd "${ED}"/usr/$(get_libdir)
	einfo "removing static libraries as upstream has requested!"
	rm -f *.a || die "failed to remove static libraries."

	# install nspr-config
	if multilib_is_native_abi; then
		dobin "${S}-${ABI}"/build/config/nspr-config || die "failed to install nspr-config"
	else
		newbin "${S}-${ABI}"/build/config/nspr-config nspr-config.${ABI} || die "failed to install nspr-config.${ABI}"
	fi

	# Remove stupid files in /usr/bin
	rm -f "${ED}"/usr/bin/prerr.properties || die "failed to cleanup unneeded files"
}
