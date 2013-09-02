# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/json-c/json-c-0.11.ebuild,v 1.2 2013/05/09 05:15:10 vapier Exp $

EAPI=5

AUTOTOOLS_AUTORECONF=true

inherit autotools-utils multilib-minimal

DESCRIPTION="A JSON implementation in C"
HOMEPAGE="https://github.com/json-c/json-c/wiki"
SRC_URI="https://s3.amazonaws.com/json-c_releases/releases/${P}.tar.gz"

LICENSE="MIT"
SLOT="0/0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="doc static-libs"

# tests break otherwise
AUTOTOOLS_IN_SOURCE_BUILD=1

src_prepare() {
	sed -i -e "s:-Werror::" Makefile.am.inc || die
	default
	multilib_copy_sources
}

multilib_src_configure() {
	# Disable old lib compatibility
	econf	--disable-oldname-compat
}

multilib_src_compile() {
	default
}

multilib_src_test() {
	export USE_VALGRIND=0 VERBOSE=1
	default
}

multilib_src_install() {
	use doc && HTML_DOCS=( "${S}"/doc/html )
	default

	# add symlink for projects not using pkgconfig
	dosym ../json-c /usr/include/json-c/json
}
