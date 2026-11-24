# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN/-bin/}"
MY_PV="${PV/-r*/}"

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
	hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
	sw ta te th tr uk ur vi zh-CN zh-TW
"
PYTHON_COMPAT=( python3_{11..15} )
UPDATE_DISABLER_COMMIT="2f26748a667045d26bc19841f1a731b4be7a7514"

ELECTRON_SLOT="45"

inherit chromium-2 desktop electron linux-info optfeature python-single-r1 unpacker xdg

DESCRIPTION="All-in-one voice and text chat for gamers"
HOMEPAGE="https://discord.com/"

SRC_URI="
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/full.distro -> ${P}.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_desktop_core/1/full.distro
		-> ${P}-${MY_PN}_desktop_core.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_erlpack/1/full.distro
		-> ${P}-${MY_PN}_erlpack.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_spellcheck/1/full.distro
		-> ${P}-${MY_PN}_spellcheck.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_utils/1/full.distro
		-> ${P}-${MY_PN}_utils.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_voice/1/full.distro
		-> ${P}-${MY_PN}_voice.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_zstd/1/full.distro
		-> ${P}-${MY_PN}_zstd.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_rpc/1/full.distro
		-> ${P}-${MY_PN}_rpc.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_game_utils/1/full.distro
		-> ${P}-${MY_PN}_game_utils.distro
	https://stable.dl2.discordapp.net/distro/app/stable/linux/x64/${MY_PV}/discord_krisp/1/full.distro
		-> ${P}-${MY_PN}_krisp.distro
	https://github.com/flathub/com.discordapp.Discord/raw/${UPDATE_DISABLER_COMMIT}/disable-breaking-updates.py
		-> discord-disable-breaking-updates-${UPDATE_DISABLER_COMMIT}.py
"
S="${WORKDIR}/${MY_PN^}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"

IUSE="appindicator bundled-electron elibc_llvm +seccomp wayland"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RESTRICT="bindist mirror strip test"
BDEPEND="app-arch/brotli"
RDEPEND="
	${PYTHON_DEPS}
	!bundled-electron? ( ${ELECTRON_DEPEND} )
	>=app-accessibility/at-spi2-core-2.46.0:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	dev-libs/wayland
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	sys-libs/glibc
	x11-libs/cairo
	x11-libs/libdrm
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXScrnSaver
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/libxshmfence
	x11-libs/pango
	appindicator? ( dev-libs/libayatana-appindicator )
"

DESTDIR="/opt/${MY_PN}"

QA_PREBUILT="*"

CONFIG_CHECK="~USER_NS"

install_node_module() {
	brotli -d "${DISTDIR}/${P}"-$1.distro -o "${T}"/$1.tar 2>/dev/null || die
	unpack "${T}"/$1.tar || die
	if [[ $1 == discord_krisp ]]; then
		# The Krisp module refuses to initialize unless the host executable
		# matches a hardcoded hash of the official Discord binary, which the
		# system Electron never will. Force the check to pass.
		"${EPYTHON}" "${FILESDIR}/patch-krisp.py" "${WORKDIR}/files/discord_krisp.node" ||
			die "failed to patch the Krisp signature check"
	fi
	# discord_voice.node and discord_krisp.node need libstdc++ and libatomic,
	# which llvm-libc does not have. The stubs make the client start without voice.
	if use elibc_llvm && [[ $1 == discord_voice || $1 == discord_krisp ]]; then
		cp "${FILESDIR}/${1#discord_}-stub.js" "${WORKDIR}/files/index.js" || die
	fi
	mv "${WORKDIR}"/files "${S}/resources/standalone_modules/$1" || die
}

src_unpack() {
	# Upstream ships only an autoupdater. Fetch the same Brotli-compressed
	# archives it would, and install the modules where build_info.json's
	# standaloneModules flag makes the app look for them. For any new module,
	# add its archive to SRC_URI and a call to install_node_module below.
	brotli -d "${DISTDIR}/${P}".distro -o "${T}/${P}.tar" 2>/dev/null || die
	unpack "${T}/${P}.tar"
	mv "${WORKDIR}"/files "${S}" || die
	rm "${T}/${P}.tar" || die
	mkdir "${S}/resources/standalone_modules" || die
	install_node_module "discord_desktop_core"
	install_node_module "discord_erlpack"
	install_node_module "discord_spellcheck"
	install_node_module "discord_utils"
	install_node_module "discord_voice"
	install_node_module "discord_zstd"
	install_node_module "discord_rpc"
	install_node_module "discord_game_utils"
	install_node_module "discord_krisp"
}

