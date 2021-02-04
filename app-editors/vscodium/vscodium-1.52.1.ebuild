# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils desktop

DESCRIPTION="VS Code without MS branding/telemetry/licensing"
HOMEPAGE="https://vscodium.com/"
LICENSE="MIT"

VSCODE_ARCH="x64"
ELECTRON_VERSION="11.1.1"
ELECTRON_ZIP="electron-v${ELECTRON_VERSION}-linux-${VSCODE_ARCH}.zip"
ELECTRON_FFMPEG_ZIP="ffmpeg-v${ELECTRON_VERSION}-linux-${VSCODE_ARCH}.zip"

SRC_URI="
  https://github.com/VSCodium/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz
  https://github.com/microsoft/vscode/archive/${PV}.tar.gz -> vscode-${PV}.tar.gz
  https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}/${ELECTRON_ZIP}
  !system-ffmpeg? ( https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}/${ELECTRON_FFMPEG_ZIP} )
"

RESTRICT="strip network-sandbox"
SLOT="0"
KEYWORDS="-* ~amd64" # todo: other arches
IUSE="minify +system-ffmpeg"

COMMON_DEPEND=""
BDEPEND="
  app-misc/jq
  app-shells/bash
  dev-vcs/git
  net-libs/nodejs[npm]
  sys-apps/grep
  sys-apps/sed
  sys-apps/yarn
  sys-devel/patch
"
DEPEND="${COMMON_DEPEND}
  app-crypt/libsecret[crypt]
"
RDEPEND="${COMMON_DEPEND}
  system-ffmpeg? ( media-video/ffmpeg[chromium] )
  app-accessibility/at-spi2-core
  app-accessibility/at-spi2-atk:2
  dev-libs/atk
  dev-libs/expat
  dev-libs/glib:2
  dev-libs/nspr
  =dev-libs/nss-3*
  media-libs/alsa-lib
  net-print/cups
  =sys-apps/dbus-1*
  sys-apps/util-linux
  sys-libs/glibc
  x11-libs/cairo
  x11-libs/gdk-pixbuf:2
  x11-libs/gtk+:3
  x11-libs/libXScrnSaver
  x11-libs/libXrandr
  x11-libs/libXtst
  x11-libs/libXi
  x11-libs/libXfixes
  x11-libs/libXdamage
  x11-libs/libXcursor
  x11-libs/libX11
  x11-libs/libXrender
  x11-libs/libXcomposite
  x11-libs/libXext
  x11-libs/pango
"

# todo: are any of these necessary?
OLD_EXTRA_RDEPEND="
  >=dev-libs/libdbusmenu-16.04.0
  >=media-libs/libpng-1.2.46:0
  >=x11-libs/libnotify-0.7.7:0
"

S_VSCODE="${S}/vscode"

src_unpack() {
  unpack "${P}.tar.gz"
  unpack "vscode-${PV}.tar.gz"
  mv --no-target-directory "vscode-${PV}" "${S_VSCODE}" || die "vscode move failed"

  mkdir -p "${HOME}/.cache/electron/"
  mkdir -p "${T}/gulp-electron-cache/atom/electron/"
  ln "${DISTDIR}/${ELECTRON_ZIP}" "${HOME}/.cache/electron/"
  ln "${DISTDIR}/${ELECTRON_ZIP}" "${T}/gulp-electron-cache/atom/electron/"
  if ! use system-ffmpeg ; then
    ln "${DISTDIR}/${ELECTRON_FFMPEG_ZIP}" "${HOME}/.cache/electron/"
    ln "${DISTDIR}/${ELECTRON_FFMPEG_ZIP}" "${T}/gulp-electron-cache/atom/electron/"
  fi
}

src_prepare() {
  export npm_config_scripts_prepend_node_path="auto"
  yarn global add node-gyp || die "add node-gyp failed"

  # init a git repo to stop husky searching up the fs tree and trying to write outside the sandbox
  git init "${WORKDIR}"

  export OS_NAME="linux"
  export VSCODE_ARCH
  export BUILDARCH="${VSCODE_ARCH}" # todo: BUILDARCH seems to matter only when CI_WINDOWS=="True"
  ./prepare_vscode.sh || die "prepare_vscode failed"

  if use system-ffmpeg; then
    # prevent downloading an extra version of libffmpeg.so during the build
    for file in "${S_VSCODE}/build/lib/electron.js" "${S_VSCODE}/build/lib/electron.ts" "${S_VSCODE}/build/gulpfile.vscode.js"; do
      sed -i "s|ffmpegChromium: true|ffmpegChromium: false|" "${file}" || die "setting ffmpegChromium failed"
    done
  fi

  default
}

src_compile () {
  cd "${S_VSCODE}"
    export NODE_ENV="production" # todo: necessary?
	  # the minify step is very expensive in RAM and CPU time, so make it optional
	  use minify && GULP_TARGET="vscode-linux-${VSCODE_ARCH}-min" || GULP_TARGET="vscode-linux-${VSCODE_ARCH}"
    yarn gulp "${GULP_TARGET}" || die "gulp build failed"
  cd -
}

RELTARGET="opt/${PN}"

QA_PRESTRIPPED="${RELTARGET}/codium"
QA_PREBUILT="${RELTARGET}}/codium"

src_install() {
  dodir "/opt"
  OUTDIR="${S}/VSCode-linux-${VSCODE_ARCH}"
  # fixup world-writable files
  chmod go-w --recursive "${OUTDIR}/resources/app/extensions"
  # using doins -r would strip executable bits from all binaries
  cp -pPR --no-target-directory "${OUTDIR}" "${ED}/${RELTARGET}" || die "file copy failed"
  if use system-ffmpeg; then
    dosym "${EPREFIX}/usr/lib64/chromium/libffmpeg.so" "/${RELTARGET}/libffmpeg.so" || die "ffmpeg.so symlink failed"
  fi
  dosym "${EPREFIX}/${RELTARGET}/bin/codium" "/usr/bin/codium" || die "codium symlink failed"
  newicon "${S}/src/resources/linux/code.png" "${PN}.png"
  make_desktop_entry "codium" "VSCodium" "${PN}" "Development;IDE"
}
