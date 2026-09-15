# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-env go-module

DESCRIPTION="A modern, extremely fast, JavaScript and CSS bundler and minifier"
HOMEPAGE="https://esbuild.github.io/"
SRC_URI="https://github.com/evanw/esbuild/archive/v${PV}.tar.gz -> ${P}.tar.gz"
# The sole Go dependency is unchanged from 0.25.1. Reuse its vendor archive.
SRC_URI+=" https://deps.gentoo.zip/dev-util/esbuild/esbuild-0.25.1-vendor.tar.xz"

LICENSE="BSD MIT"
SLOT="${PV}"
KEYWORDS="~amd64 ~arm64"

RESTRICT="test" # tests require more work, but chromium needs esbuild already.

src_unpack() {
	default
	mv "${WORKDIR}/esbuild-0.25.1/vendor" "${S}/vendor" || die
	go-env_set_compile_environment
}

src_compile() {
	# Build using vendored dependencies instead of Makefile
	ego build -mod=vendor -v -ldflags="-s -w" ./cmd/esbuild
}

src_install() {
	newbin esbuild esbuild-${PV}
}

src_test() {
	ego test -mod=vendor -v -ldflags="-s -w" ./cmd/esbuild
}
