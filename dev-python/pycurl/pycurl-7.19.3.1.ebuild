# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pycurl/pycurl-7.19.3.1.ebuild,v 1.3 2014/05/28 15:20:44 floppym Exp $

EAPI=5

# The selftests fail with pypy, and urlgrabber segfaults for me.
PYTHON_COMPAT=( python{2_7,3_2,3_3,3_4} )

inherit distutils-r1

DESCRIPTION="python binding for curl/libcurl"
HOMEPAGE="https://github.com/pycurl/pycurl http://pypi.python.org/pypi/pycurl"
SRC_URI="http://pycurl.sourceforge.net/download/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="curl_ssl_gnutls curl_ssl_nss +curl_ssl_openssl examples ssl"

# Depend on a curl with curl_ssl_* USE flags.
# libcurl must not be using an ssl backend we do not support.
# If the libcurl ssl backend changes pycurl should be recompiled.
# If curl uses gnutls, depend on at least gnutls 2.11.0 so that pycurl
# does not need to initialize gcrypt threading and we do not need to
# explicitly link to libgcrypt.
DEPEND=">=net-misc/curl-7.25.0-r1[ssl=]
	ssl? (
		net-misc/curl[curl_ssl_gnutls=,curl_ssl_nss=,curl_ssl_openssl=,-curl_ssl_axtls,-curl_ssl_polarssl]
		curl_ssl_gnutls? ( >=net-libs/gnutls-2.11.0 )
	)"
RDEPEND="${DEPEND}"
# Tests have new deps that can never be keyworded, for now
RESTRICT="test"

python_prepare_all() {
	sed -e "/data_files=/d" -i setup.py || die
	distutils-r1_python_prepare_all
}

src_configure() {
	# Override faulty detection in setup.py, bug 510974.
	export PYCURL_SSL_LIBRARY=${CURL_SSL}
}

python_compile() {
	python_is_python3 || local -x CFLAGS="${CFLAGS} -fno-strict-aliasing"
	distutils-r1_python_compile
}

src_test() {
	# suite shatters without this
	local DISTUTILS_NO_PARALLEL_BUILD=1
	distutils-r1_src_test
}

python_test() {
	# https://github.com/pycurl/pycurl/issues/180
	if [[ "${EPYTHON}" == python2.7 ]]; then
		sed -e 's:test_request_with_certinfo:_&:' \
			-e 's:test_request_without_certinfo:_&:' \
			-i tests/certinfo_test.py || die
	elif [[ "${EPYTHON}" == python3.4 ]]; then
		sed -e 's:test_post_buffer:_&:' \
			-e 's:test_post_file:_&:' \
			-i tests/post_test.py || die
	fi
	emake test
}

python_install_all() {
	local HTML_DOCS=( doc/. )
	use examples && local EXAMPLES=( examples/. )
	distutils-r1_python_install_all
}
