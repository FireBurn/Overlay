# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )
inherit desktop python-single-r1 toolchain-funcs xdg

DESCRIPTION="Installer and launcher for Valve's 64-bit SteamRT3 Steam client"
HOMEPAGE="https://store.steampowered.com"
SRC_URI="https://repo.steampowered.com/steam/archive/stable/steam_${PV}.tar.gz"
S="${WORKDIR}/steam-launcher"

LICENSE="Steam MIT"
SLOT="0"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="bindist mirror test"

RDEPEND="
	${PYTHON_DEPS}
	app-shells/bash
	net-misc/curl
	sys-apps/coreutils
"

src_prepare() {
	default

	# Only steam.sh from the bootstrap: the rest of it is the 32-bit client.
	tar -xJf bootstraplinux_ubuntu12_32.tar.xz steam.sh || die

	sed -e "s#@LIBDIR@#${EPREFIX}/usr/lib/${PN}#" \
		-e "s#@PYTHON@#${PYTHON}#" \
		"${FILESDIR}"/${PN}.sh > ${PN}.sh || die
	# Named for this package, so it can sit beside games-util/steam-launcher.
	sed -i -e "s#^Exec=/usr/bin/steam#Exec=${PN}#" \
		-e "s#^Icon=steam\$#Icon=${PN}#" steam.desktop || die
}

src_compile() {
	# Static and without an interpreter, so it runs inside the container,
	# whatever C library that has.
	$(tc-getCC) ${CFLAGS} ${LDFLAGS} -static -Wl,--no-dynamic-linker \
		-o reaper "${FILESDIR}"/reaper.c || die
}

src_install() {
	local size
	for size in 16 24 32 48 256; do
		newicon -s ${size} icons/${size}/steam.png ${PN}.png
	done

	exeinto /usr/lib/${PN}
	doexe steam.sh reaper
	dobin ${PN}.sh
	mv "${ED}"/usr/bin/${PN}{.sh,} || die

	newmenu steam.desktop ${PN}.desktop

	dodoc README
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Run ${PN} to download the SteamRT3 client into"
	elog "\${XDG_DATA_HOME:-~/.local/share}/Steam and start it. The client"
	elog "then updates itself, outside Portage's control."
}
