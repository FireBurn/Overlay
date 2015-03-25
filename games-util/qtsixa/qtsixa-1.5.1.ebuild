# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python2_7 )
inherit eutils linux-info python-single-r1 systemd udev

MY_P="QtSixA-${PV}"
DESCRIPTION="Sixaxis Joystick Manager"
HOMEPAGE="http://qtsixa.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P/-/%20}/${MY_P}-src.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="jack qt4"

DEPEND="net-wireless/bluez
	virtual/libusb:1
	jack? ( media-sound/jack-audio-connection-kit )
	qt4? ( dev-python/PyQt4[${PYTHON_USEDEP}] )"

RDEPEND="${DEPEND}
	dev-python/dbus-python[${PYTHON_USEDEP}]
	qt4? (
		net-wireless/bluez-hcidump
		x11-libs/libnotify
		x11-misc/xdg-utils
	)"

S="${WORKDIR}/${MY_P}"

CONFIG_CHECK="~BT_HIDP ~INPUT_UINPUT"

pkg_setup() {
	python-single-r1_pkg_setup
	linux-info_pkg_setup
}

src_prepare() {
	epatch "${FILESDIR}"/qtsixa-1.5.1-fix-missing-includes.patch

	sed -i -e s/exec\ python/exec\ "${EPYTHON}"/g qtsixa/qtsixa ||
		die "Replace hardcoded python executable fails."
}

src_compile() {
	use qt4 && emake -C qtsixa
	emake -C utils WANT_JACK=$(use jack && echo true)
	emake -C sixad
}

src_install() {
	use qt4 && emake -C qtsixa install DESTDIR="${D}"
	emake -C utils install DESTDIR="${D}" WANT_JACK=$(use jack && echo true)
	emake -C sixad install DESTDIR="${D}"

	dodoc INSTALL manual.pdf README TODO

	if use qt4; then
		python_fix_shebang "${D}"/usr/bin/sixad-lq
		python_fix_shebang "${D}"/usr/bin/sixad-notify
		python_fix_shebang "${D}"/usr/share/qtsixa/gui
		python_optimize "${D}"/usr/share/qtsixa/gui
	fi

	# Remove unused configuration file.
	# Since we are using hand-written startup files.
	# We could coexist with the bluetooth daemon if input plugin is disabled.
	rm -r "${D}etc/default" || die "Remove not needed configuration file fails."

	# Remove unused logrotate configuration file.
	rm -r "${D}etc/logrotate.d" ||
		die "Remove not needed log configuration fails."

	# Do not install upstream start script.
	# It does not work nicely.
	# We added custom startup scripts for OpenRC and systemd.
	rm "${D}usr/bin/sixad" || die "Could not remove upstream start script."

	# Use our own init script compatible with OpenRC.
	newinitd "${FILESDIR}"/sixad.initd sixad

	# Install systemd unit file.
	systemd_dounit "${FILESDIR}"/sixad.service

	# Add an udev rule for automatically pairing.
	udev_dorules "${FILESDIR}"/97-sixpair.rules
}

pkg_postinst() {
	udev_reload

	einfo "Requirements:"
	einfo "Ensure that the uinput module is loaded."
	einfo ""
	einfo "Solve conflicts:"
	einfo "Do not forget to disable the input plugin of your bluetooth daemon."
	einfo "You could disable the plugin by adding the following line to the"
	einfo "configuration file of the bluetooth daemon (/etc/bluetooth/main.conf):"
	einfo "DisablePlugins = input"
	einfo ""
	einfo "Pairing:"
	einfo "There is an udev rule installed, that will pair PS3 remote"
	einfo "controllers if they are plugged in on USB."
}
