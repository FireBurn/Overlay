# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3

DESCRIPTION="A modern flat theme with a combination of light and dark elements"
HOMEPAGE="https://github.com/numixproject/numix-gtk-theme"
EGIT_REPO_URI="https://github.com/numixproject/numix-gtk-theme-light"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	dev-libs/libxml2
	x11-libs/gtk+:3
	x11-themes/gtk-engines-murrine
"
DEPEND="
	${RDEPEND}
	dev-libs/glib:2
	dev-ruby/sass:*
	x11-libs/gdk-pixbuf:2
"

src_install() {
    insinto "/usr/share/themes/Numix-Light"
    doins -r *
}