src_configure() {
	default

	use bundled-electron && chromium_suid_sandbox_check_kernel_config
}

src_prepare() {
	default

	if use bundled-electron; then
		pushd "locales/" >/dev/null || die "location change for language cleanup failed"
		chromium_remove_language_paks
		popd >/dev/null || die "location reset for language cleanup failed"
	fi

	# Update exec location in launcher
	local exec="${DESTDIR}/${MY_PN^}"
	use bundled-electron ||
		exec="$(electron_home)/electron ${DESTDIR}/resources/app"
	sed --expression "s:@@DESTDIR@@:${DESTDIR}:" \
		--expression "s:@@EXEC@@:${exec}:" \
		"${FILESDIR}/launcher-r1.sh" > "${T}/launcher.sh" || die "updating of exec location in launcher failed"

	# USE seccomp in launcher
	if use seccomp; then
		sed --in-place --expression '/^EBUILD_SECCOMP=/s/false/true/' \
			"${T}/launcher.sh" || die "sed failed for seccomp"
	fi

	# USE wayland in launcher
	if use wayland; then
		sed --in-place --expression '/^EBUILD_WAYLAND=/s/false/true/' \
			"${T}/launcher.sh" || die "sed failed for wayland"
	fi

	"${EPYTHON}" - <<-EOF || die "Failed updating build_info.json"
	import json
	with open("resources/build_info.json") as f:
	    info = json.load(f)
	info["disableUpdater"] = True
	info["standaloneModules"] = True
	info["newUpdater"] = False
	with open("resources/build_info.json", "w") as f:
	    json.dump(info, f, indent=2)
	EOF

	# Preload scripts do not see the resourcesPath override the loader installs,
	# and module data must not go in the read-only install directory
	"${EPYTHON}" "${FILESDIR}/asar-resources-path.py" resources/app.asar ||
		die "Failed patching app.asar"
}

src_install() {
	doicon -s 256 "${MY_PN}.png"

	# install .desktop file
	make_desktop_entry "${EPREFIX}/usr/bin/discord" Discord "${PN}" \
	"Network;InstantMessaging;" \
	"StartupWMClass=discord" \
	"Path=${EPREFIX}/usr/bin"

	if use bundled-electron; then
		exeinto "${DESTDIR}"

		doexe "${MY_PN^}" chrome-sandbox libEGL.so libffmpeg.so libGLESv2.so libvk_swiftshader.so

		insinto "${DESTDIR}"
		doins chrome_100_percent.pak chrome_200_percent.pak icudtl.dat resources.pak snapshot_blob.bin v8_context_snapshot.bin
		insopts -m0755
		doins -r locales

		# Chrome-sandbox requires the setuid bit to be specifically set.
		# see https://github.com/electron/electron/issues/17972
		fowners root "${DESTDIR}/chrome-sandbox"
		fperms 4711 "${DESTDIR}/chrome-sandbox"

		# Crashpad is included in the package once in a while and when it does, it must be installed.
		# See #903616 and #890595
		[[ -x chrome_crashpad_handler ]] && doins chrome_crashpad_handler
	else
		insopts -m0755
	fi

	insinto "${DESTDIR}"
	doins -r resources

	if ! use bundled-electron; then
		# Discord's own app.asar, loaded by the system Electron
		insinto "${DESTDIR}/resources/app"
		newins - package.json <<-EOF
		{ "name": "discord", "main": "index.js" }
		EOF
		newins "${FILESDIR}/loader.js" index.js
	fi

	# https://bugs.gentoo.org/905289
	insinto "${DESTDIR}"
	insopts -m0755
	newins "${DISTDIR}/discord-disable-breaking-updates-${UPDATE_DISABLER_COMMIT}.py" disable-breaking-updates.py
	python_fix_shebang "${ED}/${DESTDIR}/disable-breaking-updates.py"

	exeinto "/usr/bin"
	newexe "${T}/launcher.sh" "discord" || die "failing to install launcher"

	# https://bugs.gentoo.org/898912
	if use appindicator && use bundled-electron; then
		dosym ../../usr/lib64/libayatana-appindicator3.so /opt/discord/libappindicator3.so
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature_header "Install the following packages for additional support:"
	optfeature "sound support" \
		media-sound/pulseaudio media-sound/apulse[sdk] media-video/pipewire
	optfeature "emoji support" media-fonts/noto-emoji
	if has_version kde-plasma/kwin[-screencast] && use wayland; then
		einfo " "
		einfo "When using KWin on Wayland, the kde-plasma/kwin[screencast] USE flag"
		einfo "must be enabled for screensharing."
		einfo " "
	fi
}
