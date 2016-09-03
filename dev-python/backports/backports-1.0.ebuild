# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
PYTHON_COMPAT=( python{2_7,3_3,3_4,3_5} pypy )

inherit distutils-r1

DESCRIPTION="Namespace for backported Python features"
HOMEPAGE="https://bitbucket.org/brandon/backports https://pypi.python.org/pypi/backports/"
SRC_URI="https://dev.gentoo.org/~radhermit/dist/${P}.tar.gz"

LICENSE="PYTHON"
SLOT="0"
KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ppc ppc64 ~sparc x86 ~amd64-linux ~x86-linux"

RDEPEND="!<dev-python/backports-lzma-0.0.2-r1"
