# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gconf/gconf-3.2.6-r1.ebuild,v 1.5 2013/12/08 18:25:00 pacho Exp $

EAPI="5"
GCONF_DEBUG="yes"
GNOME_ORG_MODULE="GConf"
GNOME2_LA_PUNT="yes"
PYTHON_COMPAT=( python2_{6,7} )
PYTHON_REQ_USE="xml"

inherit eutils gnome2 python-r1 multilib-minimal

DESCRIPTION="GNOME configuration system and daemon"
HOMEPAGE="http://projects.gnome.org/gconf/"

LICENSE="LGPL-2+"
SLOT="2"
KEYWORDS="~alpha amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~arm-linux ~x86-linux"
IUSE="debug gtk +introspection ldap orbit policykit"

RDEPEND="
	${PYTHON_DEPS}
	>=dev-libs/glib-2.31:2[${MULTILIB_USEDEP}]
	>=dev-libs/dbus-glib-0.74:=[${MULTILIB_USEDEP}]
	>=sys-apps/dbus-1:=[${MULTILIB_USEDEP}]
	>=dev-libs/libxml2-2:2[${MULTILIB_USEDEP}]
	gtk? ( >=x11-libs/gtk+-2.90:3[${MULTILIB_USEDEP}] )
	introspection? ( >=dev-libs/gobject-introspection-0.9.5:=[${MULTILIB_USEDEP}] )
	ldap? ( net-nds/openldap:= )
	orbit? ( >=gnome-base/orbit-2.4:2 )
	policykit? ( sys-auth/polkit:=[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}
	dev-libs/libxslt
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.35
	virtual/pkgconfig
"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

pkg_setup() {
	kill_gconf
}

src_prepare() {
	# Do not start gconfd when installing schemas, fix bug #238276, upstream #631983
	epatch "${FILESDIR}/${PN}-2.24.0-no-gconfd.patch"

	# Do not crash in gconf_entry_set_value() when entry pointer is NULL, upstream #631985
	epatch "${FILESDIR}/${PN}-2.28.0-entry-set-value-sigsegv.patch"

	gnome2_src_prepare

	multilib_copy_sources
}

multilib_src_configure() {
	gnome2_src_configure \
		--disable-static \
		--enable-gsettings-backend \
		$(use_enable gtk) \
		$(usex gtk --with-gtk=3.0 "") \
		$(use_enable introspection) \
		$(use_with ldap openldap) \
		$(use_enable orbit) \
		$(use_enable policykit defaults-service) \
		ORBIT_IDL=$(type -P orbit-idl-2)
}

multilib_src_install() {
	gnome2_src_install
	python_replicate_script "${ED}"/usr/bin/gsettings-schema-convert || die

	keepdir /etc/gconf/gconf.xml.mandatory
	keepdir /etc/gconf/gconf.xml.defaults
	# Make sure this directory exists, bug #268070, upstream #572027
	keepdir /etc/gconf/gconf.xml.system

	echo "CONFIG_PROTECT_MASK=\"/etc/gconf\"" > 50gconf
	echo 'GSETTINGS_BACKEND="gconf"' >> 50gconf
	doenvd 50gconf
	dodir /root/.gconfd
}

pkg_preinst() {
	kill_gconf
}

pkg_postinst() {
	kill_gconf

	# change the permissions to avoid some gconf bugs
	einfo "changing permissions for gconf dirs"
	find  "${EPREFIX}"/etc/gconf/ -type d -exec chmod ugo+rx "{}" \;

	einfo "changing permissions for gconf files"
	find  "${EPREFIX}"/etc/gconf/ -type f -exec chmod ugo+r "{}" \;

	if ! use orbit; then
		ewarn "You are using dbus for GConf's IPC. If you are upgrading from"
		ewarn "<=gconf-3.2.3, or were previously using gconf with USE=orbit,"
		ewarn "you will need to now restart your desktop session (for example,"
		ewarn "by logging out and then back in)."
		ewarn "Otherwise, gconf-based applications may crash with 'Method ..."
		ewarn "on interface \"org.gnome.GConf.Server\" doesn't exist' errors."
	fi
}

kill_gconf() {
	# This function will kill all running gconfd-2 that could be causing troubles
	if [ -x "${EPREFIX}"/usr/bin/gconftool-2 ]
	then
		"${EPREFIX}"/usr/bin/gconftool-2 --shutdown
	fi

	return 0
}
