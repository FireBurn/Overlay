# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-env go-module

# The only Go dependency, from go.sum. Deliberately old: upstream keeps
# esbuild buildable with Go 1.13.
GO_MODULE="golang.org/x/sys"
GO_MODULE_PV="v0.0.0-20220715151400-c0bba94af5f8"
GO_MODULE_P="${GO_MODULE//\//-}-${GO_MODULE_PV}"

DESCRIPTION="A modern, extremely fast, JavaScript and CSS bundler and minifier"
HOMEPAGE="https://esbuild.github.io/"
SRC_URI="
	https://github.com/evanw/esbuild/archive/v${PV}.tar.gz -> ${P}.tar.gz
	mirror://goproxy/${GO_MODULE}/@v/${GO_MODULE_PV}.zip -> ${GO_MODULE_P}.zip
	mirror://goproxy/${GO_MODULE}/@v/${GO_MODULE_PV}.mod -> ${GO_MODULE_P}.mod
"

LICENSE="BSD MIT"
SLOT="${PV}"
KEYWORDS="~amd64 ~arm64"

RESTRICT="test" # tests require more work, but chromium needs esbuild already.

src_unpack() {
	unpack "${P}.tar.gz"

	# Serve the module out of DISTDIR instead of proxy.golang.org; go
	# verifies it against go.sum as usual
	local proxy="${T}/go-proxy/${GO_MODULE}/@v"
	mkdir -p "${proxy}" || die
	cp "${DISTDIR}/${GO_MODULE_P}.zip" "${proxy}/${GO_MODULE_PV}.zip" || die
	cp "${DISTDIR}/${GO_MODULE_P}.mod" "${proxy}/${GO_MODULE_PV}.mod" || die
	echo "{\"Version\": \"${GO_MODULE_PV}\"}" > "${proxy}/${GO_MODULE_PV}.info" || die
	echo "${GO_MODULE_PV}" > "${proxy}/list" || die

	export GOPROXY="file://${T}/go-proxy"

	go-env_set_compile_environment
}

src_compile() {
	ego build -v -ldflags="-s -w" ./cmd/esbuild
}

src_install() {
	newbin esbuild esbuild-${PV}
}

src_test() {
	ego test -v -ldflags="-s -w" ./cmd/esbuild
}
