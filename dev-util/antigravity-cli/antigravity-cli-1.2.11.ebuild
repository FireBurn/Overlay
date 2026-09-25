# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Google's agentic development platform (CLI companion)"
HOMEPAGE="https://antigravity.google/ https://github.com/google-antigravity/antigravity-cli"

SRC_URI="
	amd64? ( https://github.com/google-antigravity/antigravity-cli/releases/download/${PV}/agy_cli_linux_x64.tar.gz -> antigravity-x64-${PV}.tar.gz )
	arm64? ( https://github.com/google-antigravity/antigravity-cli/releases/download/${PV}/agy_cli_linux_arm64.tar.gz -> antigravity-arm64-${PV}.tar.gz )
"

# Tarball unpacks the bare files without a root directory
S="${WORKDIR}"

LICENSE="Google-TOS"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="bindist mirror strip"

# Prevent QA warnings regarding pre-stripped Go binaries
QA_PREBUILT="usr/bin/agy"

RDEPEND="sys-libs/glibc"
BDEPEND=""

src_install() {
	# Install the 'antigravity' Go binary to /usr/bin/antigravity
	dobin antigravity

	# Include documentation/licenses if present in the fetched tarball
	[[ -f LICENSE ]] && dodoc LICENSE
	[[ -f README.md ]] && dodoc README.md
}
