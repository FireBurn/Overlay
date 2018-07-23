# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit meson systemd multilib-minimal

DESCRIPTION="Optimise Linux system performance on demand"
HOMEPAGE="https://github.com/FeralInteractive/gamemode"
SRC_URI=""https://github.com/FeralInteractive/${PN}/releases/download/${PV}/${P}.tar.xz

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="sys-apps/systemd"
RDEPEND="${DEPEND}"

multilib_src_configure() {
	meson_src_configure
}

multilib_src_compile() {
	meson_src_compile
}

multilib_src_install() {
	meson_src_install
}

pkg_postinst() {
    elog " "
	elog "Run the following commands as your user (not as root) to enable gamemode"
	elog " systemctl --user daemon-reload     # Reload the unit files"
	elog " systemctl --user enable gamemoded  # Enables the gamemoded daemon on future restarts"
	elog " systemctl --user start gamemoded   # This starts the gamemoded daemon"
	elog " "
	elog "Add 'LD_PRELOAD=\$LD_PRELOAD:/usr/\$LIB/libgamemodeauto.so %command%'"
	elog "to the start options to any steam game to enable the performance"
	elog "governor as you start the game"
	elog " "
}
